# Ảnh chụp minh chứng – Bài tập 2

Ảnh chụp thật khi chạy hệ thống trên máy phát triển (Ubuntu 26.04 / WSL 2, Rails 8.1, PostgreSQL 18).
Cùng bộ ảnh được dùng trong báo cáo `BT2_2374802012635_ThaiAnQuoc/BT2_2374802012635_ThaiAnQuoc.pdf`.
Token xuất hiện trong ảnh là token của tài khoản demo trên CSDL máy phát triển, đã bị thu hồi
(`DELETE /api/session` cấp token mới) – không dùng được ở nơi khác.

| Tệp | Nội dung | Trong báo cáo |
|---|---|---|
| [`01-so-do-kien-truc-thuc-te.png`](01-so-do-kien-truc-thuc-te.png) | Sơ đồ kiến trúc đã hiện thực | Báo cáo Hình 2.1 |
| [`02-kiem-tra-ranh-gioi-lop.png`](02-kiem-tra-ranh-gioi-lop.png) | grep: không có dấu vết HTTP trong app/services | Mục 2.3 |
| [`03-api-lay-token.png`](03-api-lay-token.png) | curl: POST /api/session lấy token nhân viên | Mục 3.4 |
| [`04-api-tao-khach-va-xoa-409.png`](04-api-tao-khach-va-xoa-409.png) | curl: tạo khách 201; xóa khách có thiết bị → 409 DANG_DUOC_SU_DUNG (BR13) | Hình 3.1, 3.2 |
| [`05-api-xoa-khach-204.png`](05-api-xoa-khach-204.png) | curl: xóa khách mới tạo → 204 No Content | Hình 3.2 |
| [`06-api-tao-yeu-cau-201.png`](06-api-tao-yeu-cau-201.png) | curl: tạo yêu cầu bảo hành → mã BH, hạn cam kết +24h | Hình 3.3 |
| [`07-api-nhay-coc-422.png`](07-api-nhay-coc-422.png) | curl: chuyển thẳng sang Hoàn tất → 422 | Hình 3.4 |
| [`08-api-chuyen-trang-thai-200.png`](08-api-chuyen-trang-thai-200.png) | curl: in_progress → completed đúng quy trình | Hình 3.4 |
| [`09-loi-503-trang-web.png`](09-loi-503-trang-web.png) | Tắt PostgreSQL: trang 503 có mã tra cứu và nút Thử lại | Hình 3.5 (TD-27) |
| [`10-loi-503-api-health.png`](10-loi-503-api-health.png) | Tắt PostgreSQL: /api/health → 503 kèm ma_tra_cuu | Hình 3.5 (TD-27) |
| [`11-api-health-200.png`](11-api-health-200.png) | curl /api/health → 200 ok | Mục 3.5 |
| [`12-postman-dang-nhap-nhan-vien.png`](12-postman-dang-nhap-nhan-vien.png) | Postman: đăng nhập Nhân viên tiếp nhận → 200, token | Mục 3.5 |
| [`13-postman-dang-nhap-quan-ly.png`](13-postman-dang-nhap-quan-ly.png) | Postman: đăng nhập Quản lý trung tâm → 200, quyền chỉ xem | Mục 3.5 |
| [`14-script-kiem-tra-api-phan-1.png`](14-script-kiem-tra-api-phan-1.png) | scripts/kiem-tra-api.sh: nhóm 00–04 PASS | Mục 3.5 |
| [`15-script-kiem-tra-api-phan-2.png`](15-script-kiem-tra-api-phan-2.png) | scripts/kiem-tra-api.sh: nhóm 05–08, tổng 40 PASS | Mục 3.5 |
| [`16-bin-rails-test-pass.png`](16-bin-rails-test-pass.png) | bin/rails test: 115 runs, 0 failures, 0 errors | Hình 4.1 |
| [`20-man-hinh-1-tim-thay.png`](20-man-hinh-1-tim-thay.png) | Màn hình 1: tìm thấy khách hàng, Network gọi /api/customers | Mục 5.1 |
| [`21-man-hinh-1-the-khach-hang.png`](21-man-hinh-1-the-khach-hang.png) | Màn hình 1: thẻ khách hàng và nút Chọn khách hàng | Mục 5.1 |
| [`22-man-hinh-1-rong.png`](22-man-hinh-1-rong.png) | Màn hình 1 – RỖNG: không tìm thấy khách hàng (UC08), request fetch 200 | Mục 5.1 |
| [`23-man-hinh-1-loi.png`](23-man-hinh-1-loi.png) | Màn hình 1 – LỖI: Offline, khung đỏ + nút Thử lại, 3 request failed | Mục 5.1 |
| [`30-man-hinh-2-loi.png`](30-man-hinh-2-loi.png) | Màn hình 2 – LỖI: Offline khi tạo yêu cầu, nút Thử lại | Mục 5.2 |
| [`31-phieu-tiep-nhan.png`](31-phieu-tiep-nhan.png) | Phiếu tiếp nhận sau khi tạo yêu cầu thành công | Mục 5.2 |
| [`32-phieu-tiep-nhan-qua-han.png`](32-phieu-tiep-nhan-qua-han.png) | Phiếu tiếp nhận của yêu cầu quá hạn | Mục 5.2 |
| [`33-phieu-tiep-nhan-quan-ly-chi-xem.png`](33-phieu-tiep-nhan-quan-ly-chi-xem.png) | Quản lý xem phiếu: không có nút đổi trạng thái | NFR05 |
| [`40-man-hinh-3-danh-sach.png`](40-man-hinh-3-danh-sach.png) | Màn hình 3: thẻ thống kê có mốc so sánh, Network /api/warranty_requests + /api/stats | Mục 5.3 |
| [`41-man-hinh-3-loi.png`](41-man-hinh-3-loi.png) | Màn hình 3 – LỖI: Offline, khung đỏ + nút Thử lại | Mục 5.3 |
| [`42-man-hinh-3-quan-ly.png`](42-man-hinh-3-quan-ly.png) | Màn hình 3 với tài khoản Quản lý trung tâm | Mục 5.3 |
| [`43-man-hinh-3-chi-tiet-request.png`](43-man-hinh-3-chi-tiet-request.png) | DevTools: chi tiết request GET /api/warranty_requests | Mục 5.3 |

Nhóm số đầu tệp: `0x–1x` API và kiểm thử · `2x` Màn hình 1 · `3x` Màn hình 2 và phiếu tiếp nhận · `4x` Màn hình 3.
