# Bug Log — Luồng L2: Tiếp nhận và phân loại yêu cầu bảo hành

Thái An Quốc – 2374802012635 · Mỗi bug một commit riêng `fix(...)`; link mở được ở cửa sổ ẩn danh (repo public).

| Mã | Mức | Tóm tắt | Commit |
|---|---|---|---|
| BUG-01 | Critical | Quản lý (chỉ được xem) vào được Tra cứu, Tạo yêu cầu và đổi trạng thái | [af9543a](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/af9543a7c40aa7bda883edde3b2c17da7ef72791) |
| BUG-02 | Major | Clone sạch thiếu `CustomerRowNormalizer`, không dựng được hệ thống | [717f4c5](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/717f4c57ec119762b5a46d7dba88d32065a3a502) |
| BUG-03 | Major | Thiếu route `/api` và `Api::WarrantyRequestsController`, API không dùng được | [ce377e4](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/ce377e41f1a843949bf8678149b2467993efef7d) |
| BUG-04 | Minor | Thẻ thống kê bị cắt dòng mốc so sánh | [515d960](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/515d960d13341264e7b83e68bab02a4443470a47) |
| BUG-05 | Minor | 3 test sửa / xóa yêu cầu hỏng do biến `@request` trùng biến của Rails | [a4d69bc](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/a4d69bcab84f3a97b37a5a1bca29485653385cd8) |

## BUG-01 — Quản lý trung tâm dùng được chức năng của Nhân viên tiếp nhận

1. **Mã và mức độ:** BUG-01 · CRITICAL — lỗ hổng kiểm soát truy cập (OWASP A01): vai trò chỉ được xem lại tạo
   và đổi trạng thái được yêu cầu, dữ liệu bị thay đổi thật (theo bảng quyền TD-24 lúc đó).
2. **Phát hiện bởi:** phép thử clone vào thư mục trống trước khi nộp BT2; test `test/integration/authorization_test.rb` (nay TC-11).
3. **Triệu chứng:** trên bản clone mới, đăng nhập `phu@mekong.vn` vẫn mở được Tra cứu khách hàng, Tạo yêu cầu và
   bấm đổi trạng thái; sidebar không khóa mục nào.
4. **Cách tái lập:** clone commit trước `af9543a` → `db:prepare`, `db:seed` → đăng nhập Quản lý → mở
   `/customers/search` và `PATCH /warranty_requests/:id/update_status` — thành công; luôn xảy ra (do thiếu mã, không phụ thuộc dữ liệu).
5. **Nguyên nhân:** khi commit TD-24, các dòng `require_permission` trong `CustomersController`,
   `WarrantyRequestsController` và phần khóa mục trong `_sidebar.html.erb` chưa được `git add`; máy phát triển
   chạy đúng vì còn bản chưa commit, repo thì thiếu.
6. **Cách sửa:** commit bổ sung `require_permission :lookup_customers`, `:create_requests`, `:view_requests`,
   `:change_status` ở hai controller và sidebar khóa mục theo `can?`; thêm bước `git status --short` phải trống
   trước khi push.
7. **Commit và xác nhận:** https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/af9543a7c40aa7bda883edde3b2c17da7ef72791 · chạy lại
   `authorization_test.rb` → PASS; phép thử clone sạch đạt. Hồi quy: TC-11 (Quản lý không sửa, không xóa yêu cầu).

## BUG-02 — Clone sạch không dựng được hệ thống vì thiếu CustomerRowNormalizer

1. **Mã và mức độ:** BUG-02 · MAJOR — người khác không dựng được hệ thống từ repo; trên máy phát triển vẫn chạy được.
2. **Phát hiện bởi:** phép thử clone vào thư mục trống theo README (BT2).
3. **Triệu chứng:** `bin/rails db:seed` và các test nạp CSV dừng với `NameError: uninitialized constant CustomerRowNormalizer`.
4. **Cách tái lập:** clone commit trước `717f4c5` → `bundle install` → `bin/rails db:prepare` → lỗi; luôn xảy ra trên bản clone mới.
5. **Nguyên nhân:** tệp `src/app/services/customer_row_normalizer.rb` (làm sạch SĐT, họ tên, email) chưa được
   `git add` khi commit TD-23; `CustomerCsvImporter` gọi lớp này nên mọi lệnh nạp dữ liệu đều hỏng.
6. **Cách sửa:** commit `src/app/services/customer_row_normalizer.rb` (88 dòng).
7. **Commit và xác nhận:** https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/717f4c57ec119762b5a46d7dba88d32065a3a502 · clone lại → `db:prepare`
   chạy hết; `test/services/customer_row_normalizer_test.rb` 5/5 PASS.

## BUG-03 — API yêu cầu bảo hành không dùng được: thiếu route và controller

1. **Mã và mức độ:** BUG-03 · MAJOR — toàn bộ `/api/warranty_requests` không dùng được; giao diện web vẫn tạo được
   yêu cầu (có cách làm khác).
2. **Phát hiện bởi:** `bin/rails test` sau khi thêm API (TD-21) — 12 errors.
3. **Triệu chứng:** gọi `GET /api/warranty_requests` trả 404 trang HTML; test API báo lỗi route / hằng số không tồn tại.
4. **Cách tái lập:** checkout commit trước `ce377e4` → `bin/rails test test/integration/api_warranty_requests_test.rb` → 12 errors.
5. **Nguyên nhân:** `config/routes.rb` thiếu `namespace :api` và tệp
   `app/controllers/api/warranty_requests_controller.rb` chưa được commit.
6. **Cách sửa:** thêm `namespace :api` (health, warranty_requests, PATCH status) vào `routes.rb` và commit controller.
7. **Commit và xác nhận:** https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/ce377e41f1a843949bf8678149b2467993efef7d · chạy lại
   `api_warranty_requests_test.rb` → PASS. Hồi quy: TC-05, TC-06 (gọi API thật qua `namespace :api`).

## BUG-04 — Thẻ thống kê bị cắt dòng mốc so sánh

1. **Mã và mức độ:** BUG-04 · MINOR — chỉ ảnh hưởng trình bày, số liệu và nghiệp vụ vẫn đúng.
2. **Phát hiện bởi:** kiểm tra giao diện Màn hình 3 khi chụp ảnh minh chứng.
3. **Triệu chứng:** dưới 4 thẻ thống kê, dòng mốc so sánh ("hôm qua: 0", "trên 14 yêu cầu đang mở"…) bị cắt nửa dưới.
4. **Cách tái lập:** đăng nhập → Danh sách yêu cầu → nhìn đáy 4 thẻ; xảy ra mọi lần.
5. **Nguyên nhân:** Propshaft nạp CSS theo bảng chữ cái; `.stat { height: auto }` trong `states.css` bị
   `.stat { height: 84px; overflow: hidden }` trong `warranty.css` (nạp sau) đè.
6. **Cách sửa:** đổi selector thành `.stats .stat` trong `src/app/assets/stylesheets/states.css` để có độ ưu tiên cao hơn.
7. **Commit và xác nhận:** https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/515d960d13341264e7b83e68bab02a4443470a47 · Ctrl + Shift + R → 4 thẻ hiện đủ dòng mốc;
   `bin/rails test` PASS.

## BUG-05 — 3 test sửa / xóa yêu cầu hỏng do biến @request

1. **Mã và mức độ:** BUG-05 · MINOR — lỗi ở code test; chức năng sửa / xóa trên giao diện vẫn đúng.
2. **Phát hiện bởi:** `bin/rails test` (Buổi 14) — 128 runs, 2 failures, 1 error.
3. **Triệu chứng:** `warranty_request_edit_test.rb`: mở form sửa ra 404; redirect tới
   `/warranty_requests/#<ActionDispatch::Request…>`; `NoMethodError: undefined method 'reload' for ActionDispatch::Request`.
4. **Cách tái lập:** `bin/rails test test/integration/warranty_request_edit_test.rb` → 3/4 test hỏng, lặp lại ở mọi lần chạy.
5. **Nguyên nhân:** test đặt biến `@request` cho yêu cầu bảo hành, trùng biến nội bộ `@request` của
   `ActionDispatch::IntegrationTest`; sau lệnh `get` / `patch` đầu tiên Rails ghi đè thành đối tượng Request.
6. **Cách sửa:** đổi `@request` → `@warranty_request` trong `src/test/integration/warranty_request_edit_test.rb`.
7. **Commit và xác nhận:** https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/a4d69bcab84f3a97b37a5a1bca29485653385cd8 · chạy lại tệp test → 4/4 PASS; toàn bộ `bin/rails test` → 0 failures,
   0 errors (ảnh `docs/screenshots/BUG-05-fixed.png`).
