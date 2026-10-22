# Smart CRM – Mekong Mobile · Luồng L2: Tiếp nhận và phân loại yêu cầu bảo hành

Đồ án môn **Chuyên đề tốt nghiệp 1** – Khoa CNTT, Trường Đại học Văn Lang · Track **SE**

| | |
|---|---|
| Sinh viên | Thái An Quốc – 2374802012635 |
| Lớp | 261_71ITGR40203_06 |
| Giảng viên | TS. Nguyễn Trí Hải |

## 1. Giới thiệu

Ứng dụng web cho nhân viên tiếp nhận tại trung tâm bảo hành:

- **Màn hình 1 – Tra cứu khách hàng** bằng số điện thoại, mã khách hàng hoặc tên (UC01, UC08).
- **Màn hình 2 – Tạo yêu cầu bảo hành**: ghi nhận thiết bị, mô tả lỗi, phân loại nhóm sự cố, mức ưu tiên;
  hệ thống tự sinh mã `BH-YYYY-NNNNNN` và tính hạn cam kết theo SLA (UC02–UC06).
- **Phiếu tiếp nhận**: in phiếu, cập nhật trạng thái (Mới tiếp nhận → Đang xử lý → Hoàn tất), hủy kèm lý do,
  xem lịch sử trạng thái.
- **Màn hình 3 – Danh sách yêu cầu**: thống kê, tìm kiếm, lọc, sắp xếp, phân trang, đánh dấu quá hạn (UC07).
- **API JSON** `/api/...` cho cùng các chức năng (gọi bằng curl / Postman).

## 2. Yêu cầu môi trường

| Thành phần | Phiên bản đã dùng | Kiểm tra bằng |
|---|---|---|
| Hệ điều hành | Ubuntu 26.04 chạy trên WSL (Windows) | `lsb_release -a` |
| Ruby | 4.0.5 (cài bằng `mise`, xem `src/.ruby-version`) | `ruby -v` |
| Ruby on Rails | 8.1 | `cd src && bin/rails -v` |
| PostgreSQL | 18 (gói `postgresql`, có extension `unaccent`) | `psql --version` |
| Thư viện hệ thống | `libpq-dev` (để cài gem `pg`) | `dpkg -l libpq-dev` |
| Trình duyệt | Chrome / Edge bản mới (Rails 8 chặn trình duyệt quá cũ) | — |

Không cần Node.js: giao diện dùng Importmap + Hotwire (Turbo, Stimulus) có sẵn trong Rails 8.

**Biến môi trường:** xem `.env.example` (`DATABASE_URL`, `PORT`, `RAILS_MAX_THREADS`, `RAILS_ENV`,
`RAILS_MASTER_KEY`). Ở môi trường phát triển có thể bỏ qua – Rails kết nối PostgreSQL qua socket với
user trùng tên user Ubuntu.

**Ghi chú:** dùng PostgreSQL 18 thay vì 16 như thiết kế ban đầu – xem `docs/thay-doi-thiet-ke.md` TD-19.

## 3. Cài đặt và chạy

```bash
# 1. Cài PostgreSQL và thư viện (một lần)
sudo apt install -y postgresql libpq-dev
sudo service postgresql start                 # WSL: chạy lại mỗi khi mở máy
sudo -u postgres createuser -s "$USER"        # tạo user CSDL trùng tên user Ubuntu

# 2. Cài gem, tạo CSDL, nạp dữ liệu mẫu
cd src
bundle install
bin/rails db:create db:migrate db:seed

# 3. Chạy
bin/rails server                              # mở http://localhost:3000
```

Dữ liệu mẫu: 2 người dùng, 4 mức ưu tiên (Thấp 72h, Trung bình 48h, Cao 24h, Khẩn cấp 8h),
6 nhóm sự cố, 8 khách hàng, 8 thiết bị, 8 yêu cầu (2 quá hạn).

## 4. Kiểm thử

```bash
cd src
bin/rails test                                # 52 test: model, service, giao diện, API
```

Gọi thử API thật (server đang chạy ở tab khác):

```bash
curl -s localhost:3000/api/health             # {"status":"ok","db":"ok"}
bash docs/scripts/goi-api.sh                  # chạy ở thư mục gốc – 12 request, lưu vào docs/api-ket-qua-thuc-te.md
```

## 5. Cấu trúc thư mục

Thư mục `src/app/` ánh xạ một–một với các lớp trong sơ đồ kiến trúc (`docs/architecture.drawio`):

```
src/app/
├── controllers/          Tầng 1 – nhận HTTP, gọi service, chọn view / JSON
│   ├── customers_controller.rb, warranty_requests_controller.rb   (giao diện HTML)
│   ├── manager/warranty_requests_controller.rb                    (Màn hình 3)
│   └── api/                                                       (API JSON)
├── forms/                Kiểm tra dữ liệu nhập của form nhiều bảng (WarrantyRequestForm)
├── services/             Tầng 2 – quy tắc nghiệp vụ, KHÔNG biết gì về HTTP
│   ├── customer_lookup_service.rb        UC01, UC08
│   ├── warranty_request_creator.rb       UC06 – một transaction
│   ├── request_code_generator.rb         BR05 – mã duy nhất, khóa chống trùng
│   ├── sla_deadline_calculator.rb        BR06 – hạn cam kết
│   └── warranty_request_status_changer.rb  cập nhật trạng thái / hủy
├── queries/              Truy vấn danh sách, thống kê (UC07)
├── models/               Tầng 3 – ActiveRecord: truy cập dữ liệu + ràng buộc (đóng vai trò repository)
├── serializers/          Định dạng JSON cho API
└── views/, helpers/, javascript/, assets/   Giao diện
src/db/migrate/           Tạo bảng theo DDL (docs/thay-doi-thiet-ke.md TD-04, TD-20)
src/db/seeds.rb           Dữ liệu mẫu
src/test/                 Kiểm thử tự động
docs/                     Tài liệu thiết kế, nhật ký thay đổi, API, ảnh chụp
```

## 6. Trạng thái hiện tại (buổi 8)

- [x] Đã đọc phản hồi BT1, ghi 22 quyết định vào `docs/thay-doi-thiet-ke.md` (TD-01 → TD-22)
- [x] Cấu trúc `src/` theo sơ đồ kiến trúc: controllers → services / forms / queries → models
- [x] Migration tạo 7 bảng theo DDL BT1 (đã bổ sung cột theo wireframe, bảng lịch sử trạng thái)
- [x] Dữ liệu danh mục và dữ liệu mẫu (`db/seeds.rb`)
- [x] Entity chính `warranty_requests` có đủ CRUD: tạo, xem, cập nhật trạng thái, hủy – qua giao diện và API
- [x] 3 màn hình theo wireframe chạy với dữ liệu thật
- [x] API JSON 5 endpoint, đã gọi thử bằng curl (`docs/api-ket-qua-thuc-te.md`, `docs/screenshots/`)
- [x] 52 test tự động, chạy bằng `bin/rails test`
- [x] `docs/srs.md` phiên bản 2.0 thống nhất mã US / FR / BR / UC với mã nguồn (TD-22)
- [ ] Cập nhật lại sơ đồ `.drawio` theo các TD (bảng cuối `docs/thay-doi-thiet-ke.md`)
- [ ] Commit theo quy ước và đẩy lên GitHub
- **Ngoài phạm vi (TD-11):** đăng nhập và phân quyền theo vai trò – mọi người dùng đều vào được cả 3 màn hình.

## 7. Tài liệu

| Tệp | Nội dung |
|---|---|
| `docs/srs.md` | Đặc tả yêu cầu (SRS rút gọn) |
| `docs/thay-doi-thiet-ke.md` | Nhật ký thay đổi thiết kế so với BT1 (TD-xx) |
| `docs/api-docs.md` | Tài liệu API JSON |
| `docs/api-ket-qua-thuc-te.md` | Request / response thật, sinh bởi `docs/scripts/goi-api.sh` |
| `docs/screenshots/` | Ảnh chụp giao diện và kết quả chạy |
| `docs/*.drawio` | Sơ đồ Use Case, ERD, kiến trúc, wireframe |
| `docs/wireframe-html/` | Bản HTML/CSS dựng từ wireframe |
| `docs/ai-declaration.md` | Khai báo sử dụng công cụ AI |
