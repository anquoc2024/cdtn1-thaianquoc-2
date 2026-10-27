#!/usr/bin/env bash
# Kiểm tra toàn bộ API Smart CRM bằng curl (BT2) – chạy từ gốc repo: bash scripts/kiem-tra-api.sh
# Yêu cầu: server đang chạy (cd src && bin/rails server). Đổi địa chỉ: BASE_URL=http://... bash scripts/kiem-tra-api.sh
BASE="${BASE_URL:-http://127.0.0.1:3000}"
PASS=0; FAIL=0; TMP=$(mktemp)
G=$'\e[32m'; R=$'\e[31m'; B=$'\e[1m'; N=$'\e[0m'

call() {   # call METHOD PATH TOKEN [BODY]
  local args=(-s -o "$TMP" -w '%{http_code}' -X "$1" "$BASE$2" -H "Content-Type: application/json")
  [ -n "$3" ] && args+=(-H "Authorization: Bearer $3")
  [ -n "$4" ] && args+=(-d "$4")
  CODE=$(curl "${args[@]}"); RESP=$(cat "$TMP")
}
check() {  # check "Tên ca" MA_HTTP_KY_VONG [MA_LOI_KY_VONG]
  local ok=1
  [ "$CODE" = "$2" ] || ok=0
  [ -n "$3" ] && ! grep -q "\"error\":\"$3\"" <<<"$RESP" && ok=0
  if [ $ok = 1 ]; then PASS=$((PASS+1)); printf "  ${G}PASS${N}  %-52s %s %s\n" "$1" "$CODE" "$3"
  else FAIL=$((FAIL+1)); printf "  ${R}FAIL${N}  %-52s nhận %s, mong đợi %s %s\n        %s\n" "$1" "$CODE" "$2" "$3" "${RESP:0:200}"; fi
}
first_id() { grep -oE '"id":[0-9]+' <<<"$RESP" | head -1 | cut -d: -f2; }
section()  { echo; echo "${B}$1${N}"; }

RUN=$(date +%s); PHONE="09${RUN: -8}"; SERIAL="SH-$RUN"; CAT_NAME="Nhóm script $RUN"
BUY=$(date -d '2 months ago' +%F)

section "00. Xác thực"
call POST /api/session "" '{"email_address":"quoc@mekong.vn","password":"Mekong@2026"}'
check "Đăng nhập Nhân viên tiếp nhận" 200
NV=$(sed -E 's/.*"token":"([^"]+)".*/\1/' <<<"$RESP")
call POST /api/session "" '{"email_address":"phu@mekong.vn","password":"Mekong@2026"}'
check "Đăng nhập Quản lý trung tâm" 200
QL=$(sed -E 's/.*"token":"([^"]+)".*/\1/' <<<"$RESP")
call POST /api/session "" '{"email_address":"quoc@mekong.vn","password":"sai-mat-khau"}'
check "Sai mật khẩu" 401 SAI_THONG_TIN_DANG_NHAP

section "01. Hệ thống"
call GET /api/health ""
check "Health check" 200

section "02. Khách hàng (CRUD)"
call GET "/api/customers?page=1" "$NV";               check "Danh sách khách hàng" 200
call GET "/api/customers?q=0912000111" "$NV";         check "Tra cứu theo SĐT ?q=" 200
call POST /api/customers "$NV" '{"name":"Khách script","phone":"'"$PHONE"'","email":"khach.script@mekong.vn","address":"1 Nguyễn Huệ, Q.1"}'
check "Tạo khách hàng (BR12 mã KH tự sinh)" 201
CUS=$(first_id); echo "        → id $CUS, mã $(grep -oE 'KH-[0-9]{6}' <<<"$RESP" | head -1)"
call GET "/api/customers/$CUS" "$NV";                 check "Xem chi tiết khách hàng" 200
call PATCH "/api/customers/$CUS" "$NV" '{"address":"99 Lê Lợi, Q.1"}'
check "Cập nhật khách hàng" 200
call POST /api/customers "$NV" '{"name":"Khách trùng","phone":"'"$PHONE"'"}'
check "Tạo trùng SĐT" 409 TRUNG_DU_LIEU
call POST /api/customers "$NV" '{"name":"Khách lỗi","phone":"123"}'
check "SĐT sai định dạng" 400 DU_LIEU_KHONG_HOP_LE
call DELETE /api/customers/1 "$NV";                   check "Xóa khách đang có thiết bị (BR13)" 409 DANG_DUOC_SU_DUNG
call DELETE "/api/customers/$CUS" "$NV";              check "Xóa khách vừa tạo" 204
call GET "/api/customers/$CUS" "$NV";                 check "Xem khách đã xóa" 404 KHONG_TIM_THAY

section "03. Nhóm sự cố (CRUD)"
call GET /api/issue_categories "$NV";                 check "Danh sách nhóm sự cố" 200
USED_CAT=$(grep -oE '\{"id":[0-9]+[^{}]*"usage_count":[1-9][0-9]*' <<<"$RESP" | head -1 | grep -oE '[0-9]+' | head -1)
[ -z "$USED_CAT" ] && USED_CAT=$(first_id)
call POST /api/issue_categories "$NV" '{"name":"'"$CAT_NAME"'","description":"Tạo từ script"}'
check "Tạo nhóm sự cố" 201
CAT=$(first_id)
call POST /api/issue_categories "$NV" '{"name":"'"${CAT_NAME^^}"'"}'
check "Tạo trùng tên (khác hoa thường)" 409 TRUNG_DU_LIEU
call PATCH "/api/issue_categories/$CAT" "$NV" '{"description":"Đã sửa"}'
check "Cập nhật nhóm sự cố" 200
call DELETE "/api/issue_categories/$USED_CAT" "$NV";  check "Xóa nhóm đang được dùng (BR14)" 409 DANG_DUOC_SU_DUNG
call DELETE "/api/issue_categories/$CAT" "$NV";       check "Xóa nhóm vừa tạo" 204

section "04. Danh mục"
call GET /api/priorities "$NV";                       check "Danh sách mức ưu tiên" 200
PRI=$(first_id)

section "05. Yêu cầu bảo hành"
BODY='{"customer_id":1,"device_type":"Điện thoại","brand":"Samsung","model":"Galaxy A55","serial_number":"'"$SERIAL"'","purchase_date":"'"$BUY"'","issue_description":"Máy sập nguồn liên tục","issue_category_id":'"$USED_CAT"',"priority_id":'"$PRI"'}'
call POST /api/warranty_requests "$NV" "$BODY";       check "Tạo yêu cầu bảo hành" 201
REQ=$(first_id); echo "        → id $REQ, mã $(grep -oE 'BH-[0-9-]+' <<<"$RESP" | head -1)"
call POST /api/warranty_requests "$NV" '{"customer_id":1,"device_type":"Điện thoại"}'
check "Thiếu trường bắt buộc" 400 DU_LIEU_KHONG_HOP_LE
call POST /api/warranty_requests "$NV" "${BODY/\"customer_id\":1/\"customer_id\":2}"
check "Serial thuộc khách khác" 409 SERIAL_THUOC_KHACH_KHAC
call POST /api/warranty_requests "$NV" '{"customer_id":999999}'
check "Khách hàng không tồn tại" 404 KHACH_HANG_KHONG_TON_TAI
call GET "/api/warranty_requests?page=1" "$NV";       check "Danh sách yêu cầu" 200
call GET "/api/warranty_requests?status=received" "$NV"; check "Lọc theo trạng thái" 200
call GET "/api/warranty_requests/$REQ" "$NV";         check "Xem chi tiết yêu cầu" 200
call PATCH "/api/warranty_requests/$REQ/status" "$NV" '{"status":"completed"}'
check "Nhảy cóc sang completed" 422 CHUYEN_TRANG_THAI_KHONG_HOP_LE
call PATCH "/api/warranty_requests/$REQ/status" "$NV" '{"status":"in_progress"}'
check "Chuyển sang in_progress" 200
call PATCH "/api/warranty_requests/$REQ/status" "$NV" '{"status":"completed"}'
check "Chuyển sang completed" 200
call PATCH "/api/warranty_requests/$REQ/status" "$NV" '{"status":"in_progress"}'
check "Đổi trạng thái yêu cầu đã đóng" 409 YEU_CAU_DA_DONG

section "06. Thống kê"
call GET /api/stats "$NV";                            check "Thống kê dashboard" 200

section "07. Phân quyền & bảo mật"
call GET /api/customers "";                           check "Không có token" 401 CHUA_XAC_THUC
call GET /api/customers "token-sai";                  check "Token sai" 401 CHUA_XAC_THUC
call GET /api/warranty_requests "$QL";                check "Quản lý xem danh sách yêu cầu" 200
call POST /api/customers "$QL" '{"name":"Không được tạo","phone":"0900000000"}'
check "Quản lý tạo khách hàng" 403 KHONG_CO_QUYEN
call PATCH "/api/warranty_requests/$REQ/status" "$QL" '{"status":"cancelled","note":"thử"}'
check "Quản lý đổi trạng thái" 403 KHONG_CO_QUYEN

section "08. Đăng xuất"
call DELETE /api/session "$NV";                       check "Đăng xuất Nhân viên" 204
call GET /api/customers "$NV";                        check "Dùng lại token cũ" 401 CHUA_XAC_THUC

rm -f "$TMP"
echo; echo "${B}Tổng: $((PASS+FAIL)) ca · ${G}$PASS PASS${N}${B} · ${R}$FAIL FAIL${N}"
[ "$FAIL" = 0 ]
