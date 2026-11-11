# Smart CRM – Mekong Mobile · Luồng L2: Tiếp nhận và phân loại yêu cầu bảo hành

[![CI](https://github.com/anquoc2024/cdtn1-thaianquoc-2/actions/workflows/ci.yml/badge.svg)](https://github.com/anquoc2024/cdtn1-thaianquoc-2/actions/workflows/ci.yml)

Đồ án môn **Chuyên đề tốt nghiệp 1** – Khoa CNTT, Trường Đại học Văn Lang · Track **SE**

| | |
|---|---|
| Sinh viên | Thái An Quốc – 2374802012635 |
| Lớp | 261_71ITGR40203_06 |
| Giảng viên | TS. Nguyễn Trí Hải |
| Repo | https://github.com/anquoc2024/cdtn1-thaianquoc-2 |
| Phiên bản nộp BT2 | tag [`v0.2`](https://github.com/anquoc2024/cdtn1-thaianquoc-2/releases/tag/v0.2) · báo cáo trong `BT2_2374802012635_ThaiAnQuoc/` · ảnh minh chứng trong `docs/screenshots/` |
| Phiên bản nộp BT3 | tag [`v1.0`](https://github.com/anquoc2024/cdtn1-thaianquoc-2/releases/tag/v1.0) (commit `22d2d94`) · chạy bằng Docker: [`docs/deployment-guide.md`](docs/deployment-guide.md) |
| Bản deploy thử (BT3) | https://smartcrm-app.onrender.com · đăng nhập bằng tài khoản demo ở mục 4 của [`docs/deployment-guide.md`](docs/deployment-guide.md) · ảnh minh chứng: `docs/screenshots/deploy-render.png` |

**Mục lục:** [1. Giới thiệu](#1-giới-thiệu) · [2. Yêu cầu môi trường](#2-yêu-cầu-môi-trường) ·
[3. Cài đặt và chạy](#3-cài-đặt-và-chạy) · [4. Kiểm thử](#4-kiểm-thử) ·
[5. Cách kiểm tra hệ thống đã chạy đúng](#5-cách-kiểm-tra-hệ-thống-đã-chạy-đúng) ·
[6. Bảo mật và Bug Log](#6-bảo-mật-và-bug-log-bài-tập-3) · [7. Bản deploy thử](#7-bản-deploy-thử) ·
[8. Trạng thái hiện tại](#8-trạng-thái-hiện-tại-bài-tập-3) · [9. Cấu trúc thư mục](#9-cấu-trúc-thư-mục) · [10. Tài liệu](#10-tài-liệu)

## 1. Giới thiệu

Hệ thống web giúp **nhân viên tiếp nhận** của trung tâm bảo hành tra cứu khách hàng (theo SĐT),
ghi nhận thiết bị và mô tả lỗi, phân loại nhóm sự cố, chọn mức ưu tiên rồi tạo yêu cầu bảo hành; hệ thống tự sinh mã
`BH-YYYY-NNNNNN` và tự tính hạn cam kết theo SLA. Nhân viên tiếp nhận cập nhật trạng thái yêu cầu
(Mới tiếp nhận → Đang xử lý → Hoàn tất, hoặc Hủy kèm lý do) và mọi lần đổi đều được ghi lịch sử.
Nhân viên tiếp nhận còn **sửa và xóa** yêu cầu (TD-29). **Quản lý trung tâm** tra cứu khách hàng, tạo yêu cầu và xem danh sách, thống kê có mốc so sánh, phiếu tiếp nhận để phát hiện yêu cầu quá hạn; không đổi trạng thái, không sửa / xóa.
Ba màn hình lấy dữ liệu qua **API JSON** (`/api/...`) bằng một lớp client riêng; cùng API đó dùng được bằng curl / Postman với token.

| Màn hình | Chức năng | Use Case |
|---|---|---|
| Đăng nhập | Email + mật khẩu, phân quyền theo vai trò | NFR05 |
| 1 – Tra cứu khách hàng | Tìm theo SĐT / mã KH / họ tên (có dấu hoặc không dấu), báo không tìm thấy | UC01, UC08 |
| 2 – Tạo yêu cầu bảo hành | Thiết bị, mô tả lỗi, nhóm sự cố, mức ưu tiên, sửa họ tên khách hàng | UC02–UC06 |
| Phiếu tiếp nhận | Xem chi tiết, đổi trạng thái, hủy kèm lý do, lịch sử trạng thái | UC09, UC10 |
| 3 – Danh sách yêu cầu | Thống kê có mốc so sánh, tìm kiếm, lọc, sắp xếp, phân trang, đánh dấu quá hạn | UC07 |

## 2. Yêu cầu môi trường

Có hai cách chạy. **Cách 1 – Docker** (khuyên dùng, dùng để chấm BT3) chỉ cần Docker và Git.
**Cách 2 – chạy trực tiếp** dùng khi phát triển.

### 2.1. Chạy bằng Docker

| Thành phần | Phiên bản | Kiểm tra bằng |
|---|---|---|
| Hệ điều hành | Linux, macOS, hoặc Windows 10/11 có WSL 2 (đã thử trên Windows 11 + WSL 2 Ubuntu, Docker Engine cài trong Ubuntu) | — |
| Docker Engine | **25+** (healthcheck dùng `start_interval`) | `docker version` |
| Docker Compose | plugin **v2.20+** | `docker compose version` |
| Git | bản bất kỳ | `git --version` |
| Ổ đĩa / cổng | khoảng 3 GB trống · cổng **3000** còn trống (đổi được bằng `APP_PORT`) | `ss -ltn` |

Không cần cài Ruby, Node.js hay PostgreSQL trên máy. Gói gồm 2 container: `app` (Rails 8.1 production, Ruby 4.0.5, Puma)
và `db` (PostgreSQL 18, chỉ nằm trong mạng nội bộ của Compose, không mở cổng ra ngoài).

Biến môi trường của gói Docker nằm trong `.env.example` (sao chép thành `.env`):

| Biến | Ý nghĩa | Giá trị mẫu |
|---|---|---|
| `APP_PORT` | Cổng mở ra máy: `http://localhost:APP_PORT` | `3000` |
| `DB_NAME` | Tên CSDL chính (thêm `_cache`, `_queue`, `_cable` cho Solid Cache / Queue / Cable) | `smartcrm` |
| `DB_USER` · `DB_PASSWORD` | Tài khoản PostgreSQL do dịch vụ `db` tạo ở lần chạy đầu | `smartcrm` · `doi-mat-khau-nay` |
| `SECRET_KEY_BASE` | Khóa ký cookie / phiên đăng nhập (production) – khóa thật sinh bằng `openssl rand -hex 64` | *(chuỗi mẫu)* |
| `RAILS_MAX_THREADS` | Số luồng Puma = số kết nối CSDL tối đa (NFR03) | `5` |
| `RAILS_LOG_LEVEL` | Mức ghi log | `info` |

Giá trị trong `.env.example` chỉ là mẫu cho máy thử; triển khai thật phải đổi mọi giá trị.

### 2.2. Chạy trực tiếp trên máy (môi trường phát triển)

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
- **Biến môi trường**: ở môi trường phát triển có thể không đặt biến nào – Rails kết nối PostgreSQL qua socket
  với user trùng tên user Ubuntu (bước 3.2.2).

| Biến | Ý nghĩa | Giá trị mẫu | Bắt buộc |
|---|---|---|---|
| `DATABASE_URL` | Chuỗi kết nối PostgreSQL, ghi đè `src/config/database.yml` | `postgres://quoc:mat_khau@localhost:5432/src_development` | Không (dev) |
| `PORT` | Cổng chạy web | `3000` | Không |
| `RAILS_MAX_THREADS` | Số luồng Puma = số kết nối pool CSDL (NFR03) | `5` | Không |
| `RAILS_ENV` | `development` / `test` / `production` | `development` | Không |
| `RAILS_MASTER_KEY` | Khóa giải mã `credentials` – chỉ cần khi chạy production ngoài Docker | *(nội dung `src/config/master.key`)* | Chỉ production |

`.env` và `src/config/master.key` nằm trong `.gitignore`, **không** có trong repo.

## 3. Cài đặt và chạy

### 3.1. Cách 1 – Docker (Bài tập 3): hai lệnh sau khi clone

```bash
git clone --branch v1.0 https://github.com/anquoc2024/cdtn1-thaianquoc-2.git && cd cdtn1-thaianquoc-2
cp .env.example .env
docker compose up -d --build
```

Lần chạy đầu build image (vài phút), tự tạo CSDL và nạp dữ liệu mẫu (`bin/docker-entrypoint` chạy `bin/rails db:prepare`).
Đợi khoảng 30 giây sau khi lệnh chạy xong, rồi mở http://localhost:3000 và đăng nhập `quoc@mekong.vn` / `Mekong@2026`.

| Việc | Lệnh |
|---|---|
| Xem trạng thái – cả `db` và `app` phải `healthy` | `docker compose ps` |
| Kiểm tra sức khỏe | `curl http://localhost:3000/api/health` → `{"status":"ok","db":"ok"}` |
| Đếm dữ liệu mẫu | `docker compose exec app bin/rails runner 'puts "users=#{User.count} customers=#{Customer.count} devices=#{Device.count} requests=#{WarrantyRequest.count}"'` → `users=2 customers=310 devices=31 requests=30` |
| Chạy toàn bộ test trong container | `docker compose exec -e RAILS_ENV=test app bin/rails db:test:prepare test` |
| Nạp lại dữ liệu L2 (không nhân đôi) | `docker compose exec app bin/rails import:l2` → mọi mục "mới 0" |
| Xem log | `docker compose logs app --tail 50` |
| Dừng (giữ dữ liệu) · xóa sạch cả dữ liệu | `docker compose down` · `docker compose down -v` |

Hướng dẫn đầy đủ (tiếng Anh: yêu cầu, biến môi trường, dữ liệu mẫu, 7 bước kiểm tra, xử lý sự cố):
**[`docs/deployment-guide.md`](docs/deployment-guide.md)**.
Clone trên Windows bằng Git for Windows vẫn chạy được: `.gitattributes` ép các script dùng xuống dòng LF (BUG-09).

### 3.2. Cách 2 – Chạy trực tiếp trên máy (môi trường phát triển)

Mỗi bước là một lệnh, chạy theo đúng thứ tự, bắt đầu từ thư mục gốc của repo.

#### 3.2.1. Lấy mã nguồn
```bash
git clone https://github.com/anquoc2024/cdtn1-thaianquoc-2.git
cd cdtn1-thaianquoc-2
```

#### 3.2.2. Cài PostgreSQL và thư viện (làm một lần trên máy)
```bash
sudo apt install -y postgresql libpq-dev build-essential
sudo service postgresql start                  # WSL: chạy lại mỗi khi mở máy
sudo -u postgres createuser -s "$USER"         # user CSDL trùng tên user Ubuntu
```

#### 3.2.3. Biến môi trường (không cần ở môi trường phát triển)
Chạy trực tiếp trên máy thì **không** cần tệp `.env`: Rails kết nối PostgreSQL qua socket bằng user Ubuntu.
`.env.example` dành cho gói Docker – **không** `source .env` vào terminal, vì `DB_USER` / `DB_PASSWORD`
trong đó sẽ đè lên kết nối socket mặc định của `src/config/database.yml`.

#### 3.2.4. Cài thư viện Ruby
```bash
cd src
bundle install
```

#### 3.2.5. Tạo CSDL, tạo bảng và nạp dữ liệu mẫu
```bash
bin/rails db:prepare                           # tạo CSDL + chạy migration + chạy db/seeds.rb nếu CSDL mới
bin/rails db:seed                              # chạy lại an toàn – không nhân đôi dữ liệu
```

#### 3.2.6. Chạy hệ thống
```bash
bin/rails server                               # mở http://localhost:3000
```

### 3.3. Dữ liệu mẫu sau khi seed (giống nhau ở cả hai cách chạy)

| Dữ liệu | Số lượng | Nguồn |
|---|---|---|
| Tài khoản | 2 | `src/db/seeds.rb` |
| Mức ưu tiên | 4 (Thấp 72h · Trung bình 48h · Cao 24h · Khẩn cấp 8h) | `src/db/seeds.rb` |
| Khách hàng (bộ 300 dòng) | 300 dòng đọc → **279** khách (loại 20 dòng thiếu SĐT, gộp 1 SĐT trùng), mã `KH-100001`… | `data/mau/customers_mau.csv` |
| Nhóm sự cố | 6 (Màn hình, Pin, Sạc, Phần mềm, Nước vào, Khác) | `data/mau/issue_categories.csv` |
| Khách hàng (bộ L2) | 31, mã `KH-(100000 + customer_id)` | `data/mau/customers.csv` |
| Thiết bị | 38 dòng → **31** (loại 7 dòng thiếu ngày mua – BR02); hãng / model / loại lấy từ `products.csv` | `data/mau/devices.csv`, `products.csv` |
| Yêu cầu bảo hành | **30**, trạng thái Mới tiếp nhận; giờ tạo = lúc seed − `hours_ago`, nên khoảng 18 yêu cầu đã quá hạn | `data/mau/tickets.csv` |

Tổng: **2** tài khoản · **310** khách hàng (279 + 31) · **31** thiết bị · **30** yêu cầu.
Bộ L2 nạp bằng `L2DatasetImporter` (TD-28); `service_centers.csv` không nạp vì hệ thống phục vụ một trung tâm.
Dòng bị loại kèm lý do ghi ở `src/tmp/import/l2_reject.csv`. Nạp lại riêng bộ L2: `bin/rails import:l2` (chạy lại không nhân đôi).

**Tài khoản demo** (chỉ dùng cho môi trường phát triển / chấm bài / bản deploy thử):

| Vai trò | Email | Mật khẩu | Được làm gì |
|---|---|---|---|
| Nhân viên tiếp nhận | `quoc@mekong.vn` | `Mekong@2026` | Tra cứu, tạo yêu cầu, đổi trạng thái, **sửa / xóa yêu cầu**, xem danh sách, CRUD khách hàng và nhóm sự cố |
| Quản lý trung tâm | `phu@mekong.vn` | `Mekong@2026` | Tra cứu khách hàng, tạo yêu cầu, xem danh sách / thống kê / phiếu tiếp nhận |

Ngoài môi trường development, seed **không** in mật khẩu demo ra log (BUG-08).

**Nạp toàn bộ dữ liệu khách hàng của giảng viên** (tệp lớn, không commit): chép tệp vào `data/customer.csv` rồi
```bash
bin/rails "import:customers[../data/customer.csv]"   # ~67.000 dòng → ~51.000 khách, chạy lại không nhân đôi
```
Các dòng bị loại kèm lý do được ghi vào `src/tmp/import/customers_reject.csv`.

## 4. Kiểm thử

### 4.1. Bộ test tự động – một lệnh

| Chạy ở đâu | Lệnh |
|---|---|
| Trên máy (thư mục `src`) | `bin/rails test` |
| Trong container Docker | `docker compose exec -e RAILS_ENV=test app bin/rails db:test:prepare test` |
| CI – GitHub Actions | Tự chạy mỗi lần push / pull request trên máy sạch (`.github/workflows/ci.yml`, PostgreSQL 18) |

Kết quả đúng ở bản `v1.0`: `131 runs, 591 assertions, 0 failures, 0 errors, 0 skips`
(ảnh: `docs/screenshots/may-trang-v1-3-test.png` – chạy trong container của bản clone theo tag `v1.0`; CI: `docs/screenshots/ci-pass.png`).
Test tự dựng dữ liệu cần dùng, chạy trên CSDL test riêng, không đụng dữ liệu mẫu.

| Thư mục | Kiểm tra gì |
|---|---|
| `src/test/models/` | Tài khoản, mật khẩu, bảng phân quyền |
| `src/test/services/` | Quy tắc nghiệp vụ ở lớp service: sinh mã, tính hạn SLA, chuyển trạng thái, CRUD khách hàng / nhóm sự cố, làm sạch dữ liệu CSV |
| `src/test/integration/` | Giao diện 3 màn hình, đăng nhập, phân quyền, API (mã HTTP, định dạng lỗi, token), xử lý lỗi 500 / 503, JSON hỏng → 400, seed không lộ mật khẩu |
| `src/test/middleware/` | Lỗi mất CSDL xảy ra trước controller vẫn trả 503 có mã tra cứu |

Chạy riêng một tệp: `bin/rails test test/services/customer_service_test.rb`.

### 4.2. Test Plan và Test Report (Bài tập 3)

- **Test Plan** [`docs/test-plan.md`](docs/test-plan.md): phạm vi, loại test, bảng truy vết BR01–BR14 → test case / test tự động, tiêu chí đạt, môi trường.
- **Test Report** [`docs/test-report.md`](docs/test-report.md): **16 test case** chạy thật theo chức năng (đăng nhập, tra cứu,
  thêm khách, tạo yêu cầu, danh sách, đổi trạng thái, sửa / xóa, phân quyền, nạp dữ liệu), đủ 8 cột – **16 / 16 PASS**.
- Đủ 5 loại: luồng đúng ×6 · giá trị biên ×2 · dữ liệu sai ×2 · bảo mật ×3 (OWASP A01, A07, A05) · tái lập ×1.

```bash
bash scripts/tc.sh TC-05      # chạy lại một test case (in lệnh, kết quả, đếm bản ghi trước / sau)
bash scripts/tc.sh all        # chạy cả 16
```
TC-05, TC-06, TC-16 cần server đang chạy (`cd src && bin/rails server`) và dữ liệu seed. Ảnh từng lần chạy: `docs/screenshots/TC-01.png` → `TC-16.png`.

## 5. Cách kiểm tra hệ thống đã chạy đúng

Với gói Docker: làm theo **mục 5 (Verify it works)** của [`docs/deployment-guide.md`](docs/deployment-guide.md).
Bảng dưới dành cho cách chạy trực tiếp (Cách 2), với server đang chạy ở một tab khác:

| # | Lệnh / thao tác | Kết quả mong đợi |
|---|---|---|
| 1 | `curl -s localhost:3000/api/health` | `{"status":"ok","db":"ok"}` |
| 2 | Mở http://localhost:3000 | Chuyển tới trang **Đăng nhập** |
| 3 | Đăng nhập `quoc@mekong.vn`, tra cứu `0793 573 965` | Thấy khách **Lý Văn Như – KH-100561**, có 1 yêu cầu bảo hành |
| 4 | Đăng nhập `phu@mekong.vn` | Mở **Danh sách yêu cầu**; dùng được Tra cứu và Tạo yêu cầu; trên phiếu tiếp nhận không có nút đổi trạng thái, Sửa, Xóa |
| 5 | Lấy token: `curl -s -X POST localhost:3000/api/session -H "Content-Type: application/json" -d '{"email_address":"phu@mekong.vn","password":"Mekong@2026"}'` | `200` kèm `"token": "..."` |
| 6 | `curl -s localhost:3000/api/warranty_requests -H "Authorization: Bearer <token>"` | Danh sách JSON có `data` và `meta.tong_so` ≥ 8 |
| 7 | `curl -s -i localhost:3000/api/warranty_requests` (không token) | `401` với `"error":"CHUA_XAC_THUC"` |
| 8 | `bash scripts/kiem-tra-api.sh` (ở gốc repo) | Dòng cuối: `Tổng: 40 ca · 40 PASS · 0 FAIL` |
| 9 | `sudo service postgresql stop` rồi F5 trang web và gọi `curl -i localhost:3000/api/health` | Trang **"Hệ thống tạm thời không truy cập được dữ liệu"** và API `503`, cả hai có **mã tra cứu**; bật lại: `sudo service postgresql start` |

### 5.1. API JSON

Xác thực bằng header `Authorization: Bearer <token>` (lấy ở `POST /api/session`). Lỗi luôn có dạng
`{"error": "MA_LOI", "message": "...", "chi_tiet": {...}}`. Tài liệu đầy đủ bằng tiếng Anh (21 endpoint, mỗi endpoint
7 mục, ví dụ thật): [`docs/api-docs.md`](docs/api-docs.md).

| Phương thức | Đường dẫn | Mô tả | Quyền |
|---|---|---|---|
| GET | `/api/health` | Dịch vụ và CSDL còn hoạt động | Không cần token |
| POST / DELETE | `/api/session` | Đăng nhập lấy token (giới hạn 10 lần / 3 phút) / đăng xuất thu hồi token | — |
| GET | `/api/customers?q=&page=` | Danh sách / tra cứu khách hàng | Cả hai vai trò |
| GET · POST · PATCH · DELETE | `/api/customers[/:id]` | CRUD khách hàng (không xóa khách đã có thiết bị – BR13) | Nhân viên tiếp nhận |
| GET | `/api/issue_categories[/:id]` | Danh sách / chi tiết nhóm sự cố | Cả hai vai trò |
| POST · PATCH · DELETE | `/api/issue_categories[/:id]` | CRUD nhóm sự cố (không xóa nhóm đang dùng – BR14) | Nhân viên tiếp nhận |
| GET | `/api/priorities` | Danh mục mức ưu tiên | Cả hai vai trò |
| GET | `/api/stats` | Thống kê có mốc so sánh | Cả hai vai trò |
| GET | `/api/warranty_requests` | Danh sách, lọc, sắp xếp, phân trang | Cả hai vai trò |
| GET | `/api/warranty_requests/:id` | Chi tiết + lịch sử trạng thái | Cả hai vai trò |
| POST | `/api/warranty_requests` | Tạo yêu cầu bảo hành | Cả hai vai trò |
| PATCH | `/api/warranty_requests/:id/status` | Đổi trạng thái / hủy kèm lý do | Nhân viên tiếp nhận |
| PATCH | `/api/warranty_requests/:id` | Sửa thiết bị, mô tả lỗi, nhóm sự cố, mức ưu tiên (gửi trường nào sửa trường đó; đổi ưu tiên thì tính lại hạn) | Nhân viên tiếp nhận |
| DELETE | `/api/warranty_requests/:id` | Xóa yêu cầu kèm lịch sử (giữ thiết bị, khách hàng) | Nhân viên tiếp nhận |

### 5.2. Kiểm tra toàn bộ API

| Cách | Lệnh / thao tác | Kết quả mong đợi |
|---|---|---|
| Script curl (40 ca, máy phát triển) | `bash scripts/kiem-tra-api.sh` (chạy ở gốc repo) | In PASS / FAIL từng ca; dòng cuối `40 PASS · 0 FAIL` |
| Postman (40 request) | Import `docs/postman/SmartCRM_API_BT2.postman_collection.json` → chuột phải collection → **Run collection** | Toàn bộ test **Passed** (thư mục `00` tự đăng nhập và lưu token) |
| Gọi mọi endpoint trên Docker (46 request) | `bash docs/scripts/goi-api-docker.sh` | Ghi request / response thật vào `docs/api-examples.md` (token được che) |
| Demo các mã lỗi | `bash scripts/demo-loi-api.sh` | Từng tình huống: lệnh curl → mã HTTP + JSON lỗi |

Thư mục `08` của collection và cuối các script sẽ **đăng xuất**, làm token cũ hết hiệu lực – lấy token mới bằng `POST /api/session`.

### 5.3. Xử lý lỗi và log (TD-27)

| Tình huống | API | Trang web |
|---|---|---|
| Lỗi nghiệp vụ / dữ liệu sai | `400 / 404 / 409 / 422` có mã lỗi riêng; log mức INFO | Thông báo ngay tại ô nhập |
| Thân request không phải JSON hợp lệ | `400 DU_LIEU_KHONG_HOP_LE` (BUG-07) | — |
| Mất kết nối CSDL | `503 CSDL_KHONG_KHA_DUNG` + header `Retry-After: 30` | Trang 503 thân thiện có nút **Thử lại** |
| Lỗi không lường trước | `500 LOI_HE_THONG` | Trang 500 (production, hoặc chạy `FRIENDLY_ERRORS=1 bin/rails server`) |

- Mọi phản hồi 5xx kèm **mã tra cứu** (= `request_id`, cũng có trong header `X-Request-Id`); người dùng không thấy tên lớp lỗi, câu SQL hay ngăn xếp.
- Mọi dòng log gắn mã tra cứu; mỗi sự cố ghi **ERROR đúng một lần**. Tìm đúng request: `grep "<mã tra cứu>" src/log/development.log` (Docker: `docker compose logs app | grep "<mã tra cứu>"`).
- Log che mật khẩu, token, email, SĐT, địa chỉ và từ khóa tra cứu (`src/config/initializers/filter_parameter_logging.rb`).

## 6. Bảo mật và Bug Log (Bài tập 3)

### 6.1. Checklist bảo mật 7 mục – [`docs/checklist-bao-mat.md`](docs/checklist-bao-mat.md)

Kiểm bằng lệnh chạy thật trên gói Docker (`bash scripts/kiem-bao-mat.sh`, kết quả chữ: `docs/sec-ket-qua.txt`, ảnh `docs/screenshots/sec-*.png`).

| # | Mục | OWASP Top 10:2025 | Trạng thái |
|---|---|---|---|
| 1 | Không có secret nào trong repo | A02 | ĐÃ LÀM |
| 2 | Dữ liệu vào được kiểm ở tầng ứng dụng | A05 | ĐÃ LÀM |
| 3 | Kiểm soát truy cập | A01 | ĐÃ LÀM (theo vai trò; theo chủ sở hữu không áp dụng – TD-29) |
| 4 | Mật khẩu và dữ liệu nhạy cảm được băm / mã hóa | A04, A07 | ĐÃ LÀM (mật khẩu bcrypt) · **CHƯA LÀM** (API token lưu nguyên văn, không hết hạn) |
| 5 | Thông báo lỗi không lộ cấu trúc bên trong | A10, A02 | ĐÃ LÀM |
| 6 | Nhật ký không ghi secret / dữ liệu cá nhân | A09 | ĐÃ LÀM |
| 7 | Phụ thuộc ghim phiên bản, đã kiểm lỗ hổng | A03 | ĐÃ LÀM (`bundler-audit`, `importmap audit` sạch; `brakeman` 3 cảnh báo mức Weak đã đánh giá) |

### 6.2. Bug Log – [`docs/bug-log.md`](docs/bug-log.md)

Mỗi bug sửa bằng một commit `fix(...)` riêng, có test hoặc lệnh xác nhận.

| Mã | Mức độ | Triệu chứng | Commit sửa |
|---|---|---|---|
| BUG-01 | Critical | Quản lý (chỉ được xem) vào được Tra cứu, Tạo yêu cầu và đổi trạng thái | `af9543a` |
| BUG-02 | Major | Clone sạch thiếu `CustomerRowNormalizer`, không dựng được hệ thống | `717f4c5` |
| BUG-03 | Major | Thiếu route `/api` và `Api::WarrantyRequestsController`, API không dùng được | `ce377e4` |
| BUG-04 | Minor | Thẻ thống kê bị cắt dòng mốc so sánh | `515d960` |
| BUG-05 | Minor | 3 test sửa / xóa yêu cầu hỏng do biến `@request` trùng biến của Rails | `a4d69bc` |
| BUG-06 | Major | 11 gem (Rails, rack, nokogiri…) có 44 lỗ hổng đã công bố | `e7c4923` |
| BUG-07 | Minor | Gửi JSON hỏng bị trả 500 thay vì 400 | `1ac9df3` |
| BUG-08 | Minor | Mật khẩu demo bị in ra log container khi nạp dữ liệu mẫu | `50d456d` |
| BUG-09 | Major | Clone bằng Git for Windows thì container `app` không khởi động (script bị đổi sang CRLF) | `5d8f608` |

## 7. Bản deploy thử

| | |
|---|---|
| Địa chỉ | https://smartcrm-app.onrender.com |
| Tài khoản | Tài khoản demo ở mục 3.3 (chỉ có dữ liệu mẫu, không có dữ liệu thật) |
| Kiểm tra nhanh | https://smartcrm-app.onrender.com/api/health → `{"status":"ok","db":"ok"}` |
| Ảnh minh chứng | `docs/screenshots/deploy-render.png` |

Bản deploy chỉ để xem thử. Cách chạy chuẩn để chấm là gói Docker theo tag `v1.0` (mục 3.1).
Khóa bí mật và mật khẩu CSDL của bản deploy khai trong phần Environment của Render, không nằm trong repo.

## 8. Trạng thái hiện tại (Bài tập 3)

**Bài tập 2 – tag `v0.2`**
- [x] Đăng nhập email + mật khẩu (bcrypt), phân quyền 2 vai trò (TD-24); Quản lý tra cứu và tạo yêu cầu, Nhân viên tiếp nhận sửa / xóa yêu cầu (TD-29)
- [x] Migration dựng CSDL từ trạng thái trống (8 bảng) + dữ liệu mẫu chạy lại không nhân đôi
- [x] Nạp khách hàng từ bộ dữ liệu của giảng viên: làm sạch SĐT / họ tên, gộp trùng, ghi dòng bị loại (TD-23)
- [x] CRUD đủ 4 thao tác cho **Khách hàng** và **Nhóm sự cố**; yêu cầu bảo hành: tạo, xem, đổi trạng thái, hủy (TD-25)
- [x] Quy tắc nghiệp vụ: sinh mã duy nhất (BR05, BR12), hạn SLA (BR06), chuyển trạng thái đúng thứ tự + lịch sử (BR08, BR09), một serial chỉ thuộc một khách (BR11), không xóa dữ liệu đang được dùng (BR13, BR14)
- [x] Tách lớp: controller (HTTP) → service (nghiệp vụ, không có dấu vết HTTP) → model (truy cập dữ liệu)
- [x] 3 màn hình lấy dữ liệu qua API bằng `api/client.js`, đủ 3 trạng thái đang tải · rỗng · lỗi có nút Thử lại; thống kê có mốc so sánh (TD-26)
- [x] Xử lý lỗi xuyên lớp: mã tra cứu cho lỗi 500, trả 503 khi mất CSDL, che dữ liệu nhạy cảm trong log (TD-27)
- [x] Bộ kiểm tra toàn bộ API: script curl `scripts/kiem-tra-api.sh` và Postman collection (40 ca)
- [x] Báo cáo BT2 (`BT2_2374802012635_ThaiAnQuoc/`), ảnh minh chứng và tag `v0.2`

**Bài tập 3 – tag `v1.0`**
- [x] Đóng gói Docker + Docker Compose (app production chạy bằng user thường + PostgreSQL 18, healthcheck), dựng bằng 2 lệnh sau khi clone (TD-30)
- [x] Phép thử máy trắng theo tag `v1.0`: clone vào thư mục trống, build lại từ đầu, `healthy`, đủ dữ liệu mẫu, test PASS (ảnh `docs/screenshots/may-trang-v1-*.png`)
- [x] Nạp dữ liệu chạy lại không nhân đôi (`bin/rails import:l2` → "mới 0")
- [x] Test Plan, Test Report 16 test case chạy thật (16 / 16 PASS), bộ test tự động 131 runs, CI GitHub Actions
- [x] Bug Log 9 bug (1 Critical, 4 Major, 4 Minor), mỗi bug một commit sửa riêng
- [x] Deployment Guide và API documentation bằng tiếng Anh
- [x] Checklist bảo mật 7 mục có minh chứng chạy thật; sửa 3 bug tìm được khi kiểm (BUG-06, 07, 08) (TD-31 → TD-33)
- [x] `.gitattributes` ép LF để clone trên Windows vẫn chạy (BUG-09, TD-34)
- [x] Bản deploy thử trên Render

**Hạn chế đã biết:**
- API token lưu nguyên văn trong CSDL và không tự hết hạn (chỉ đổi khi đăng xuất qua `DELETE /api/session`) – kế hoạch: lưu bản băm SHA-256 và thêm hạn dùng.
- Phân quyền theo vai trò; không có phân quyền theo chủ sở hữu vì luồng L2 không có tài khoản khách hàng, nhân viên dùng chung một hàng đợi (TD-29).
- Giao diện không có màn hình riêng cho CRUD khách hàng / nhóm sự cố (thao tác qua API).
- `brakeman` còn 3 cảnh báo mức tin cậy Weak (đã đánh giá trong `docs/checklist-bao-mat.md`).

## 9. Cấu trúc thư mục

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
│   ├── bin/docker-entrypoint     Khởi động container: db:prepare (tạo CSDL, migration, seed lần đầu)
│   ├── config/database.yml       Kết nối CSDL (socket khi dev, biến DB_* khi chạy Docker)
│   ├── db/migrate/               Migration (dựng CSDL từ trống)
│   ├── db/seeds.rb               Dữ liệu mẫu
│   ├── lib/tasks/import.rake     Lệnh nạp khách hàng / bộ L2 từ CSV
│   ├── lib/middleware/           Lưới an toàn trả 503 khi mất CSDL trước controller
│   ├── test/                     Bộ kiểm thử (131 test)
│   └── Gemfile.lock              Tệp khóa phiên bản
├── .github/workflows/ci.yml      CI: chạy toàn bộ test trên máy sạch mỗi lần push
├── Dockerfile                    Image production (build nhiều tầng, chạy bằng user rails)
├── docker-compose.yml            2 dịch vụ app + db, healthcheck, volume dữ liệu
├── .dockerignore · .gitattributes  Loại tệp khỏi image · ép xuống dòng LF (BUG-09)
├── .env.example                  Mẫu biến môi trường cho Docker
├── BT1_2374802012635_ThaiAnQuoc/  Báo cáo Bài tập 1 (PDF, bản chỉnh sửa v2)
├── BT2_2374802012635_ThaiAnQuoc/  Báo cáo Bài tập 2 (PDF + Word)
├── data/mau/                     Bộ dữ liệu mẫu (300 khách + bộ L2); tệp đầy đủ của giảng viên không commit
├── db/schema.sql                 DDL đọc được, đối chiếu thiết kế
├── docs/                         Tài liệu · postman/ · scripts/ · screenshots/ (ảnh minh chứng)
├── scripts/
│   ├── tc.sh · chup-tc.sh        Chạy lại / chụp ảnh 16 test case của Test Report
│   ├── kiem-bao-mat.sh           Checklist bảo mật 7 mục trên gói Docker
│   ├── kiem-tra-api.sh           Kiểm tra toàn bộ API bằng curl (40 ca)
│   └── demo-loi-api.sh           Demo các mã lỗi của API
└── README.md
```

## 10. Tài liệu

| Tệp | Nội dung |
|---|---|
| `docs/srs.md` | Đặc tả yêu cầu (SRS), quy tắc nghiệp vụ BR01–BR14 |
| `docs/thay-doi-thiet-ke.md` | Nhật ký thay đổi thiết kế so với BT1 (TD-01 → TD-34) |
| `docs/deployment-guide.md` | **Deployment Guide** (tiếng Anh) – dựng hệ thống bằng Docker, kiểm tra, xử lý sự cố |
| `docs/test-plan.md` · `docs/test-report.md` · `docs/bug-log.md` | Test Plan · Test Report 16 test case chạy thật · Bug Log (9 bug) |
| `docs/checklist-bao-mat.md` | Checklist bảo mật 7 mục (OWASP Top 10:2025), mỗi mục có minh chứng chạy thật |
| `docs/api-docs.md` | **API documentation** (tiếng Anh) – 21 endpoint, mỗi endpoint 7 mục, ví dụ thật |
| `docs/api-examples.md` | 46 request / response thật trên Docker, sinh bởi `docs/scripts/goi-api-docker.sh` |
| `docs/api-ket-qua-thuc-te.md` | Request / response thật trên máy phát triển, sinh bởi `docs/scripts/goi-api.sh` |
| `docs/postman/SmartCRM_API_BT2.postman_collection.json` | Postman collection 40 request có test tự kiểm tra |
| `docs/tc-ket-qua.txt` · `docs/sec-ket-qua.txt` | Nhật ký chữ của lần chạy 16 test case và checklist bảo mật |
| `docs/ai-disclosure.md` | Khai báo sử dụng công cụ AI (BT2 và BT3) |
| `docs/screenshots/` | 72 ảnh chụp thật: BT2 (API, kiểm thử, lỗi 503, 3 màn hình – mục lục trong `README.md` của thư mục), BT3 (`TC-*`, `sec-*`, `BUG-*`, `docker-*`, `may-trang-*`, `deploy-render`) |
| `docs/*.drawio` | Sơ đồ Use Case, ERD, kiến trúc, wireframe |
| `docs/wireframe-html/` | Bản HTML/CSS dựng từ wireframe |
| `BT1_…/`, `BT2_…/` | Báo cáo Bài tập 1 và Bài tập 2 |
