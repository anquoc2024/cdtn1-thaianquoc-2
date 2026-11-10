#!/usr/bin/env bash
# Demo các mã lỗi của API Smart CRM (BT2) – chạy từ gốc repo: bash scripts/demo-loi-api.sh
# Mỗi bước: in tình huống → lệnh curl → mã HTTP + JSON trả về, rồi dừng chờ Enter.
# Chạy liền không dừng: NO_PAUSE=1 bash scripts/demo-loi-api.sh   ·   Bỏ bước tắt CSDL: SKIP_DB=1
BASE="${BASE_URL:-http://127.0.0.1:3000}"
B=$'\e[1m'; C=$'\e[36m'; Y=$'\e[33m'; G=$'\e[32m'; R=$'\e[31m'; N=$'\e[0m'
STEP=0; TMP=$(mktemp)

pause() { [ -n "$NO_PAUSE" ] || read -rp "${Y}   ↵ Enter để sang bước tiếp…${N}" _; }
pretty() { python3 -m json.tool --no-ensure-ascii 2>/dev/null <<<"$1" || echo "$1"; }

call() {   # call METHOD PATH TOKEN [BODY]
  local args=(-s -o "$TMP" -w '%{http_code}' -D "$TMP.h" -X "$1" "$BASE$2" -H "Content-Type: application/json")
  [ -n "$3" ] && args+=(-H "Authorization: Bearer $3")
  [ -n "$4" ] && args+=(-d "$4")
  CODE=$(curl "${args[@]}"); RESP=$(cat "$TMP")
}
quiet() { call "$@" >/dev/null; }
token_of() { sed -E 's/.*"token":"([^"]+)".*/\1/' <<<"$RESP"; }
first_id() { grep -oE '"id":[0-9]+' <<<"$RESP" | head -1 | cut -d: -f2; }

demo() {   # demo "Tình huống" "Quy tắc" METHOD PATH TOKEN_LABEL TOKEN [BODY]
  STEP=$((STEP+1))
  echo; echo "${B}━━━ Bước $STEP: $1${N}"; echo "    ${C}$2${N}"
  local auth=""; [ -n "$6" ] && auth=" -H \"Authorization: Bearer \$$5\""
  echo "    \$ curl -X $3 $BASE$4$auth${7:+ -d '$7'}"
  call "$3" "$4" "$6" "$7"
  local color=$R; [ "${CODE:0:1}" = 2 ] && color=$G
  echo "    → ${color}${B}HTTP $CODE${N}"
  grep -iE "^(retry-after|x-request-id):" "$TMP.h" | sed 's/^/      /'
  pretty "$RESP" | sed 's/^/      /'
  pause
}

curl -s -o /dev/null "$BASE/api/health" || { echo "${R}Server chưa chạy. Mở tab khác: cd src && bin/rails server${N}"; exit 1; }

# ---------- Chuẩn bị (không in) ----------
RUN=$(date +%s); PHONE="09${RUN: -8}"; SERIAL="DEMO-$RUN"; BUY=$(date -d '2 months ago' +%F)
quiet POST /api/session "" '{"email_address":"quoc@mekong.vn","password":"Mekong@2026"}'; NV=$(token_of)
quiet POST /api/session "" '{"email_address":"phu@mekong.vn","password":"Mekong@2026"}'; QL=$(token_of)
quiet GET /api/issue_categories "$NV"
CAT=$(grep -oE '\{"id":[0-9]+[^{}]*"usage_count":[1-9][0-9]*' <<<"$RESP" | head -1 | grep -oE '[0-9]+' | head -1); [ -z "$CAT" ] && CAT=$(first_id)
quiet GET /api/priorities "$NV"; PRI=$(first_id)
quiet POST /api/customers "$NV" '{"name":"Khách demo","phone":"'"$PHONE"'"}'; CUS=$(first_id)
REQ_BODY='{"customer_id":1,"device_type":"Điện thoại","brand":"Samsung","model":"Galaxy A55","serial_number":"'"$SERIAL"'","purchase_date":"'"$BUY"'","issue_description":"Máy sập nguồn liên tục","issue_category_id":'"$CAT"',"priority_id":'"$PRI"'}'
quiet POST /api/warranty_requests "$NV" "$REQ_BODY"; REQ=$(first_id)

echo "${B}DEMO MÃ LỖI API – Smart CRM Mekong Mobile${N}  (server: $BASE)"
echo "Định dạng lỗi chung: {\"error\": \"MA_LOI\", \"message\": \"câu cho người đọc\", \"chi_tiet\": {...}}"
echo "Đã chuẩn bị: token NV, token QL, khách demo id=$CUS (SĐT $PHONE), yêu cầu id=$REQ (serial $SERIAL)"
pause

echo; echo "${B}════ A. XÁC THỰC & PHÂN QUYỀN ════${N}"
demo "Gọi API không có token" "401 CHUA_XAC_THUC" GET /api/customers
demo "Đăng nhập sai mật khẩu" "401 SAI_THONG_TIN_DANG_NHAP" POST /api/session "" "" '{"email_address":"quoc@mekong.vn","password":"sai-mat-khau"}'
demo "Quản lý trung tâm (chỉ xem) cố tạo khách hàng" "403 KHONG_CO_QUYEN – NFR05, Quản lý chỉ được xem" POST /api/customers TOKEN_QL "$QL" '{"name":"Không được tạo","phone":"0900000000"}'

echo; echo "${B}════ B. DỮ LIỆU SAI ════${N}"
demo "Số điện thoại sai định dạng" "400 DU_LIEU_KHONG_HOP_LE – chỉ rõ trường sai (BR01)" POST /api/customers TOKEN_NV "$NV" '{"name":"Khách lỗi","phone":"123"}'
demo "Tạo yêu cầu thiếu trường bắt buộc" "400 DU_LIEU_KHONG_HOP_LE – liệt kê từng trường thiếu" POST /api/warranty_requests TOKEN_NV "$NV" '{"customer_id":1,"device_type":"Điện thoại"}'
demo "Xem khách hàng không tồn tại" "404 KHONG_TIM_THAY" GET /api/customers/999999 TOKEN_NV "$NV"
demo "Tạo yêu cầu cho khách không tồn tại" "404 KHACH_HANG_KHONG_TON_TAI (BR01)" POST /api/warranty_requests TOKEN_NV "$NV" '{"customer_id":999999}'

echo; echo "${B}════ C. VI PHẠM QUY TẮC NGHIỆP VỤ ════${N}"
demo "Tạo khách trùng số điện thoại" "409 TRUNG_DU_LIEU – SĐT là duy nhất" POST /api/customers TOKEN_NV "$NV" '{"name":"Khách trùng","phone":"'"$PHONE"'"}'
demo "Xóa khách hàng đã có thiết bị" "409 DANG_DUOC_SU_DUNG – BR13" DELETE /api/customers/1 TOKEN_NV "$NV"
demo "Xóa nhóm sự cố đang được dùng" "409 DANG_DUOC_SU_DUNG – BR14" DELETE "/api/issue_categories/$CAT" TOKEN_NV "$NV"
demo "Serial đã đăng ký cho khách khác" "409 SERIAL_THUOC_KHACH_KHAC – BR11, một serial chỉ thuộc một khách" POST /api/warranty_requests TOKEN_NV "$NV" "${REQ_BODY/\"customer_id\":1/\"customer_id\":2}"
demo "Nhảy cóc: Mới tiếp nhận → Hoàn tất" "422 CHUYEN_TRANG_THAI_KHONG_HOP_LE – BR08, phải đi đúng thứ tự" PATCH "/api/warranty_requests/$REQ/status" TOKEN_NV "$NV" '{"status":"completed"}'
demo "Hủy yêu cầu không ghi lý do" "400 THIEU_LY_DO_HUY – hủy bắt buộc có lý do" PATCH "/api/warranty_requests/$REQ/status" TOKEN_NV "$NV" '{"status":"cancelled"}'
quiet PATCH "/api/warranty_requests/$REQ/status" "$NV" '{"status":"in_progress"}'
quiet PATCH "/api/warranty_requests/$REQ/status" "$NV" '{"status":"completed"}'
demo "Đổi trạng thái yêu cầu đã Hoàn tất" "409 YEU_CAU_DA_DONG – yêu cầu đã đóng không mở lại" PATCH "/api/warranty_requests/$REQ/status" TOKEN_NV "$NV" '{"status":"in_progress"}'

quiet DELETE "/api/customers/$CUS" "$NV"   # dọn khách demo (chưa có thiết bị)

if [ -z "$SKIP_DB" ]; then
  echo; echo "${B}════ D. LỖI HỆ THỐNG – MẤT CSDL (TD-27) ════${N}"
  echo "   Mở tab khác và chạy: ${B}sudo service postgresql stop${N}"
  read -rp "${Y}   ↵ Đã tắt PostgreSQL thì Enter…${N}" _
  demo "Health check khi mất CSDL" "503 – dịch vụ còn sống nhưng không kết nối được CSDL" GET /api/health
  demo "Gọi nghiệp vụ khi mất CSDL" "503 CSDL_KHONG_KHA_DUNG + Retry-After, kèm mã tra cứu – không lộ SQL / tên lớp lỗi" GET /api/customers TOKEN_NV "$NV"
  MA=$(grep -oE '"ma_tra_cuu":"[^"]+"' <<<"$RESP" | cut -d'"' -f4)
  if [ -n "$MA" ] && [ -f src/log/development.log ]; then
    echo; echo "${B}━━━ Kỹ sư tìm sự cố theo mã tra cứu người dùng báo: $MA${N}"
    echo "    \$ grep \"$MA\" src/log/development.log"
    grep -F "$MA" src/log/development.log | grep -E "CSDL_KHONG_KHA_DUNG|Started|Completed" | cut -c1-220 | sed 's/^/      /'
  fi
  echo; echo "   Bật lại CSDL: ${B}sudo service postgresql start${N}"
fi

rm -f "$TMP" "$TMP.h"
echo; echo "${G}${B}Xong demo: $STEP tình huống lỗi.${N}"
