# Nhật ký thay đổi thiết kế

Luồng L2 – Tiếp nhận và phân loại yêu cầu bảo hành · Thái An Quốc – 2374802012635

Mọi sai lệch so với thiết kế ban đầu (Bài tập 1) đều được ghi tại đây. Mỗi thay đổi có
một mã **TD-xx** và bốn dòng bắt buộc: **phản hồi → quyết định → lý do → ảnh hưởng**.
File này nối tiếp ở BT2, BT3 (thêm mục mới vào cuối, không sửa mục cũ).

---



Điểm BT1: 6.5/10.

### A. Theo góp ý của giảng viên

### TD-01  Viết lại ba câu lập luận kiến trúc (Mục 3.2)
- Phản hồi của GV : 3 câu lập luận không theo khuôn "Vì NFR… yêu cầu…, tôi chọn…, đánh đổi là…";
                    câu 2 và câu 3 gần như trùng nhau (cùng nói về PostgreSQL).
- Quyết định      : SỬA
- Lý do           : Mỗi lựa chọn kiến trúc phải truy được về một NFR có ngưỡng đo được, và phải
                    nêu cái giá phải trả. Viết lại thành 3 lựa chọn khác nhau:
                    (1) NFR05 + NFR02 → MVC + Service Layer, đánh đổi: nhiều lớp và tệp hơn;
                    (2) NFR04 + BR05 → ràng buộc NOT NULL/UNIQUE/CHECK/FK ở PostgreSQL,
                        đánh đổi: khai báo quy tắc ở 2 lớp, migration phải viết cẩn thận;
                    (3) NFR01 + NFR03 → chỉ mục UNIQUE trên phone, chỉ mục (status, due_at),
                        Puma đa luồng, đánh đổi: ghi chậm hơn, tốn dung lượng chỉ mục.
- Ảnh hưởng       : SRS mục 3.2; báo cáo BT1 bản v2.

### TD-02  Bổ sung User Story, đặc tả Use Case và SQL DDL vào bản nộp
- Phản hồi của GV : Bản PDF không có nội dung User Story, không có đặc tả use case (luồng chính
                    đánh số, luồng ngoại lệ 3a…) và không có SQL DDL; các phần này chỉ có trong repo.
- Quyết định      : SỬA
- Lý do           : Bản nộp phải tự đủ để chấm, không bắt người chấm tìm trong repo.
- Ảnh hưởng       : SRS mục 1.3 (US1–US8 kèm tiêu chí chấp nhận), mục 2.3 (đặc tả UC01–UC08,
                    luồng chính đánh số, ngoại lệ dạng 3a/4a), mục 4.4 (DDL PostgreSQL);
                    file db/schema.sql.

### TD-03  Bổ sung FR09 bị thiếu trong bảng yêu cầu chức năng
- Phản hồi của GV : Bảng truy vết có US8 ↔ FR09 nhưng FR09 không tồn tại.
- Quyết định      : SỬA
- Lý do           : UC08 (không tìm thấy khách hàng) và BR07 cần một yêu cầu chức năng để truy vết.
                    FR09: "Hệ thống thông báo khi không tìm thấy khách hàng theo số điện thoại và
                    không cho phép tiếp tục tạo yêu cầu bảo hành" (MUST).
- Ảnh hưởng       : SRS mục 1.4 (bảng FR), mục 1.7 (bảng truy vết).
                    Mã nguồn: CustomerLookupService (trạng thái :not_found), customers/search.html.erb.

### TD-04  Bổ sung các cột trên wireframe nhưng thiếu trong ERD
- Phản hồi của GV : Wireframe có Hãng, Model, IMEI, Ngày mua, Email, Địa chỉ nhưng ERD không có các cột này.
- Quyết định      : SỬA
- Lý do           : Mọi trường nhập trên giao diện phải có chỗ lưu trong CSDL, nếu không sẽ mất dữ liệu.
                    Thêm: customers(code, email, address); devices(device_type, brand, model,
                    purchase_date, warranty_card_number); users(full_name); updated_at cho mọi bảng
                    (Rails cần cột này).
- Ảnh hưởng       : ERD.drawio; db/schema.sql; SRS mục 4.3 (bảng đối chiếu trường wireframe ↔ cột);
                    migration src/db/migrate/20261021070001 → 20261021070006.

### TD-05  Thêm chú thích ký hiệu cho sơ đồ Use Case và ERD
- Phản hồi của GV : Sơ đồ Use Case và ERD chưa có chú thích ký hiệu.
- Quyết định      : SỬA
- Lý do           : Người đọc không thuộc ký hiệu UML/Crow's Foot vẫn phải hiểu được sơ đồ.
- Ảnh hưởng       : UseCase.drawio (actor, use case, ranh giới, association, «include», «extend»);
                    ERD.drawio (PK, FK, UK, ký hiệu bản số một / nhiều).

### TD-06  Hoàn thiện Phụ lục khai báo AI
- Phản hồi của GV : Phụ lục AI thiếu dòng cam kết kèm họ tên, MSSV, ngày, và còn câu mẫu chưa xóa.
- Quyết định      : SỬA
- Lý do           : Đây là mục bắt buộc của mọi bài nộp.
- Ảnh hưởng       : docs/ai-declaration.md; Phụ lục của báo cáo BT1 bản v2.

### TD-07  Bổ sung tệp cấu hình repo và tài liệu API; viết commit đúng quy ước
- Phản hồi của GV : Repo thiếu .gitignore, .env.example, api-contract.md; commit message chung chung.
- Quyết định      : SỬA
- Lý do           : Tránh đẩy bí mật và tệp tạm lên GitHub; người khác dựng lại được môi trường;
                    lịch sử commit đọc được theo từng đơn vị công việc.
- Ảnh hưởng       : .gitignore, .env.example ở thư mục gốc; docs/api-contract.md được thay bằng
                    docs/api-docs.md (theo cấu trúc tài liệu của học phần); commit theo
                    Conventional Commits (feat / fix / docs / chore / test / style / refactor).

### B. Tự phát hiện khi rà soát lại thiết kế

### TD-08  Sửa actor của UC05 trên sơ đồ Use Case
- Phản hồi của GV : (tự phát hiện) Sơ đồ nối "Quản lý trung tâm" với UC05 – Xác định mức độ ưu tiên,
                    mâu thuẫn với SRS mục 1.2 (việc này do Nhân viên tiếp nhận làm).
- Quyết định      : SỬA
- Lý do           : Sơ đồ và SRS phải nói cùng một điều. UC05 là một phần của UC06 («include»).
- Ảnh hưởng       : UseCase.drawio (Quản lý chỉ nối với UC07).

### TD-09  "Quá hạn" là giá trị tính toán, không lưu thành trạng thái
- Phản hồi của GV : (tự phát hiện) Thiết kế ban đầu coi "Quá hạn" là một giá trị của cột status.
- Quyết định      : SỬA
- Lý do           : Nếu lưu cứng, phải có tác vụ định kỳ cập nhật, dễ lệch dữ liệu. Tính trực tiếp:
                    due_at < hiện tại VÀ status ≠ completed. Chỉ mục (status, due_at) phục vụ đúng
                    truy vấn này.
- Ảnh hưởng       : ERD (status chỉ còn new / in_progress / completed); SRS bảng thuật ngữ;
                    WarrantyRequest#overdue?, scope :overdue; WarrantyRequestSearch, WarrantyRequestStats.

### TD-10  Không lưu customer_id trong warranty_requests
- Phản hồi của GV : (tự rà soát) Có thể thêm customer_id vào warranty_requests cho tiện truy vấn.
- Quyết định      : GIỮ NGUYÊN (không thêm)
- Lý do           : Khách hàng của yêu cầu được xác định qua thiết bị (warranty_requests → devices →
                    customers). Lưu thêm customer_id sẽ cho phép trường hợp yêu cầu trỏ khách A nhưng
                    thiết bị thuộc khách B, vi phạm NFR04 (toàn vẹn dữ liệu).
- Ảnh hưởng       : Không. Đã ghi chú lý do trong SRS mục 4.2.

### C. Quyết định phát sinh khi hiện thực mã nguồn

### TD-11  Bỏ chức năng đăng nhập và phân quyền theo vai trò khỏi phạm vi
- Phản hồi của GV : (quyết định khi hiện thực) Thiết kế ban đầu có NFR05 – kiểm soát quyền truy cập
                    theo vai trò, dùng Devise (xác thực) và Pundit (phân quyền).
- Quyết định      : SỬA – chuyển NFR05 sang "Ngoài phạm vi"
- Lý do           : Đã hiện thực thử Devise + Pundit, nhưng để tập trung thời gian vào quy tắc nghiệp vụ
                    của luồng L2 (là nội dung được đánh giá) trước hạn BT2, chức năng này được gỡ bỏ.
                    Người tạo yêu cầu mặc định là nhân viên tiếp nhận đầu tiên (DefaultCurrentUser).
                    HẠN CHẾ ĐÃ BIẾT: ai mở được trình duyệt đều dùng được cả 3 màn hình.
- Ảnh hưởng       : SRS NFR05 (ngoài phạm vi), UC07 (bỏ luồng ngoại lệ 2a); architecture.drawio
                    (bỏ khối Devise, Pundit); ERD (users không có cột mật khẩu);
                    src/app/controllers/concerns/default_current_user.rb.

### TD-12  Tra cứu khách hàng bằng số điện thoại, mã khách hàng hoặc tên
- Phản hồi của GV : (yêu cầu bổ sung khi hiện thực) FR01 ban đầu chỉ cho tra cứu bằng số điện thoại.
- Quyết định      : SỬA – mở rộng FR01
- Lý do           : Khách hàng hay quên hoặc đổi số điện thoại; nhân viên cần tìm được bằng mã KH hoặc
                    tên. Hệ thống tự nhận biết loại từ khóa: bắt đầu bằng 0 → SĐT (vẫn kiểm đủ 10 số);
                    KH-000245 hoặc ≤ 6 chữ số → mã KH; còn lại → tên (không phân biệt hoa thường,
                    có dấu hay không dấu nhờ extension unaccent). Tìm theo tên ra nhiều người thì
                    hiện danh sách để chọn.
- Ảnh hưởng       : SRS FR01; UC01 (thêm luồng 5b – nhiều kết quả); Wireframe màn hình 1;
                    migration 20261021090001_enable_unaccent; CustomerLookupService; customers/search.

### TD-13  Cho phép sửa họ tên khách hàng khi tạo yêu cầu
- Phản hồi của GV : (yêu cầu bổ sung khi hiện thực) Màn hình 2 ban đầu chỉ hiển thị khách hàng đã chọn.
- Quyết định      : SỬA – thêm FR10 (SHOULD)
- Lý do           : Nhân viên cần sửa tên khách hàng ghi sai mà không phải rời màn hình. Việc cập nhật
                    nằm trong cùng transaction với tạo yêu cầu. SĐT và mã KH vẫn chỉ đọc để không gắn
                    nhầm khách hàng (BR01, NFR04).
- Ảnh hưởng       : SRS (thêm FR10, US9, bảng truy vết); Wireframe màn hình 2 (thêm mục
                    "1. Thông tin khách hàng"); WarrantyRequestForm, WarrantyRequestCreator.

### TD-14  Danh sách yêu cầu: mặc định mới tạo nhất lên đầu, thêm ô sắp xếp và khoảng ngày
- Phản hồi của GV : (lỗi phát hiện khi chạy thử) Tạo yêu cầu xong không thấy trong danh sách vì danh sách
                    sắp theo hạn cam kết, 8 dòng mỗi trang, yêu cầu mới rơi sang trang 2.
- Quyết định      : SỬA
- Lý do           : Người dùng phải thấy ngay kết quả thao tác của mình. Mặc định sắp xếp theo thời điểm
                    tạo giảm dần; vẫn chọn được "Hạn cam kết gần nhất" như wireframe. Ô "01/10 – 10/10"
                    thay bằng 2 ô chọn ngày để lọc chính xác.
- Ảnh hưởng       : Wireframe màn hình 3 (ô Sắp xếp, 2 ô ngày); WarrantyRequestSearch (SORT_OPTIONS);
                    manager/warranty_requests/index.html.erb; test manager_warranty_requests_test.rb.

### TD-15  Giao diện: sidebar đủ 3 mục, icon theo template, hiển thị toàn màn hình
- Phản hồi của GV : (điều chỉnh khi hiện thực) Wireframe khóa khung 1280px, sidebar của Quản lý chỉ có
                    1 mục, icon dùng emoji.
- Quyết định      : SỬA
- Lý do           : Đã bỏ phân quyền (TD-11) nên không cần ẩn mục theo vai trò; emoji hiển thị khác nhau
                    giữa các máy; màn hình rộng bị thừa khoảng trắng. Dùng bộ icon Phosphor và Bootstrap
                    Icons giống template mẫu; bố cục co giãn theo màn hình.
- Ảnh hưởng       : Wireframe (cả 3 màn hình); shared/_topbar, shared/_sidebar;
                    stylesheets icons.css, zz_layout.css.

### TD-16  Thêm Form object và Query object vào kiến trúc
- Phản hồi của GV : (quyết định khi hiện thực) Sơ đồ kiến trúc chỉ có Controllers → Services → Models.
- Quyết định      : SỬA
- Lý do           : Form ở màn hình 2 gom dữ liệu của 3 bảng (customers, devices, warranty_requests) nên
                    cần một Form object kiểm tra dữ liệu trước khi lưu. Bộ lọc màn hình 3 nhiều điều kiện
                    nên tách thành Query object để controller chỉ còn nhận tham số. Model của Rails
                    (ActiveRecord) đóng vai trò tầng repository: chỉ truy cập dữ liệu, quy tắc nghiệp vụ
                    nằm ở Service.
- Ảnh hưởng       : architecture.drawio (thêm app/forms, app/queries);
                    src/app/forms/warranty_request_form.rb;
                    src/app/queries/warranty_request_search.rb, warranty_request_stats.rb.

### TD-17  Sinh mã yêu cầu có khóa chống trùng khi tạo đồng thời
- Phản hồi của GV : (quyết định khi hiện thực) Thiết kế chỉ yêu cầu mã duy nhất (BR05), chưa nói cách sinh.
- Quyết định      : SỬA – bổ sung cách hiện thực
- Lý do           : Sinh mã bằng "mã lớn nhất + 1" có thể trùng khi 2 nhân viên bấm Tạo cùng lúc. Dùng
                    pg_advisory_xact_lock trong cùng transaction để tuần tự hóa việc sinh mã; chỉ mục
                    UNIQUE trên code là lớp chặn cuối.
- Ảnh hưởng       : SRS BR05 (ghi chú cách hiện thực); RequestCodeGenerator;
                    test request_code_generator_test.rb.

### TD-18  Giá trị trạng thái trong CSDL và trong mã nguồn
- Phản hồi của GV : (quyết định khi hiện thực) DDL lưu status = 'new' cho "Mới tiếp nhận".
- Quyết định      : GIỮ NGUYÊN giá trị trong CSDL
- Lý do           : Giữ đúng DDL đã nộp. Trong Ruby, giá trị 'new' được đặt tên :received vì
                    WarrantyRequest.new trùng với hàm tạo đối tượng, Rails không cho đặt enum tên :new.
- Ảnh hưởng       : Không đổi DDL. Ghi chú trong src/app/models/warranty_request.rb.

### TD-19  Dùng PostgreSQL 18 thay vì PostgreSQL 16
- Phản hồi của GV : (quyết định khi dựng môi trường) Thiết kế ghi PostgreSQL 16.
- Quyết định      : SỬA phiên bản
- Lý do           : Ubuntu (WSL) cài sẵn bản 18; DDL và các tính năng dùng đến (CHECK, chỉ mục,
                    advisory lock, extension unaccent) đều tương thích, không cần sửa câu lệnh nào.
- Ảnh hưởng       : README mục 2 (yêu cầu môi trường); sơ đồ kiến trúc (nhãn PostgreSQL).

---

## Việc cần làm để tài liệu khớp với các quyết định trên

| Tài liệu | Cập nhật theo | Trạng thái |
|---|---|---|
| docs/srs.md – FR01, FR09, FR10, US9, bảng truy vết | TD-03, TD-12, TD-13 | [ ] |
| docs/srs.md – NFR05 ngoài phạm vi, UC01 luồng 5b, UC07 bỏ 2a, BR05 | TD-11, TD-12, TD-17 | [ ] |
| docs/UseCase.drawio – actor UC05, chú thích ký hiệu | TD-05, TD-08 | [ ] |
| docs/ERD.drawio – cột mới, status 3 giá trị, chú thích ký hiệu | TD-04, TD-05, TD-09 | [ ] |
| docs/architecture.drawio – bỏ Devise/Pundit, thêm forms/queries, PostgreSQL 18 | TD-11, TD-16, TD-19 | [ ] |
| docs/Wireframe.drawio – màn hình 1, 2, 3 | TD-12, TD-13, TD-14, TD-15 | [ ] |
| .gitignore, .env.example, docs/api-docs.md, README | TD-07 | [ ] |

### TD-21  Thêm API JSON bên cạnh giao diện HTML
- Phản hồi của GV : (yêu cầu buổi 8 – track SE) Gọi thử endpoint bằng Postman hoặc curl; thiết kế BT1 chỉ có
                    giao diện HTML render từ server, chưa có API.
- Quyết định      : SỬA – thêm namespace /api
- Lý do           : Có API thì kiểm thử được bằng curl và tích hợp được với frontend khác về sau. API dùng lại
                    đúng các service của giao diện (WarrantyRequestCreator, WarrantyRequestStatusChanger,
                    WarrantyRequestSearch) nên quy tắc nghiệp vụ chỉ viết một lần. Lỗi trả về thống nhất dạng
                    {"error","message","chi_tiet"} với mã nghiệp vụ → mã HTTP (400/404/409/422/500).
                    HẠN CHẾ ĐÃ BIẾT: API không xác thực (theo TD-11).
- Ảnh hưởng       : architecture.drawio (thêm khối API JSON song song với giao diện HTML);
                    src/app/controllers/api/*, src/app/serializers/warranty_request_serializer.rb;
                    WarrantyRequestCreator trả thêm error_code; docs/api-docs.md (S4);
                    test api_warranty_requests_test.rb.

### TD-23 Nạp khách hàng từ bộ dữ liệu mẫu customers_raw.csv
- Phản hồi / nguồn : Buổi 8 yêu cầu nạp dữ liệu từ bộ mẫu của giảng viên. File customers_raw.csv có 67.037 dòng, dữ liệu bẩn: 4.133 dòng thiếu SĐT, SĐT ở nhiều định dạng (dấu chấm, khoảng trắng, +84, 84…), 10.239 SĐT bị trùng, 1.933 tên toàn chữ thường và 2.651 tên toàn chữ hoa.
- Quyết định       : SỬA – thêm CustomerRowNormalizer (làm sạch 1 dòng), CustomerCsvImporter (gộp trùng SĐT, nạp trong 1 transaction, ghi danh sách dòng bị loại) và lệnh bin/rails import:customers. Đưa 300 dòng đầu vào src/db/data/customers_raw_mau.csv; db:seed nạp phần mẫu này. Giữ 8 khách hàng mẫu tự tạo.
- Lý do            : customers.phone có UNIQUE và CHECK ^0[0-9]{9}$ (FR01, NFR04) nên phải chuẩn hóa và gộp trùng trước khi lưu. 300 dòng đủ để demo và chạy nhanh; file đầy đủ vẫn nạp được bằng rake. Mã KH-(100000 + record_id) không đụng các mã KH-000245… đang dùng trong ảnh chụp và tài liệu.
- Ảnh hưởng        : Không đổi schema. Thêm 2 service, 1 rake task, gem csv, 10 test (52 → 62). Kết quả với 300 dòng mẫu: nạp 279, gộp trùng 1, loại 20 (thiếu SĐT).

### TD-25 Bổ sung CRUD đầy đủ cho Khách hàng và Nhóm sự cố
- Thay đổi gì : Thêm 10 API (GET danh sách, GET chi tiết, POST, PATCH, DELETE) cho customers và issue_categories; service CustomerService, IssueCategoryService (lớp nghiệp vụ, không có dấu vết HTTP); quyền manage_customers, manage_catalog chỉ cho Nhân viên tiếp nhận. Quy tắc mới: BR12 mã KH tự sinh KH-NNNNNN (dải 000001–099999, tách khỏi dải 1xxxxx của dữ liệu CSV), BR13 không xóa khách hàng đã có thiết bị, BR14 không xóa nhóm sự cố đang được dùng.
- Vì sao      : BT2 yêu cầu ≥ 2 thực thể có đủ 4 thao tác CRUD (mục S1). Yêu cầu bảo hành giữ nguyên "hủy kèm lý do, không xóa" (FR12) nên chọn 2 thực thể danh mục có thể xóa an toàn khi chưa có dữ liệu phụ thuộc. Quản lý vẫn chỉ xem theo User Story.
- Ảnh hưởng   : routes.rb (namespace api), User::PERMISSIONS, thêm 4 service, 2 serializer, 2 controller API; 16 test mới; SRS cần thêm US12, US13, FR13, FR14, BR12–BR14; api-docs thêm 10 endpoint.

### TD-26 Giao diện lấy dữ liệu qua API bằng lớp client riêng
- Thay đổi gì : Thêm app/javascript/api/client.js là nơi duy nhất giao diện gọi API (timeout 8 s, GET thử lại tối đa 2 lần có giãn cách, lỗi chuẩn hóa thành ApiError). Api::BaseController nhận thêm phiên đăng nhập web khi có header X-Requested-With. Thêm GET /api/stats (mỗi số liệu kèm mốc so sánh: hôm qua, tổng đang mở, mục tiêu quá hạn = 0) và GET /api/priorities. Ba màn hình chuyển sang lấy dữ liệu từ API, hiển thị đủ ba trạng thái đang tải · rỗng · lỗi kết nối có nút Thử lại.
- Vì sao      : BT2 mục S4 yêu cầu ≥ 3 màn hình lấy dữ liệu từ API thật qua một lớp client riêng và xử lý đủ ba trạng thái; số liệu trình bày phải có mốc so sánh. Thiết kế BT1 render dữ liệu ở server (ERB) nên chưa đáp ứng.
- Ảnh hưởng   : Api::BaseController, routes.rb, config/importmap.rb, thêm query DashboardStats, 2 controller API, client.js và các Stimulus controller của 3 màn hình; 4 test mới; sơ đồ kiến trúc thực tế thêm tầng "API client (JS)".

### TD-27 Xử lý lỗi hệ thống thống nhất: mã tra cứu, 503 khi mất CSDL (Buổi 11)
- Thay đổi gì : Concern SystemErrorHandling dùng chung cho web và API: mất CSDL → 503 CSDL_KHONG_KHA_DUNG + Retry-After; lỗi khác → 500 LOI_HE_THONG; cả hai kèm mã tra cứu = request_id. Middleware DatabaseUnavailableResponder bắt lỗi mất CSDL xảy ra trước controller. Trang lỗi riêng (layout không gọi CSDL) có nút Thử lại. Mọi dòng log gắn request_id; mỗi sự cố ghi ERROR một lần, lỗi 4xx ghi INFO; che phone, address, email, q, token, mật khẩu trong log.
- Vì sao      : Buổi 11 – dịch lỗi ở ranh giới, ghi log một lần ở lớp trên cùng, không lộ chi tiết kỹ thuật, người dùng có mã để báo lỗi.
- Ảnh hưởng   : Api::BaseController, Api::HealthController, ApplicationController, config/application.rb, filter_parameter_logging.rb; thêm concern, middleware, views/errors, layouts/error; 6 test mới (109 → 115).

### TD-28 Dữ liệu mẫu lấy từ bộ dữ liệu L2 của giảng viên thay cho dữ liệu tự tạo
- Thay đổi gì : Bỏ 8 khách / thiết bị / yêu cầu viết tay trong db/seeds.rb; thêm L2DatasetImporter và rake import:l2 nạp data/mau/ issue_categories.csv, customers.csv, products.csv, devices.csv, tickets.csv. Khách tìm theo SĐT (chuẩn hóa +84 → 0), mã mới KH-(100000 + customer_id); thiết bị tìm theo serial, hãng / model / loại suy ra từ tên sản phẩm; phiếu thành yêu cầu Mới tiếp nhận, giờ tạo = lúc nạp − hours_ago, hạn = giờ tạo + SLA (BR06). Dòng lỗi (SĐT sai, thiếu ngày mua – BR02, serial của khách khác) bị loại kèm lý do. service_centers.csv, warranty_months, is_warranty chưa nạp vì thiết kế hiện tại không có bảng trung tâm và cột thời hạn bảo hành.
- Vì sao      : Dữ liệu demo và chấm bài phải là dữ liệu thật của đề, có sẵn yêu cầu quá hạn để Màn hình 3 hiển thị đúng. Sửa luôn lỗi seeds: mảng rows bị chú thích nhưng vòng lặp rows.each vẫn chạy nên db:seed dừng giữa chừng (không tạo tài khoản đăng nhập trên máy mới).
- Ảnh hưởng   : Không đổi schema. db/seeds.rb, lib/tasks/import.rake, thêm service L2DatasetImporter và 3 test. Sau seed trên CSDL trống: 310 khách, 31 thiết bị, 30 yêu cầu (khoảng 18 quá hạn), loại 7 dòng.
