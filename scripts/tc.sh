#!/usr/bin/env bash
# Chạy từng test case của docs/test-report.md và in đủ: lệnh · kết quả · đếm trước / sau.
#   bash scripts/tc.sh TC-05        # một test case
#   bash scripts/tc.sh all          # cả 16
# TC-05, TC-06, TC-16 cần server đang chạy (cd src && bin/rails server) và dữ liệu seed (bin/rails db:reset).
# Chụp màn hình kết quả mỗi test case → docs/screenshots/TC-xx.png
cd "$(dirname "$0")/../src" || exit 1
BASE="${BASE_URL:-http://127.0.0.1:3000}"
B=$'\e[1m'; N=$'\e[0m'

head_tc() { echo; echo "${B}════ $1 · $2 ════${N}"; date "+%Y-%m-%d %H:%M:%S"; }
run()     { echo "\$ $*"; eval "$@"; }
count()   { bin/rails runner "print $1.count" 2>/dev/null; }
auto()    { run "bin/rails test $1 -v 2>&1 | grep -E 'Test#|runs,|Failure|Error|Expected'"; }
token()   { curl -s -X POST "$BASE/api/session" -H "Content-Type: application/json" \
              -d "{\"email_address\":\"$1\",\"password\":\"Mekong@2026\"}" | sed -E 's/.*"token":"([^"]+)".*/\1/'; }

# ---------- Đăng nhập ----------
tc01() { head_tc TC-01 "Đăng nhập – đúng email, mật khẩu → vào trang theo vai trò";  auto test/integration/authentication_test.rb:31; }
tc02() { head_tc TC-02 "Đăng nhập – sai mật khẩu → báo lỗi, không tạo phiên";        auto test/integration/authentication_test.rb:23; }
# ---------- Tra cứu khách hàng ----------
tc03() { head_tc TC-03 "Tra cứu khách hàng – SĐT có dấu cách → tìm thấy";             auto test/integration/customer_lookup_test.rb:21; }
tc04() { head_tc TC-04 "Tra cứu khách hàng – không tìm thấy (UC08)";                  auto test/integration/customer_lookup_test.rb:54; }
# ---------- Thêm khách hàng (giá trị biên SĐT) ----------
tc05() {
  head_tc TC-05 "Thêm khách hàng – biên SĐT đúng 10 chữ số → 201 (API thật)"
  local nv; nv=$(token quoc@mekong.vn); local phone="09$(date +%s | tail -c 9)"
  echo "Khách hàng trước: $(count Customer)"
  echo "\$ curl -s -i -X POST $BASE/api/customers -H 'Authorization: Bearer <token NV>' -d '{\"name\":\"Khách TC05\",\"phone\":\"$phone\"}'"
  curl -s -i -X POST "$BASE/api/customers" -H "Authorization: Bearer $nv" -H "Content-Type: application/json" \
       -d "{\"name\":\"Khách TC05\",\"phone\":\"$phone\"}" | sed -n '1p;$p'; echo
  echo "Khách hàng sau:   $(count Customer)   (dữ liệu thử: phone=$phone – 10 chữ số)"
}

tc06() {
  head_tc TC-06 "Thêm khách hàng – biên SĐT 9 chữ số → 400, không tạo khách (API thật)"
  local nv; nv=$(token quoc@mekong.vn)
  echo "Khách hàng trước: $(count Customer)"
  echo "\$ curl -s -i -X POST $BASE/api/customers -H 'Authorization: Bearer <token NV>' -d '{\"name\":\"Khách TC06\",\"phone\":\"091234567\"}'"
  curl -s -i -X POST "$BASE/api/customers" -H "Authorization: Bearer $nv" -H "Content-Type: application/json" \
       -d '{"name":"Khách TC06","phone":"091234567"}' | sed -n '1p;$p'; echo
  echo "Khách hàng sau:   $(count Customer)   (dữ liệu thử: phone=091234567 – 9 chữ số)"
}

# ---------- Tạo yêu cầu bảo hành ----------
tc07() { head_tc TC-07 "Tạo yêu cầu – thành công: mã BH, Mới tiếp nhận, hạn +24h";    auto test/integration/warranty_request_creation_test.rb:32; }
tc08() { head_tc TC-08 "Tạo yêu cầu – thiếu trường bắt buộc → không tạo gì";          auto test/integration/warranty_request_creation_test.rb:53; }
# ---------- Danh sách yêu cầu ----------
tc09() { head_tc TC-09 "Danh sách yêu cầu – lọc Quá hạn";                              auto test/integration/manager_warranty_requests_test.rb:50; }
# ---------- Cập nhật trạng thái ----------
tc10() { head_tc TC-10 "Cập nhật trạng thái – nhảy cóc sang Hoàn tất bị chặn (BR08)"; auto test/integration/warranty_request_status_test.rb:33; }
# ---------- Phân quyền ----------
tc11() { head_tc TC-11 "Phân quyền – Quản lý không sửa, không xóa yêu cầu (A01)";     auto test/integration/authorization_test.rb:68; }
# ---------- Nạp dữ liệu ----------
tc12() {
  head_tc TC-12 "Nạp dữ liệu – chạy lần hai không nhân đôi (tái lập)"
  auto test/services/l2_dataset_importer_test.rb:70
  echo; echo "Trên CSDL development – trước: KH $(count Customer) · TB $(count Device) · YC $(count WarrantyRequest)"
  run "bin/rails import:l2 2>&1 | head -1"
  echo "Sau:                            KH $(count Customer) · TB $(count Device) · YC $(count WarrantyRequest)"
}

# ---------- Đăng xuất ----------
tc13() { head_tc TC-13 "Đăng xuất – xóa phiên, vào lại trang bị chuyển về đăng nhập"; auto test/integration/authentication_test.rb:57; }
# ---------- Sửa / xóa yêu cầu (Nhân viên tiếp nhận – TD-29) ----------
tc14() { head_tc TC-14 "Sửa yêu cầu – lưu thay đổi, ghi lịch sử Cập nhật thông tin";   auto test/integration/warranty_request_edit_test.rb:26; }
tc15() { head_tc TC-15 "Xóa yêu cầu – yêu cầu mất, thiết bị vẫn còn";                  auto test/integration/warranty_request_edit_test.rb:45; }
# ---------- Bảo mật tra cứu (A05) ----------
tc16() {
  head_tc TC-16 "Tra cứu khách hàng – chống SQL injection ' OR '1'='1 (A05)"
  auto test/integration/customer_lookup_test.rb:74
  echo; local nv; nv=$(token quoc@mekong.vn)
  echo "Trên server thật – tổng số khách trong CSDL: $(count Customer)"
  echo "\$ curl -s -G $BASE/api/customers --data-urlencode \"q=' OR '1'='1\" -H 'Authorization: Bearer <token NV>'"
  curl -s -G "$BASE/api/customers" --data-urlencode "q=' OR '1'='1" -H "Authorization: Bearer $nv"; echo
}

case "${1:-all}" in
  all) for i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16; do "tc$i"; done ;;
  TC-[0-9][0-9]) "tc${1#TC-}" ;;
  *) echo "Dùng: bash scripts/tc.sh TC-01 … TC-16 | all"; exit 1 ;;
esac
