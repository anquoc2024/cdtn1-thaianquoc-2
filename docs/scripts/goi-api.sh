#!/usr/bin/env bash
# ============================================================
# Gọi thử 12 request API thật và lưu request + response vào
#   docs/api-ket-qua-thuc-te.md
# Dùng làm minh chứng "gọi thử endpoint bằng curl" (buổi 8) và
# dữ liệu thật cho docs/api-docs.md.
#
# Cách chạy (server phải đang chạy ở một tab khác):
#   cd ~/cdtn1-thaianquoc-2
#   bash docs/scripts/goi-api.sh
#
# LƯU Ý: script tạo 1 yêu cầu mới rồi hủy nó – chỉ chạy trên CSDL phát triển.
# ============================================================
set -u

BASE="${BASE:-http://localhost:3000}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/docs/api-ket-qua-thuc-te.md"
BODY="$(mktemp)"
HEAD="$(mktemp)"
trap 'rm -f "$BODY" "$HEAD"' EXIT

if ! curl -s -o /dev/null "$BASE/api/health"; then
  echo "Không gọi được $BASE – hãy chạy 'bin/rails server' trong src/ ở một tab khác trước." >&2
  exit 1
fi

# Lấy ID thật từ dữ liệu mẫu
cd "$ROOT/src"
read -r C K P EXISTING <<< "$(bin/rails runner '
  print Customer.find_by!(phone: "0905123456").id, " ",
        IssueCategory.first.id, " ",
        Priority.find_by!(name: "Cao").id, " ",
        WarrantyRequest.order(:id).first.id')"

{
  echo "# Kết quả gọi API thực tế"
  echo
  echo "Sinh tự động bởi \`docs/scripts/goi-api.sh\` lúc $(date '+%d/%m/%Y %H:%M:%S'), trên $BASE."
  echo "Mọi request và response dưới đây là **thật**, chép nguyên từ hệ thống đang chạy."
  echo
} > "$OUT"

# call "Tiêu đề" <các tham số curl…>
call() {
  local title="$1"; shift
  local code
  code="$(curl -s -D "$HEAD" -o "$BODY" -w '%{http_code}' "$@")"
  {
    echo "## $title"
    echo
    echo '```bash'
    printf 'curl'
    printf " '%s'" "$@"
    echo
    echo '```'
    echo
    echo "**HTTP $code**"
    loc="$(grep -i '^location:' "$HEAD" | tr -d '\r')"
    if [ -n "$loc" ]; then echo; echo "Header trả về: \`$loc\`"; fi
    echo
    echo '```json'
    python3 -m json.tool --no-ensure-ascii "$BODY" 2>/dev/null || cat "$BODY"
    echo '```'
    echo
  } >> "$OUT"
  printf '  %s  %s\n' "$code" "$title"
}

JSON=(-H 'Content-Type: application/json')
SERIAL="SN-CURL-$(date +%s)"
VALID="{\"customer_id\":$C,\"device_type\":\"Điện thoại\",\"brand\":\"Samsung\",\"model\":\"Galaxy S24\",\"serial_number\":\"$SERIAL\",\"purchase_date\":\"2026-05-01\",\"issue_description\":\"Màn hình chớp tắt\",\"issue_category_id\":$K,\"priority_id\":$P}"

echo "Đang gọi API…"
call "1. GET /api/health – dịch vụ còn sống"            "$BASE/api/health"
call "2. GET /api/warranty_requests – lọc Quá hạn"      "$BASE/api/warranty_requests?status=overdue"
call "3. GET /api/warranty_requests/:id – chi tiết"     "$BASE/api/warranty_requests/$EXISTING"
call "4. GET /api/warranty_requests/:id – không tồn tại (404)" "$BASE/api/warranty_requests/999999"
call "5. POST /api/warranty_requests – tạo thành công (201)" -X POST "${JSON[@]}" -d "$VALID" "$BASE/api/warranty_requests"

NEW_ID="$(bin/rails runner 'print WarrantyRequest.order(:id).last.id')"

call "6. POST – thiếu trường bắt buộc (400)" -X POST "${JSON[@]}" -d "{\"customer_id\":$C}" "$BASE/api/warranty_requests"
call "7. POST – khách hàng không tồn tại (404)" -X POST "${JSON[@]}" -d "${VALID/\"customer_id\":$C/\"customer_id\":999999}" "$BASE/api/warranty_requests"
call "8. POST – serial đã thuộc khách hàng khác (409)" -X POST "${JSON[@]}" -d "${VALID/$SERIAL/DL-INS-0002}" "$BASE/api/warranty_requests"
call "9. PATCH status – nhảy cóc sang completed (422)" -X PATCH "${JSON[@]}" -d '{"status":"completed"}' "$BASE/api/warranty_requests/$NEW_ID/status"
call "10. PATCH status – hủy không có lý do (400)" -X PATCH "${JSON[@]}" -d '{"status":"cancelled"}' "$BASE/api/warranty_requests/$NEW_ID/status"
call "11. PATCH status – hủy có lý do (200)" -X PATCH "${JSON[@]}" -d '{"status":"cancelled","note":"Khách xin nhận lại máy"}' "$BASE/api/warranty_requests/$NEW_ID/status"
call "12. PATCH status – yêu cầu đã đóng (409)" -X PATCH "${JSON[@]}" -d '{"status":"in_progress"}' "$BASE/api/warranty_requests/$NEW_ID/status"

echo
echo "Đã lưu: $OUT"
