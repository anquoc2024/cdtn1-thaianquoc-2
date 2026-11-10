#!/usr/bin/env bash
# Checklist bảo mật 7 mục (BT3 – TP5): chạy từng mục bằng lệnh thật, dừng để chụp màn hình
# → docs/screenshots/sec-N.png, kết quả chữ ghi thêm vào docs/sec-ket-qua.txt
#   bash scripts/kiem-bao-mat.sh          # cả 7 mục
#   bash scripts/kiem-bao-mat.sh 5 6      # chỉ vài mục (chạy lại / chụp lại)
# Cần gói Docker đang chạy. Để mục 6 xem được cả log của lần nạp dữ liệu đầu tiên, chạy trước:
#   docker compose down -v && docker compose up -d --build
cd "$(dirname "$0")/.." || exit 1
BASE="http://localhost:${APP_PORT:-3000}"
SHOTS="/mnt/c/Users/Thai An Quoc/Pictures/Screenshots"
OUT=docs/sec-ket-qua.txt
B=$'\e[1m'; N=$'\e[0m'

head_sec() { echo "${B}════ MỤC $1 · $2 ════${N}"; date "+%Y-%m-%d %H:%M:%S"; }
run()      { echo; echo "\$ $*"; eval "$@"; }
empty()    { local out; out=$(eval "$1" 2>&1); echo; echo "\$ $1"; if [ -z "$out" ]; then echo "(rỗng)"; else echo "$out"; fi; }
token()    { curl -s -X POST "$BASE/api/session" -H "Content-Type: application/json" \
               -d "{\"email_address\":\"$1\",\"password\":\"Mekong@2026\"}" | sed -E 's/.*"token":"([^"]+)".*/\1/'; }
status()   { sed -n '1p;$p'; echo; }     # dòng trạng thái HTTP + thân phản hồi

sec1() {
  head_sec 1 "Không có secret nào trong repo (A02)"
  empty "git ls-files | grep -E '(^|/)\.env$|master\.key$'"
  empty "git log --all --oneline -- .env src/.env src/config/master.key"
  run   "git check-ignore -v .env src/config/master.key"
  empty "git grep -niIE '(secret_key_base|api_key|access_key|private_key)[\"]?[[:space:]]*[:=][[:space:]]*[\"'\''][A-Za-z0-9+/_-]{16,}' -- . ':!*.lock'"
  run   "docker compose exec -T app sh -c 'ls /rails/.env /rails/config/master.key 2>&1'"
}

sec2() {
  head_sec 2 "Dữ liệu vào được kiểm ở tầng ứng dụng (A05)"
  local nv; nv=$(token quoc@mekong.vn)
  run "git grep -nIE '(where|find_by_sql|execute|order|pluck|select)\(\s*\"[^\"]*#\{' -- src/app src/lib"
  echo "  ↳ chỉ được phép là hằng số trong mã (khóa advisory lock), không có dữ liệu người dùng ghép vào SQL"
  run "curl -s -G $BASE/api/customers --data-urlencode \"q=' OR '1'='1\" -H \"Authorization: Bearer \$nv\"; echo"
  run "curl -s -i -X POST $BASE/api/customers -H \"Authorization: Bearer \$nv\" -H 'Content-Type: application/json' -d '{\"name\":\"Thử sai\",\"phone\":\"091234567\"}' | status"
}

sec3() {
  head_sec 3 "Kiểm soát truy cập theo vai trò (A01)"
  local ql id; ql=$(token phu@mekong.vn)
  run "curl -s -i $BASE/api/warranty_requests | status"
  id=$(curl -s "$BASE/api/warranty_requests" -H "Authorization: Bearer $ql" | sed -E 's/^\{"data":\[\{"id":([0-9]+).*/\1/')
  echo; echo "Quản lý trung tâm (phu@mekong.vn) thử sửa / xóa / đổi trạng thái yêu cầu id=$id:"
  echo "Số yêu cầu trước: $(docker compose exec -T app bin/rails runner 'print WarrantyRequest.count')"
  run "curl -s -i -X PATCH $BASE/api/warranty_requests/$id -H \"Authorization: Bearer \$ql\" -H 'Content-Type: application/json' -d '{\"issue_description\":\"Sửa trộm\"}' | status"
  run "curl -s -i -X DELETE $BASE/api/warranty_requests/$id -H \"Authorization: Bearer \$ql\" | status"
  run "curl -s -i -X PATCH $BASE/api/warranty_requests/$id/status -H \"Authorization: Bearer \$ql\" -H 'Content-Type: application/json' -d '{\"status\":\"in_progress\"}' | status"
  echo "Số yêu cầu sau:   $(docker compose exec -T app bin/rails runner 'print WarrantyRequest.count')"
}

sec4() {
  head_sec 4 "Mật khẩu, dữ liệu nhạy cảm được băm / mã hóa (A04 · A07)"
  run "docker compose exec -T app bin/rails runner 'User.order(:id).each { |u| puts \"#{u.email_address} | password_digest = #{u.password_digest[0, 12]}… (#{u.password_digest.length} ký tự)\" }'"
  run "docker compose exec -T app bin/rails runner 'p User.column_names.grep(/password|token|expire/)'"
}

sec5() {
  head_sec 5 "Thông báo lỗi không lộ cấu trúc bên trong (A10 · A02)"
  local nv; nv=$(token quoc@mekong.vn)
  echo; echo "--- 5a. Gửi JSON hỏng ---"
  run "curl -s -i -X POST $BASE/api/customers -H \"Authorization: Bearer \$nv\" -H 'Content-Type: application/json' -d '{\"name\":\"A\", phone' | status"
  echo "--- 5b. Đường dẫn không tồn tại ---"
  run "curl -s -i $BASE/api/khong-ton-tai -H 'Accept: application/json' | status"
  echo "--- 5c. Tắt CSDL rồi gọi API ---"
  run "docker compose stop db"
  run "curl -s -i $BASE/api/health | status"
  run "curl -s -i $BASE/api/warranty_requests -H \"Authorization: Bearer \$nv\" | status"
  run "curl -s $BASE/api/warranty_requests -H \"Authorization: Bearer \$nv\" | grep -ciE 'pg::|postgres://|backtrace|/rails/|db:5432|password' || true"
  echo "  ↳ số dòng chứa tên lớp lỗi / chuỗi kết nối / đường dẫn mã nguồn trong phản hồi (mong đợi 0)"
  run "docker compose start db"
  for _ in $(seq 1 20); do curl -fs "$BASE/api/health" >/dev/null && break; sleep 2; done
  run "curl -s $BASE/api/health; echo"
}

sec6() {
  head_sec 6 "Nhật ký không ghi secret, dữ liệu cá nhân (A09)"
  local i=0 t
  echo; echo "\$ (đếm số lần mỗi API token thật xuất hiện trong log container – không in token ra màn hình)"
  for t in $(docker compose exec -T app bin/rails runner 'puts User.pluck(:api_token)'); do
    i=$((i + 1)); echo "token người dùng #$i: $(docker compose logs app 2>&1 | grep -cF "$t") lần"
  done
  run "docker compose logs app 2>&1 | grep -cE '0[0-9]{9}' || true"
  echo "  ↳ số dòng log có số điện thoại 10 chữ số (mong đợi 0)"
  run "docker compose logs app 2>&1 | grep -iE 'password|q=' | tail -4"
  echo "  ↳ tham số mật khẩu / từ khóa tra cứu phải hiện [FILTERED]"
  run "docker compose logs app 2>&1 | grep -n 'Mekong@2026' || echo '(không có)'"
}

sec7() {
  head_sec 7 "Phụ thuộc ghim phiên bản, đã kiểm lỗ hổng (A03)"
  run "git ls-files src/Gemfile.lock src/config/importmap.rb"
  run "(cd src && bin/bundler-audit check --update 2>&1 | tail -6)"
  run "(cd src && bin/importmap audit 2>&1 | tail -6)"
  run "(cd src && bin/brakeman --no-pager -q --no-exit-on-warn 2>&1 | tail -15)"
}

curl -fs "$BASE/api/health" >/dev/null || { echo "Hệ thống chưa chạy ở $BASE – chạy: docker compose up -d rồi thử lại"; exit 1; }
mkdir -p docs/screenshots
if [ $# -eq 0 ]; then set -- 1 2 3 4 5 6 7; : > "$OUT"; fi

for n in "$@"; do
  clear
  "sec$n" 2>&1 | tee -a "$OUT"
  truoc=$(ls -t "$SHOTS"/*.png 2>/dev/null | head -1)
  echo
  read -r -p ">>> Chụp màn hình (Win+Shift+S) rồi nhấn Enter để lưu sec-$n.png ... "
  moi=$(ls -t "$SHOTS"/*.png 2>/dev/null | head -1)
  if [ -n "$moi" ] && [ "$moi" != "$truoc" ]; then
    cp "$moi" "docs/screenshots/sec-$n.png" && echo "Đã lưu docs/screenshots/sec-$n.png"
  else
    echo "*** Chưa thấy ảnh mới – bỏ qua mục $n. Chụp lại: bash scripts/kiem-bao-mat.sh $n"
  fi
  sleep 1
done
echo; echo "Ảnh đã có:"; ls docs/screenshots/sec-*.png 2>/dev/null
