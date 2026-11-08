# Test Plan — Luồng L2: Tiếp nhận và phân loại yêu cầu bảo hành (track SE)

Thái An Quốc – 2374802012635 · Smart CRM – Mekong Mobile · Rails 8.1 + PostgreSQL 18 · Minitest

## 1. Phạm vi

**Kiểm:**
- Tạo yêu cầu bảo hành: sinh mã BH-YYYY-NNNNNN (BR05), hạn cam kết = lúc tạo + SLA (BR06).
- Máy trạng thái Mới tiếp nhận → Đang xử lý → Hoàn tất, không nhảy cóc (BR08); hủy bắt buộc có lý do.
- Kiểm tra dữ liệu vào: SĐT 10 chữ số bắt đầu bằng 0 (BR01), trường bắt buộc (BR04), serial chỉ thuộc một khách (BR11).
- Xác thực bằng token và phân quyền theo vai trò (NFR05, TD-24, TD-29).
- Nạp lại dữ liệu mẫu không nhân đôi (tính tái lập).

**Cố ý KHÔNG kiểm (và lý do):**
- Hiệu năng, tải đồng thời: thuộc Chuyên đề tốt nghiệp 2.
- Giao diện bằng trình duyệt tự động (Selenium / Capybara): chậm và dễ vỡ; giao diện đã có test tích hợp
  ở mức HTML (`test/integration/*`) và ảnh chụp 3 trạng thái ở BT2.
- Kiểm soát truy cập theo CHỦ SỞ HỮU: hệ thống phân quyền theo VAI TRÒ — Nhân viên tiếp nhận dùng chung hàng
  đợi nên ai cũng sửa / xóa được mọi yêu cầu (TD-29). Test bảo mật kiểm vai trò Quản lý bị chặn.
- `service_centers.csv`: thiết kế chưa có bảng trung tâm (TD-28).

## 2. Loại test và số lượng

- Bộ test tự động: 128 test, chạy bằng MỘT lệnh `bin/rails test` (thư mục `src`).
- Test Report chọn 12 test case đại diện theo kim tự tháp:
  **4 unit / service** (TC-01, TC-02, TC-03, TC-08) · **6 integration** – Rails integration test gọi controller,
  router, CSDL thật mà không mở cổng (TC-06, TC-07, TC-09, TC-10, TC-11, TC-12) · **2 system / API** qua curl
  vào server đang chạy (TC-04, TC-05).
- Đủ 5 loại BT3: luồng đúng ×3 (TC-01–03) · giá trị biên ×2 (TC-04, TC-05 – hai bên ranh giới 10 chữ số) ·
  dữ liệu sai ×2 (TC-06, TC-07) · vi phạm quy tắc ×2 (TC-08, TC-09) · bảo mật ×2 (TC-10 A01, TC-11 A07) ·
  tái lập ×1 (TC-12).
- Kỹ thuật chọn dữ liệu: **phân vùng tương đương** (SĐT hợp lệ / sai độ dài / sai đầu số; yêu cầu đủ trường /
  thiếu trường) và **giá trị biên** (SĐT 10 chữ số – nhận, 9 chữ số – từ chối).
- Mọi kết quả mong đợi kiểm cả mã trạng thái, mã lỗi VÀ tác dụng phụ (đếm bản ghi trước / sau, trạng thái không đổi).

## 3. Tiêu chí thành công (đặt trước khi chạy)

- 12/12 test case có kết quả thực tế ghi bằng lời cụ thể và ảnh `docs/screenshots/TC-xx.png`.
- Mỗi quy tắc đã hiện thực trong phạm vi (BR01, BR04, BR05, BR06, BR08, BR11, NFR05) có ≥ 1 test.
- `bin/rails test` PASS toàn bộ (0 failures, 0 errors) sau khi sửa bug.
- Không còn bug Critical đang mở; bug Major còn lại (nếu có) ghi lý do và hướng xử lý trong `docs/bug-log.md`.

## 4. Môi trường và dữ liệu thử

- Ubuntu 26.04 (WSL 2), Ruby 4.0.5, Rails 8.1, PostgreSQL 18.
- Test tự động: CSDL `src_test`, mỗi test tự dựng dữ liệu trong `setup` và chạy trong transaction được rollback
  sau test — không phụ thuộc dữ liệu có sẵn trên máy.
- Test API thủ công (TC-04, TC-05, TC-12): `bin/rails db:reset` (seed bộ dữ liệu L2 của giảng viên trong
  `data/mau/`, 2 tài khoản `quoc@mekong.vn` / `phu@mekong.vn`), rồi `bin/rails server`.
- Chạy từng test case: `bash scripts/tc.sh TC-05` (in lệnh, kết quả, đếm trước / sau); chạy hết: `bash scripts/tc.sh all`.
