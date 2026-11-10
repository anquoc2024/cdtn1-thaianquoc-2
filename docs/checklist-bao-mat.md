# Checklist bảo mật — Luồng L2: Tiếp nhận và phân loại yêu cầu bảo hành

Thái An Quốc – 2374802012635 · BT3, thành phần 5 · Đối chiếu OWASP Top 10:2025 ở mức nhận biết

Mỗi mục được kiểm bằng **lệnh chạy thật** trên gói Docker (`docker compose down -v && docker compose up -d --build`),
ngày 10/11/2026, bằng script `scripts/kiem-bao-mat.sh`. Kết quả chữ của mọi lần chạy: `docs/sec-ket-qua.txt`;
ảnh từng mục: `docs/screenshots/sec-N.png`. Chạy checklist tìm ra 3 bug thật (BUG-06, BUG-07, BUG-08 – xem
`docs/bug-log.md`); ba bug đã được sửa, mỗi bug một commit riêng, rồi chạy lại các mục liên quan.

| # | Mục | OWASP | Trạng thái |
|---|---|---|---|
| 1 | Không có secret nào trong repo | A02 | ĐÃ LÀM |
| 2 | Dữ liệu vào được kiểm ở tầng ứng dụng | A05 | ĐÃ LÀM |
| 3 | Kiểm soát truy cập | A01 | ĐÃ LÀM (theo vai trò) |
| 4 | Mật khẩu, dữ liệu nhạy cảm được băm / mã hóa | A04 · A07 | ĐÃ LÀM (mật khẩu) · CHƯA LÀM (API token) |
| 5 | Thông báo lỗi không lộ cấu trúc bên trong | A10 · A02 | ĐÃ LÀM (sau khi sửa BUG-07) |
| 6 | Nhật ký không ghi secret, dữ liệu cá nhân | A09 | ĐÃ LÀM (sau khi sửa BUG-08) |
| 7 | Phụ thuộc ghim phiên bản, đã kiểm lỗ hổng | A03 | ĐÃ LÀM (sau khi sửa BUG-06) |

## 1. Không có secret nào trong repo — ĐÃ LÀM

Minh chứng: `git ls-files | grep -E '(^|/)\.env$|master\.key$'` → rỗng · `git log --all --oneline -- .env src/.env
src/config/master.key` → rỗng (chưa từng vào lịch sử) · `git check-ignore -v` → `.gitignore:6:.env`,
`.gitignore:11:src/config/master.key` · `git grep` tìm khóa ghi cứng (`secret_key_base`, `api_key`, `access_key`,
`private_key`) → rỗng · trong image Docker: `ls /rails/.env /rails/config/master.key` → `No such file or directory`
(`.dockerignore` chặn). `.env.example` chỉ có giá trị mẫu, ghi rõ phải đổi khi triển khai thật.
Ảnh: `docs/screenshots/sec-1.png`

## 2. Dữ liệu vào được kiểm ở tầng ứng dụng — ĐÃ LÀM

Minh chứng: tìm SQL ghép chuỗi `#{…}` trong `src/app`, `src/lib` → chỉ 2 dòng, đều ghép **hằng số** khóa advisory lock
(`customer_service.rb:18`, `request_code_generator.rb:11`), không có dữ liệu người dùng; mọi truy vấn khác qua
ActiveRecord có tham số hóa · `GET /api/customers?q=' OR '1'='1` → `"data":[]`, `"tong_so":0` · `POST /api/customers`
với SĐT 9 chữ số → `400 DU_LIEU_KHONG_HOP_LE`, trường `phone`. Test kèm theo PASS: TC-06, TC-08, TC-16.
Ảnh: `docs/screenshots/sec-2.png`

## 3. Kiểm soát truy cập — ĐÃ LÀM (theo vai trò)

Phạm vi: luồng L2 không có tài khoản khách hàng; mọi nhân viên của trung tâm làm việc trên chung một danh sách yêu
cầu, nên quyền được kiểm **theo vai trò** (`User::PERMISSIONS`, TD-29), không theo chủ sở hữu từng bản ghi.
Minh chứng: gọi API không có token → `401 CHUA_XAC_THUC` · tài khoản Quản lý trung tâm sửa, xóa, đổi trạng thái một
yêu cầu → cả 3 lệnh `403 KHONG_CO_QUYEN` · test TC-11 (giao diện web) PASS.
Ảnh: `docs/screenshots/sec-3.png`, `docs/screenshots/TC-11.png`

## 4. Mật khẩu, dữ liệu nhạy cảm được băm / mã hóa — ĐÃ LÀM (mật khẩu) · CHƯA LÀM (API token)

Minh chứng: `password_digest` của 2 tài khoản bắt đầu bằng `$2a$12$…`, dài 60 ký tự — bcrypt qua `has_secure_password`,
không đọc ngược được · cột của bảng `users` liên quan: `["password_digest", "api_token"]`.
Chưa làm: `api_token` được lưu **nguyên văn** và **không có hạn dùng** (không có cột hết hạn). Hiện đã giảm rủi ro
bằng: đăng xuất API (`DELETE /api/session`) đổi token, token cũ hết dùng được (test "đăng xuất: 204, token cũ không dùng
được nữa" PASS); token không bao giờ ghi vào log (mục 6).
Kế hoạch: lưu bản băm SHA-256 của token thay cho token gốc, thêm cột `api_token_expires_at` (ví dụ 30 ngày) và đổi
token mỗi lần đăng nhập — làm sau khi nộp BT3.
Ảnh: `docs/screenshots/sec-4.png`

## 5. Thông báo lỗi không lộ cấu trúc bên trong — ĐÃ LÀM (sau khi sửa BUG-07)

Minh chứng: đường dẫn không tồn tại → `404 {"status":404,"error":"Not Found"}` · tắt CSDL (`docker compose stop db`)
→ `/api/health` trả `503 {"status":"degraded", … "ma_tra_cuu":…}`, API trả `503 CSDL_KHONG_KHA_DUNG` kèm mã tra cứu;
đếm dòng chứa `PG::`, `postgres://`, `backtrace`, `/rails/`, `db:5432`, `password` trong phản hồi → **0** · bật lại CSDL
→ `{"status":"ok","db":"ok"}`.
Phát hiện khi kiểm: JSON hỏng trả `500 LOI_HE_THONG` (không lộ thông tin nhưng sai mã, báo động giả) → **BUG-07**,
sửa ở commit `1ac9df3`; chạy lại → `400 Bad Request`, `DU_LIEU_KHONG_HOP_LE`.
Ảnh: `docs/screenshots/BUG-07-truoc.png` (trước), `docs/screenshots/sec-5.png` (sau)

## 6. Nhật ký không ghi secret, dữ liệu cá nhân — ĐÃ LÀM (sau khi sửa BUG-08)

Minh chứng (trên log container, gồm cả lần nạp dữ liệu đầu tiên): API token thật của 2 người dùng xuất hiện **0 lần** ·
dòng có số điện thoại 10 chữ số → **0** · tham số đăng nhập ghi `"email_address" => "[FILTERED]"`,
`"password" => "[FILTERED]"`, từ khóa tra cứu ghi `q=[FILTERED]` (`filter_parameter_logging.rb`) · mỗi dòng log có mã
yêu cầu (request id) để lần theo.
Phát hiện khi kiểm: 2 dòng log chứa mật khẩu demo `Mekong@2026` do seed in ra → **BUG-08**, sửa ở commit `50d456d`;
`down -v` → `up` → chạy lại → `(không có)`.
Ảnh: `docs/screenshots/BUG-08-truoc.png` (trước), `docs/screenshots/sec-6.png` (sau)

## 7. Phụ thuộc ghim phiên bản, đã kiểm lỗ hổng — ĐÃ LÀM (sau khi sửa BUG-06)

Minh chứng: `src/Gemfile.lock` và `src/config/importmap.rb` đã commit (ghim phiên bản gem và gói JavaScript) ·
`bin/importmap audit` → `No vulnerable packages found` · `bin/brakeman` (phân tích tĩnh) → 2 cảnh báo mức **Weak**
loại *HTTP Verb Confusion* (`authentication.rb:40`, `database_unavailable_responder.rb:52`): request `HEAD` không
được ghi nhớ làm trang quay lại sau đăng nhập — không ảnh hưởng quyền truy cập, ghi nhận và chưa sửa.
Phát hiện khi kiểm: `bin/bundler-audit check --update` báo 44 lỗ hổng đã công bố ở 11 gem (1 Critical, 5 High) →
**BUG-06**, sửa ở commit `e7c4923` (Rails 8.1.4.1, rack 3.2.8, nokogiri 1.19.7, rails-html-sanitizer 1.7.2…);
chạy lại → `No vulnerabilities found`.
Ảnh: `docs/screenshots/BUG-06-truoc.png` (trước), `docs/screenshots/sec-7.png` (sau)
