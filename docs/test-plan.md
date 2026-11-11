# Test Plan — Luồng L2: Tiếp nhận và phân loại yêu cầu bảo hành (track SE)

Thái An Quốc – 2374802012635 · Smart CRM – Mekong Mobile · Rails 8.1 + PostgreSQL 18 · Minitest

## 1. Phạm vi kiểm thử và phần chủ ý KHÔNG kiểm

**Kiểm:** đăng nhập / đăng xuất và phân quyền theo vai trò (NFR05, TD-24, TD-29) · tra cứu khách hàng (UC01, UC08) ·
thêm khách hàng · tạo yêu cầu bảo hành (BR01–BR06) · danh sách và lọc quá hạn (BR10) · đổi trạng thái (BR08, BR09) ·
sửa / xóa yêu cầu (TD-29) · nạp lại dữ liệu mẫu không nhân đôi (TD-28) · ràng buộc dữ liệu BR11–BR14.

**Cố ý KHÔNG kiểm (và lý do):**
- Hiệu năng, tải đồng thời: thuộc Chuyên đề tốt nghiệp 2.
- Kiểm thử giao diện bằng trình duyệt tự động (Selenium / Capybara): chậm và dễ vỡ; giao diện đã được kiểm ở mức
  HTML bằng integration test (`src/test/integration/*`).
- Kiểm soát truy cập theo CHỦ SỞ HỮU từng bản ghi: luồng L2 không có tài khoản khách hàng, Nhân viên tiếp nhận dùng
  chung một hàng đợi nên quyền được kiểm theo VAI TRÒ (TD-29); test bảo mật kiểm vai trò Quản lý bị chặn (TC-11).
- `service_centers.csv`: thiết kế chưa có bảng trung tâm (TD-28).

## 2. Loại test và số lượng mỗi tầng

- Bộ test tự động: **131 test**, chạy bằng MỘT lệnh `bin/rails test` (thư mục `src`, hoặc trong container theo
  `docs/deployment-guide.md`): unit / service `src/test/services/` (máy tính hạn cam kết, sinh mã, làm sạch dữ liệu,
  máy trạng thái, CRUD service) · integration `src/test/integration/` (controller + router + CSDL thật, gồm API).
- Test Report: **16 test case** chạy thật — 12 integration (TC-01–04, 07–11, 13–15) · 2 system / API qua curl vào
  server thật (TC-05, TC-06) · 1 service + CSDL (TC-12) · 1 integration + API thật (TC-16).
- Đủ 5 loại: luồng đúng ×6 (TC-01, 03, 07, 09, 14, 15) · giá trị biên ×2 (TC-05 / TC-06, hai bên ranh giới SĐT 10 chữ
  số) · dữ liệu sai ×2 (TC-02, TC-08) · bảo mật ×3 (TC-11 A01, TC-13 A07, TC-16 A05) · tái lập ×1 (TC-12); thêm luồng
  ngoại lệ UC08 (TC-04) và vi phạm BR08 (TC-10).
- Kỹ thuật chọn dữ liệu: phân vùng tương đương (SĐT hợp lệ / sai độ dài; yêu cầu đủ / thiếu trường) và giá trị biên.
  Kết quả mong đợi kiểm cả mã trạng thái, thông báo lỗi VÀ tác dụng phụ (đếm bản ghi trước / sau).

**Truy vết — mỗi quy tắc nghiệp vụ đã hiện thực có ít nhất một test:**

| Quy tắc (`docs/srs.md`) | Test case trong Test Report | Test tự động khác trong `bin/rails test` |
|---|---|---|
| BR01 Xác định khách hàng trước khi tạo yêu cầu | TC-03, TC-06, TC-07 | `customer_service_test.rb:55` |
| BR02 Thông tin thiết bị đủ, ngày mua không ở tương lai | TC-08 | `warranty_request_updater_test.rb:43` |
| BR03 Có nhóm sự cố và mức ưu tiên | TC-07, TC-08 | `issue_category_service_test.rb:25` |
| BR04 Thiếu / sai thông tin thì không tạo | TC-08 | — |
| BR05 Mã `BH-YYYY-NNNNNN`, trạng thái đầu Mới tiếp nhận | TC-07 | `request_code_generator_test.rb` |
| BR06 Hạn cam kết = lúc tạo + SLA | TC-07, TC-14 | `sla_deadline_calculator_test.rb`, `warranty_request_updater_test.rb:22` |
| BR07 Không tìm thấy khách thì không cho tạo | TC-04 | — |
| BR08 Chuyển trạng thái đúng thứ tự | TC-10 | `warranty_request_status_changer_test.rb:20` |
| BR09 Hủy phải có lý do; ghi lịch sử | — | `warranty_request_status_changer_test.rb:39`, `api_warranty_requests_test.rb:115` |
| BR10 Quá hạn tính khi truy vấn | TC-09 | `warranty_request_status_changer_test.rb:63` |
| BR11 Một serial chỉ thuộc một khách | — | `warranty_request_creation_test.rb:63`, `api_warranty_requests_test.rb:94` |
| BR12 Mã khách hàng tự sinh | TC-05 | `customer_service_test.rb:10` |
| BR13 Không xóa khách đã có thiết bị | — | `customer_service_test.rb:63` |
| BR14 Không xóa nhóm sự cố đang dùng | — | `issue_category_service_test.rb:32` |
| NFR05 / TD-24 Đăng nhập, phiên | TC-01, TC-02, TC-13 | `api_sessions_test.rb` |
| TD-29 Phân quyền vai trò (OWASP A01) | TC-11, TC-14, TC-15 | `authorization_test.rb` |

## 3. Tiêu chí thành công ĐO ĐƯỢC (đặt trước khi chạy)

- 16/16 test case có kết quả thực tế ghi bằng số liệu cụ thể và ảnh `docs/screenshots/TC-xx.png`.
- Mỗi quy tắc BR01–BR14 có ≥ 1 test (bảng truy vết ở mục 2).
- `bin/rails test` PASS toàn bộ (0 failures, 0 errors) cả trên máy lẫn trong container.
- Không còn bug Critical đang mở; bug Major còn lại (nếu có) ghi lý do và hướng xử lý trong `docs/bug-log.md`.

## 4. Môi trường và dữ liệu thử

- Máy phát triển: Windows + WSL 2 (Ubuntu), Ruby 4.0.5, Rails 8.1, PostgreSQL 18. Gói Docker: `docker compose`
  với PostgreSQL 18 và app Ruby 4.0.5 (`docs/deployment-guide.md`).
- Test tự động: CSDL test riêng (`src_test`), mỗi test tự dựng dữ liệu trong `setup` và chạy trong transaction được
  rollback — không phụ thuộc dữ liệu có sẵn trên máy; chạy song song thì mỗi tiến trình một CSDL riêng.
- Test thủ công qua API (TC-05, TC-06, TC-12, TC-16): `bin/rails db:reset` nạp bộ dữ liệu L2 trong `data/mau/` và
  2 tài khoản demo, rồi `bin/rails server`. Dọn: chạy lại `bin/rails db:reset`.
- Chạy từng test case: `bash scripts/tc.sh TC-05`; chạy và chụp cả 16: `bash scripts/chup-tc.sh`.
