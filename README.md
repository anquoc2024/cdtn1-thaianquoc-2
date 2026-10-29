# Smart CRM – Mekong Mobile · Luồng L2: Tiếp nhận và phân loại yêu cầu bảo hành

Đồ án môn **Chuyên đề tốt nghiệp 1** – Khoa CNTT, Trường Đại học Văn Lang · Track **SE**

| | |
|---|---|
| Sinh viên | Thái An Quốc – 2374802012635 |
| Lớp | 261_71ITGR40203_06 |
| Giảng viên | TS. Nguyễn Trí Hải |
| Repo | https://github.com/anquoc2024/cdtn1-thaianquoc-2 |
| Phiên bản nộp BT2 | tag [`v0.2`](https://github.com/anquoc2024/cdtn1-thaianquoc-2/releases/tag/v0.2) · báo cáo trong `BT2_2374802012635_ThaiAnQuoc/` · ảnh minh chứng trong `docs/screenshots/` |

## 1. Giới thiệu

Hệ thống web giúp **nhân viên tiếp nhận** của trung tâm bảo hành tra cứu khách hàng (theo SĐT)
ghi nhận thiết bị và mô tả lỗi, phân loại nhóm sự cố, chọn mức ưu tiên rồi tạo yêu cầu bảo hành; hệ thống tự sinh mã
`BH-YYYY-NNNNNN` và tự tính hạn cam kết theo SLA. Nhân viên tiếp nhận cập nhật trạng thái yêu cầu
(Mới tiếp nhận → Đang xử lý → Hoàn tất, hoặc Hủy kèm lý do) và mọi lần đổi đều được ghi lịch sử.
**Quản lý trung tâm** chỉ xem: danh sách, thống kê có mốc so sánh và phiếu tiếp nhận, phát hiện yêu cầu quá hạn.
Ba màn hình lấy dữ liệu qua **API JSON** (`/api/...`) bằng một lớp client riêng; cùng API đó dùng được bằng curl / Postman với token.

| Màn hình | Chức năng | Use Case |
|---|---|---|
| Đăng nhập | Email + mật khẩu, phân quyền theo vai trò | NFR05 |
| 1 – Tra cứu khách hàng | Tìm theo SĐT / mã KH / họ tên (có dấu hoặc không dấu), báo không tìm thấy | UC01, UC08 |
| 2 – Tạo yêu cầu bảo hành | Thiết bị, mô tả lỗi, nhóm sự cố, mức ưu tiên, sửa họ tên khách hàng | UC02–UC06 |
| Phiếu tiếp nhận | Xem chi tiết, đổi trạng thái, hủy kèm lý do, lịch sử trạng thái | UC09, UC10 |
| 3 – Danh sách yêu cầu | Thống kê có mốc so sánh, tìm kiếm, lọc, sắp xếp, phân trang, đánh dấu quá hạn | UC07 |

## 2. Yêu cầu môi trường

| Thành phần | Phiên bản đã dùng | Kiểm tra bằng |
|---|---|---|
| Hệ điều hành | Ubuntu 26.04 trên WSL 2 (Windows 11) – Ubuntu 22.04+ cũng chạy được | `lsb_release -a` |
| Ruby | **4.0.5** (cài bằng `mise`, khai báo trong `src/.ruby-version`) | `ruby -v` |
| Bundler | đi kèm Ruby 4.0.5 | `bundle -v` |
| Ruby on Rails | **8.1** (khóa trong `src/Gemfile.lock`) | `cd src && bin/rails -v` |
| PostgreSQL | **18** (cần extension `unaccent` – có sẵn trong gói `postgresql`) | `psql --version` |
| Thư viện hệ thống | `libpq-dev` (biên dịch gem `pg`), `build-essential` | `dpkg -l libpq-dev` |
| Trình duyệt | Chrome / Edge / Firefox bản mới (Rails 8 chặn trình duyệt quá cũ) | — |
| Cổng | **3000** (web + API), **5432** (PostgreSQL) phải còn trống | `ss -ltn` |

- **Không cần Node.js**: giao diện dùng Importmap + Hotwire (Turbo, Stimulus) có sẵn trong Rails 8.
- **Tệp khóa phiên bản**: `src/Gemfile.lock` (đã commit) – `bundle install` cài đúng phiên bản trong tệp này.
- **Biến môi trường**: liệt kê trong `.env.example`. Ở môi trường phát triển có thể không đặt biến nào:
  Rails kết nối PostgreSQL qua socket với user trùng tên user Ubuntu (bước 3.2).

| Biến | Ý nghĩa | Giá trị mẫu | Bắt buộc |
|---|---|---|---|
| `DATABASE_URL` | Chuỗi kết nối PostgreSQL, ghi đè `src/config/database.yml` | `postgres://quoc:mat_khau@localhost:5432/src_development` | Không (dev) |
| `PORT` | Cổng chạy web | `3000` | Không |
| `RAILS_MAX_THREADS` | Số luồng Puma = số kết nối pool CSDL (NFR03) | `5` | Không |
| `RAILS_ENV` | `development` / `test` / `production` | `development` | Không |
| `RAILS_MASTER_KEY` | Khóa giải mã `credentials` – chỉ cần khi chạy production | *(nội dung `src/config/master.key`)* | Chỉ production |

`.env` và `src/config/master.key` nằm trong `.gitignore`, **không** có trong repo.

## 3. Cài đặt và chạy

Mỗi bước là một lệnh, chạy theo đúng thứ tự, bắt đầu từ thư mục gốc của repo.

### 3.1. Lấy mã nguồn
```bash
git clone https://github.com/anquoc2024/cdtn1-thaianquoc-2.git
cd cdtn1-thaianquoc-2
```

### 3.2. Cài PostgreSQL và thư viện (làm một lần trên máy)
```bash
sudo apt install -y postgresql libpq-dev build-essential
sudo service postgresql start                  # WSL: chạy lại mỗi khi mở máy
sudo -u postgres createuser -s "$USER"         # user CSDL trùng tên user Ubuntu
```

### 3.3. Biến môi trường (tùy chọn ở môi trường phát triển)
```bash
cp .env.example .env                           # sửa giá trị nếu không dùng kết nối socket mặc định
set -a; source .env; set +a                    # chỉ cần khi đã sửa .env
```

### 3.4. Cài thư viện Ruby
```bash
cd src
bundle install
```

### 3.5. Tạo CSDL, tạo bảng và nạp dữ liệu mẫu
```bash
bin/rails db:prepare                           # tạo CSDL + chạy migration + chạy db/seeds.rb nếu CSDL mới
bin/rails db:seed                              # chạy lại an toàn – không nhân đôi dữ liệu
```

### 3.6. Chạy hệ thống
```bash
bin/rails server                               # mở http://localhost:3000
```

### Dữ liệu mẫu sau khi seed

| Dữ liệu | Số lượng | Nguồn |
|---|---|---|
| Tài khoản | 2 | `src/db/seeds.rb` |
| Mức ưu tiên | 4 (Thấp 72h · Trung bình 48h · Cao 24h · Khẩn cấp 8h) | `src/db/seeds.rb` |
| Khách hàng (bộ 300 dòng) | 300 dòng đọc → **279** khách (loại 20 dòng thiếu SĐT, gộp 1 SĐT trùng), mã `KH-100001`… | `data/mau/customers_mau.csv` |
| Nhóm sự cố | 6 (Màn hình, Pin, Sạc, Phần mềm, Nước vào, Khác) | `data/mau/issue_categories.csv` |
| Khách hàng (bộ L2) | 31, mã `KH-(100000 + customer_id)` | `data/mau/customers.csv` |
| Thiết bị | 38 dòng → **31** (loại 7 dòng thiếu ngày mua – BR02); hãng / model / loại lấy từ `products.csv` | `data/mau/devices.csv`, `products.csv` |
| Yêu cầu bảo hành | **30**, trạng thái Mới tiếp nhận; giờ tạo = lúc seed − `hours_ago`, nên khoảng 18 yêu cầu đã quá hạn | `data/mau/tickets.csv` |

Bộ L2 nạp bằng `L2DatasetImporter` (TD-28); `service_centers.csv` không nạp vì hệ thống phục vụ một trung tâm.
Dòng bị loại kèm lý do ghi ở `src/tmp/import/l2_reject.csv`. Nạp lại riêng bộ L2: `bin/rails import:l2` (chạy lại không nhân đôi).

**Tài khoản demo** (chỉ dùng cho môi trường phát triển / chấm bài):

| Vai trò | Email | Mật khẩu | Được làm gì |
|---|---|---|---|
| Nhân viên tiếp nhận | `quoc@mekong.vn` | `Mekong@2026` | Tra cứu, tạo yêu cầu, đổi trạng thái, xem danh sách, CRUD khách hàng và nhóm sự cố |
| Quản lý trung tâm | `phu@mekong.vn` | `Mekong@2026` | Chỉ xem: danh sách, thống kê, phiếu tiếp nhận |

**Nạp toàn bộ dữ liệu khách hàng của giảng viên** (tệp lớn, không commit): chép tệp vào `data/customer.csv` rồi
```bash
bin/rails "import:customers[../data/customer.csv]"   # ~67.000 dòng → ~51.000 khách, chạy lại không nhân đôi
```
Các dòng bị loại kèm lý do được ghi vào `src/tmp/import/customers_reject.csv`.

## 4. Kiểm thử

Chạy **toàn bộ** bộ kiểm thử bằng **một lệnh** (trong thư mục `src`):
```bash
bin/rails test
```
Kết quả đúng: dòng cuối có `115 runs, … 0 failures, 0 errors` (ảnh: `docs/screenshots/16-bin-rails-test-pass.png`). Test tự dựng dữ liệu cần dùng, không phụ thuộc dữ liệu có sẵn trên máy.

| Thư mục | Kiểm tra gì |
|---|---|
| `src/test/models/` | Tài khoản, mật khẩu, bảng phân quyền |
| `src/test/services/` | Quy tắc nghiệp vụ ở lớp service: sinh mã, tính hạn SLA, chuyển trạng thái, CRUD khách hàng / nhóm sự cố, làm sạch dữ liệu CSV |
| `src/test/integration/` | Giao diện 3 màn hình, đăng nhập, phân quyền, API (mã HTTP, định dạng lỗi, token), xử lý lỗi hệ thống 500 / 503 |
| `src/test/middleware/` | Lỗi mất CSDL xảy ra trước controller vẫn trả 503 có mã tra cứu |

Ba loại kiểm thử theo yêu cầu BT2 (ví dụ):
- **Luồng đúng:** tạo yêu cầu hợp lệ → 201, mã `BH-YYYY-NNNNNN`, hạn = lúc tạo + số giờ SLA.
- **Giá trị biên:** SĐT đúng 10 chữ số được nhận, 9 chữ số bị từ chối; họ tên 100 ký tự được nhận, 101 ký tự bị từ chối.
- **Dữ liệu sai:** thiếu trường bắt buộc → 400 `DU_LIEU_KHONG_HOP_LE` kèm tên trường; serial thuộc khách khác → 409.

Chạy riêng một tệp: `bin/rails test test/services/customer_service_test.rb`.

## 5. Cách kiểm tra hệ thống đã chạy đúng

Với server đang chạy ở một tab khác:

| # | Lệnh / thao tác | Kết quả mong đợi |
|---|---|---|
| 1 | `curl -s localhost:3000/api/health` | `{"status":"ok","db":"ok"}` |
| 2 | Mở http://localhost:3000 | Chuyển tới trang **Đăng nhập** |
| 3 | Đăng nhập `quoc@mekong.vn`, tra cứu `0793 573 965` | Thấy khách **Lý Văn Như – KH-100561**, có 1 yêu cầu bảo hành |
| 4 | Đăng nhập `phu@mekong.vn` | Mở **Danh sách yêu cầu**; mục Tra cứu và Tạo yêu cầu có ổ khóa |
| 5 | Lấy token: `curl -s -X POST localhost:3000/api/session -H "Content-Type: application/json" -d '{"email_address":"phu@mekong.vn","password":"Mekong@2026"}'` | `200` kèm `"token": "..."` |
| 6 | `curl -s localhost:3000/api/warranty_requests -H "Authorization: Bearer <token>"` | Danh sách JSON có `data` và `meta.tong_so` ≥ 8 |
| 7 | `curl -s -i localhost:3000/api/warranty_requests` (không token) | `401` với `"error":"CHUA_XAC_THUC"` |
| 8 | `bash scripts/kiem-tra-api.sh` (ở gốc repo) | Dòng cuối: `Tổng: 40 ca · 40 PASS · 0 FAIL` |
| 9 | `sudo service postgresql stop` rồi F5 trang web và gọi `curl -i localhost:3000/api/health` | Trang **"Hệ thống tạm thời không truy cập được dữ liệu"** và API `503`, cả hai có **mã tra cứu**; bật lại: `sudo service postgresql start` |

### API JSON

Xác thực bằng header `Authorization: Bearer <token>` (lấy ở `POST /api/session`). Lỗi luôn có dạng
`{"error": "MA_LOI", "message": "...", "chi_tiet": {...}}`. Chi tiết: `docs/api-docs.md`.

| Phương thức | Đường dẫn | Mô tả | Quyền |
|---|---|---|---|
| GET | `/api/health` | Dịch vụ và CSDL còn hoạt động | Không cần token |
| POST / DELETE | `/api/session` | Đăng nhập lấy token / đăng xuất thu hồi token | — |
| GET | `/api/customers?q=&page=` | Danh sách / tra cứu khách hàng | Nhân viên tiếp nhận |
| GET · POST · PATCH · DELETE | `/api/customers[/:id]` | CRUD khách hàng (không xóa khách đã có thiết bị – BR13) | Nhân viên tiếp nhận |
| GET | `/api/issue_categories[/:id]` | Danh sách / chi tiết nhóm sự cố | Cả hai vai trò |
| POST · PATCH · DELETE | `/api/issue_categories[/:id]` | CRUD nhóm sự cố (không xóa nhóm đang dùng – BR14) | Nhân viên tiếp nhận |
| GET | `/api/priorities` | Danh mục mức ưu tiên | Cả hai vai trò |
| GET | `/api/stats` | Thống kê có mốc so sánh | Cả hai vai trò |
| GET | `/api/warranty_requests` | Danh sách, lọc, sắp xếp, phân trang | Cả hai vai trò |
| GET | `/api/warranty_requests/:id` | Chi tiết + lịch sử trạng thái | Cả hai vai trò |
| POST | `/api/warranty_requests` | Tạo yêu cầu bảo hành | Nhân viên tiếp nhận |
| PATCH | `/api/warranty_requests/:id/status` | Đổi trạng thái / hủy kèm lý do | Nhân viên tiếp nhận |

### Kiểm tra toàn bộ API

| Cách | Lệnh / thao tác | Kết quả mong đợi |
|---|---|---|
| Script curl (40 ca) | `bash scripts/kiem-tra-api.sh` (chạy ở gốc repo) | In PASS / FAIL từng ca; dòng cuối `40 PASS · 0 FAIL` |
| Postman (40 request) | Import `docs/postman/SmartCRM_API_BT2.postman_collection.json` → chuột phải collection → **Run collection** | Toàn bộ test **Passed** (thư mục `00` tự đăng nhập và lưu token) |
| Gọi thử từng request | `bash docs/scripts/goi-api.sh` | Ghi request / response thật vào `docs/api-ket-qua-thuc-te.md` |

Thư mục `08` của collection và cuối script sẽ **đăng xuất**, làm token cũ hết hiệu lực – lấy token mới bằng `POST /api/session`.

### Xử lý lỗi và log (TD-27)

| Tình huống | API | Trang web |
|---|---|---|
| Lỗi nghiệp vụ / dữ liệu sai | `400 / 404 / 409 / 422` có mã lỗi riêng; log mức INFO | Thông báo ngay tại ô nhập |
| Mất kết nối CSDL | `503 CSDL_KHONG_KHA_DUNG` + header `Retry-After: 30` | Trang 503 thân thiện có nút **Thử lại** |
| Lỗi không lường trước | `500 LOI_HE_THONG` | Trang 500 (production, hoặc chạy `FRIENDLY_ERRORS=1 bin/rails server`) |

- Mọi phản hồi 5xx kèm **mã tra cứu** (= `request_id`, cũng có trong header `X-Request-Id`); người dùng không thấy tên lớp lỗi, câu SQL hay ngăn xếp.
- Mọi dòng log gắn mã tra cứu; mỗi sự cố ghi **ERROR đúng một lần**. Tìm đúng request: `grep "<mã tra cứu>" src/log/development.log`.
- Log che mật khẩu, token, email, SĐT, địa chỉ và từ khóa tra cứu (`src/config/initializers/filter_parameter_logging.rb`).

### Ảnh chụp minh chứng

Ảnh chụp thật khi chạy hệ thống nằm trong [`docs/screenshots/`](docs/screenshots/) (28 ảnh, có mục lục):
API bằng curl / Postman, kết quả kiểm thử, lỗi 503 khi tắt CSDL, và 3 trạng thái của từng màn hình.

## 6. Trạng thái hiện tại (Bài tập 2)

- [x] Đăng nhập email + mật khẩu (bcrypt), phân quyền theo User Story: Quản lý chỉ xem (TD-24)
- [x] Migration dựng CSDL từ trạng thái trống (8 bảng) + dữ liệu mẫu chạy lại không nhân đôi
- [x] Nạp khách hàng từ bộ dữ liệu của giảng viên: làm sạch SĐT / họ tên, gộp trùng, ghi dòng bị loại (TD-23)
- [x] CRUD đủ 4 thao tác cho **Khách hàng** và **Nhóm sự cố**; yêu cầu bảo hành: tạo, xem, đổi trạng thái, hủy (TD-25)
- [x] Quy tắc nghiệp vụ: sinh mã duy nhất (BR05, BR12), hạn SLA (BR06), chuyển trạng thái đúng thứ tự + lịch sử (BR08, BR09), một serial chỉ thuộc một khách (BR11), không xóa dữ liệu đang được dùng (BR13, BR14)
- [x] Tách lớp: controller (HTTP) → service (nghiệp vụ, không có dấu vết HTTP) → model (truy cập dữ liệu)
- [x] 3 màn hình lấy dữ liệu qua API bằng `api/client.js`, đủ 3 trạng thái đang tải · rỗng · lỗi có nút Thử lại; thống kê có mốc so sánh (TD-26)
- [x] Bộ kiểm thử đủ 3 loại (luồng đúng · giá trị biên · dữ liệu sai), chạy bằng `bin/rails test`
- [x] Xử lý lỗi xuyên lớp theo Buổi 11: mã tra cứu cho lỗi 500, trả 503 khi mất CSDL, che dữ liệu nhạy cảm trong log (TD-27)
- [x] Bộ kiểm tra toàn bộ API: script curl `scripts/kiem-tra-api.sh` và Postman collection (40 ca)
- [x] Báo cáo BT2 (`BT2_2374802012635_ThaiAnQuoc/`), ảnh minh chứng (`docs/screenshots/`) và tag `v0.2`
- [ ] Đóng gói Docker + docker-compose, chạy bằng ≤ 2 lệnh (Bài tập 3)
- [ ] Test plan, test report, Bug Log ≥ 3 lỗi; tài liệu triển khai và API bằng tiếng Anh; checklist bảo mật (Bài tập 3)

**Hạn chế đã biết:** API token không tự hết hạn (chỉ đổi khi đăng xuất qua `DELETE /api/session`);
giao diện không có màn hình riêng cho CRUD khách hàng / nhóm sự cố (thao tác qua API).

## 7. Cấu trúc thư mục

`src/app/` ánh xạ với các lớp trong sơ đồ kiến trúc (`docs/architecture.drawio`):

```
cdtn1-thaianquoc-2/
├── src/                          Ứng dụng Rails
│   ├── app/
│   │   ├── controllers/          LỚP ROUTES / CONTROLLER – nhận HTTP, gọi service, trả HTML / JSON
│   │   │   ├── concerns/         Authentication (đăng nhập), Authorization (phân quyền), SystemErrorHandling (lỗi 500 / 503)
│   │   │   ├── api/              API JSON + crud_responses.rb (nơi duy nhất ánh xạ lỗi nghiệp vụ → mã HTTP)
│   │   │   └── manager/          Màn hình 3
│   │   ├── services/             LỚP NGHIỆP VỤ – quy tắc BR, KHÔNG có params / render / mã HTTP
│   │   ├── forms/                Kiểm tra dữ liệu nhập form nhiều bảng (WarrantyRequestForm)
│   │   ├── queries/              Truy vấn danh sách, thống kê (UC07)
│   │   ├── models/               LỚP DỮ LIỆU – ActiveRecord (vai trò repository) + ràng buộc
│   │   ├── serializers/          Định dạng JSON trả về
│   │   ├── javascript/api/       client.js – lớp DUY NHẤT gọi API từ giao diện; ui.js – 3 trạng thái
│   │   ├── javascript/controllers/  Stimulus cho 3 màn hình
│   │   └── views/, helpers/, assets/  Giao diện (views/errors + layouts/error: trang lỗi không gọi CSDL)
│   ├── db/migrate/               Migration (dựng CSDL từ trống)
│   ├── db/seeds.rb               Dữ liệu mẫu
│   ├── lib/tasks/import.rake     Lệnh nạp khách hàng từ CSV
│   ├── lib/middleware/           Lưới an toàn trả 503 khi mất CSDL trước controller
│   ├── test/                     Bộ kiểm thử
│   └── Gemfile.lock              Tệp khóa phiên bản
├── BT1_2374802012635_ThaiAnQuoc/  Báo cáo Bài tập 1 (PDF, bản chỉnh sửa v2)
├── BT2_2374802012635_ThaiAnQuoc/  Báo cáo Bài tập 2 (PDF + Word)
├── data/mau/customers_mau.csv    Bộ dữ liệu mẫu 300 dòng (tệp đầy đủ không commit)
├── db/schema.sql                 DDL đọc được, đối chiếu thiết kế
├── docs/                         Tài liệu · postman/ (collection kiểm thử API) · screenshots/ (ảnh minh chứng)
├── scripts/kiem-tra-api.sh       Kiểm tra toàn bộ API bằng curl (40 ca)
├── .env.example                  Danh sách biến môi trường
└── README.md
```

## 8. Tài liệu

| Tệp | Nội dung |
|---|---|
| `docs/srs.md` | Đặc tả yêu cầu (SRS) |
| `docs/thay-doi-thiet-ke.md` | Nhật ký thay đổi thiết kế so với BT1 (TD-01 → TD-28) |
| `docs/api-docs.md` | Tài liệu API JSON |
| `docs/api-ket-qua-thuc-te.md` | Request / response thật, sinh bởi `docs/scripts/goi-api.sh` |
| `docs/postman/SmartCRM_API_BT2.postman_collection.json` | Postman collection 40 request có test tự kiểm tra |
| `docs/ai-disclosure.md` | Khai báo sử dụng công cụ AI |
| `docs/screenshots/` | 28 ảnh chụp thật: API, kiểm thử, lỗi 503, 3 màn hình (mục lục trong `README.md` của thư mục) |
| `docs/*.drawio` | Sơ đồ Use Case, ERD, kiến trúc, wireframe |
| `docs/wireframe-html/` | Bản HTML/CSS dựng từ wireframe |
| `BT1_…/`, `BT2_…/` | Báo cáo Bài tập 1 và Bài tập 2 |

