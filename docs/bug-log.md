# Bug Log — Luồng L2: Tiếp nhận và phân loại yêu cầu bảo hành

Thái An Quốc – 2374802012635 · Mỗi bug một commit riêng `fix(...)`; link mở được ở cửa sổ ẩn danh (repo public).

| Mã | Mức | Tóm tắt | Commit |
|---|---|---|---|
| BUG-01 | Critical | Quản lý (chỉ được xem) vào được Tra cứu, Tạo yêu cầu và đổi trạng thái | [af9543a](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/af9543a7c40aa7bda883edde3b2c17da7ef72791) |
| BUG-02 | Major | Clone sạch thiếu `CustomerRowNormalizer`, không dựng được hệ thống | [717f4c5](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/717f4c57ec119762b5a46d7dba88d32065a3a502) |
| BUG-03 | Major | Thiếu route `/api` và `Api::WarrantyRequestsController`, API không dùng được | [ce377e4](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/ce377e41f1a843949bf8678149b2467993efef7d) |
| BUG-04 | Minor | Thẻ thống kê bị cắt dòng mốc so sánh | [515d960](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/515d960d13341264e7b83e68bab02a4443470a47) |
| BUG-05 | Minor | 3 test sửa / xóa yêu cầu hỏng do biến `@request` trùng biến của Rails | [a4d69bc](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/a4d69bcab84f3a97b37a5a1bca29485653385cd8) |
| BUG-06 | Major | 11 gem (Rails, rack, nokogiri…) có 44 lỗ hổng đã công bố, gồm 1 Critical và 5 High | [e7c4923](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/e7c49235b1f9d6a09734586af0c617862c3495b7) |
| BUG-07 | Minor | Gửi JSON hỏng bị trả 500 `LOI_HE_THONG` thay vì 400 | [1ac9df3](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/1ac9df33586f8236c8a7d43f2564de7d819fc28f) |
| BUG-08 | Minor | Mật khẩu demo bị in ra log container khi nạp dữ liệu mẫu | [50d456d](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/50d456d655e82e1e110d8b67bc70ff736a95813a) |
| BUG-09 | Major | Clone bằng Git for Windows thì container app không khởi động (script bị đổi sang CRLF) | [5d8f608](https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/5d8f6088f2417ea4a64839222264ac0cd167e204) |

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

## BUG-06 — Thư viện có lỗ hổng bảo mật đã công bố

1. **Mã và mức độ:** BUG-06 · MAJOR — 44 lỗ hổng đã công bố trong 11 gem (1 Critical, 5 High), trong đó có loại
   ứng dụng đang dùng tới: rack multipart DoS (High), Strong Parameters bypass (High), giả IP qua RemoteIp (High).
   Hệ thống vẫn chạy đúng chức năng và chưa thấy bị khai thác; lỗ hổng Critical nằm ở Active Storage phân tích
   ảnh – tính năng luồng L2 không dùng – nên xếp Major, không phải Critical.
2. **Phát hiện bởi:** checklist bảo mật mục 7 (OWASP A03) — `bin/bundler-audit check --update` trong
   `scripts/kiem-bao-mat.sh` báo `Vulnerabilities found!` (ảnh `docs/screenshots/BUG-06-truoc.png`).
3. **Triệu chứng:** bundler-audit liệt kê, ví dụ: rack 3.2.7 `GHSA-5v64-555j-wjxm` (High), rails-html-sanitizer 1.7.1
   `GHSA-cpgf-5mjf-73p7`, nokogiri 1.19.4 `GHSA-v995-44v6-5fqm`. Đối chiếu đủ với ruby-advisory-db (bản 09/11/2026):
   actionpack 7 · activestorage 7 · addressable 7 · loofah 6 · rack 4 · actionview 4 · nokogiri 3 · activesupport 2 ·
   rails-html-sanitizer 2 · actionmailbox 1 · crass 1 = 44 mã.
4. **Cách tái lập:** checkout commit trước `e7c4923` → `cd src && bin/bundler-audit check --update` → `Vulnerabilities found!`;
   luôn xảy ra (phụ thuộc phiên bản trong `Gemfile.lock`, không phụ thuộc dữ liệu).
5. **Nguyên nhân:** `Gemfile.lock` vẫn khóa các phiên bản lúc tạo dự án; các bản vá bảo mật phát hành sau đó
   (Rails 8.1.4.1, rack 3.2.8…) chưa được cập nhật vì trước đó chưa có bước kiểm lỗ hổng phụ thuộc.
6. **Cách sửa:** `bundle update --conservative` đúng các gem bị báo — chỉ đổi `src/Gemfile.lock`:
   Rails 8.1.4 → 8.1.4.1 (cả nhóm actionpack, actionview, activestorage, activesupport, actionmailbox…),
   rack 3.2.7 → 3.2.8, nokogiri 1.19.4 → 1.19.7, rails-html-sanitizer 1.7.1 → 1.7.2, loofah 2.25.2 → 2.25.3,
   crass 1.0.7 → 1.0.8, addressable 2.9.0 → 2.9.2. (Tiêu đề commit chỉ nêu ba gem; nội dung commit nâng đủ 11 gem trên.)
7. **Commit và xác nhận:** https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/e7c49235b1f9d6a09734586af0c617862c3495b7 · `bin/bundler-audit check` → `No vulnerabilities found`;
   `bin/importmap audit` → `No vulnerable packages found` (ảnh `sec-7.png`); `bin/rails test` → 131 runs, 0 failures;
   build lại Docker → db, app healthy; CI xanh.

## BUG-07 — Gửi JSON hỏng bị trả 500 thay vì 400

1. **Mã và mức độ:** BUG-07 · MINOR — lỗi phía người gửi bị coi là sự cố hệ thống: trả `500 LOI_HE_THONG` và ghi log
   mức ERROR (báo động giả cho người vận hành). Không lộ thông tin bên trong, chức năng chính không bị ảnh hưởng.
2. **Phát hiện bởi:** checklist bảo mật mục 5a (OWASP A10 – xử lý tình huống bất thường) — gửi thân JSON hỏng tới
   `POST /api/customers` (ảnh `docs/screenshots/BUG-07-truoc.png`).
3. **Triệu chứng:** `HTTP/1.1 500 Internal Server Error` ·
   `{"error":"LOI_HE_THONG", … "ma_tra_cuu":"4c57e01f-56c1-4a45-8ddf-7c1cc368cb3d"}`.
4. **Cách tái lập:** `curl -X POST http://localhost:3000/api/customers -H "Authorization: Bearer <token>"
   -H "Content-Type: application/json" -d '{"name":"A", phone'` → 500; luôn xảy ra.
5. **Nguyên nhân:** Rails ném `ActionDispatch::Http::Parameters::ParseError` khi đọc tham số; `Api::BaseController`
   chỉ có `rescue_from StandardError` chung nên lỗi rơi vào nhánh 500.
6. **Cách sửa:** thêm `rescue_from ActionDispatch::Http::Parameters::ParseError` trả `400 DU_LIEU_KHONG_HOP_LE`
   ("Nội dung gửi lên không phải JSON hợp lệ.") trong `src/app/controllers/api/base_controller.rb`; thêm test hồi quy
   "JSON hỏng: 400 …" vào `src/test/integration/api_crud_test.rb`.
7. **Commit và xác nhận:** https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/1ac9df33586f8236c8a7d43f2564de7d819fc28f · test mới PASS; chạy lại checklist mục 5 → `HTTP/1.1 400 Bad Request`,
   `DU_LIEU_KHONG_HOP_LE` (ảnh `sec-5.png`); `bin/rails test` → 131 runs, 0 failures.

## BUG-08 — Mật khẩu demo bị in ra log container

1. **Mã và mức độ:** BUG-08 · MINOR — mật khẩu của tài khoản demo (dữ liệu mẫu, đã ghi trong Deployment Guide) nằm
   trong log container, trái nguyên tắc "log không ghi mật khẩu" (OWASP A09). Không có dữ liệu thật bị lộ.
2. **Phát hiện bởi:** checklist bảo mật mục 6 — `docker compose logs app | grep -n 'Mekong@2026'`
   (ảnh `docs/screenshots/BUG-08-truoc.png`).
3. **Triệu chứng:** 2 dòng log: `Nhân viên tiếp nhận: quoc@mekong.vn / Mekong@2026 · lấy token qua POST /api/session`
   và dòng tương tự cho `phu@mekong.vn`.
4. **Cách tái lập:** `docker compose down -v && docker compose up -d --build` → `docker compose logs app | grep Mekong@2026`
   → 2 dòng; luôn xảy ra ở lần khởi động đầu (lúc seed chạy).
5. **Nguyên nhân:** `db/seeds.rb` in tài khoản demo kèm mật khẩu ra màn hình; `bin/docker-entrypoint` chạy seed khi
   khởi động nên đầu ra nằm lại trong log container. Lần sửa trước (`967bf5a`) mới bỏ token, còn sót mật khẩu.
6. **Cách sửa:** `src/db/seeds.rb` chỉ in mật khẩu và token ở môi trường development; môi trường khác chỉ in email kèm
   chỉ dẫn tới Deployment Guide. Thêm test `src/test/integration/seeds_output_test.rb` chạy seed và kiểm tra đầu ra
   không chứa mật khẩu, không chứa token.
7. **Commit và xác nhận:** https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/50d456d655e82e1e110d8b67bc70ff736a95813a · test mới PASS; `down -v` → `up` → chạy lại checklist mục 6 → `(không có)`
   (ảnh `sec-6.png`); `bin/rails test` → 131 runs, 0 failures.

## BUG-09 — Clone trên Windows thì container app không khởi động

1. **Mã và mức độ:** BUG-09 · MAJOR — nếu repo được clone bằng Git for Windows (mặc định `core.autocrlf=true`), container
   `app` dừng ngay khi khởi động: hệ thống không lên, phép thử máy trắng (C1) thất bại. Có cách làm khác (clone trong
   WSL / Linux / macOS, hoặc tắt `core.autocrlf`) nên xếp Major.
2. **Phát hiện bởi:** rà soát phép thử máy trắng trên môi trường khác — giả lập máy Windows bằng
   `git clone -c core.autocrlf=true --branch v1.0 …` rồi chạy thử `src/bin/docker-entrypoint`
   (ảnh `docs/screenshots/BUG-09-truoc.png`).
3. **Triệu chứng:** `file src/bin/docker-entrypoint` → `… with CRLF line terminators`; chạy script → `/bin/bash: -: invalid
   option`. Đây chính là ENTRYPOINT của image nên container `app` thoát, không bao giờ healthy.
4. **Cách tái lập:** `git clone -q -c core.autocrlf=true --branch v1.0 https://github.com/anquoc2024/cdtn1-thaianquoc-2.git x`
   (tag cũ, trước `5d8f608`) → `x/src/bin/docker-entrypoint echo ok` → `invalid option`; luôn xảy ra khi Git đổi xuống dòng.
5. **Nguyên nhân:** repo không có `.gitattributes`, nên Git for Windows đổi LF → CRLF khi checkout. Dòng shebang thành
   `#!/bin/bash -e\r`; kernel truyền tham số `-e\r` cho bash và bash từ chối tùy chọn lạ. Mọi lần thử trước đều clone
   trong WSL (giữ LF) nên không lộ lỗi.
6. **Cách sửa:** thêm `.gitattributes` ở gốc repo: `* text=auto eol=lf` (checkout luôn giữ LF, bất kể `core.autocrlf`);
   CSV, PNG, JPG, PDF, DOCX, drawio giữ nguyên từng byte. Deployment Guide thêm một dòng Troubleshooting.
7. **Commit và xác nhận:** https://github.com/anquoc2024/cdtn1-thaianquoc-2/commit/5d8f6088f2417ea4a64839222264ac0cd167e204 · clone lại với `core.autocrlf=true` → `file` không còn `CRLF`, chạy script in `ok`
   (ảnh `docs/screenshots/BUG-09-sau.png`); phép thử máy trắng theo tag `v1.0` gắn lại sau bản sửa vẫn đạt.
