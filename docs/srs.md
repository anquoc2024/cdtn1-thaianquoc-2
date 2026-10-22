# ĐẶC TẢ YÊU CẦU PHẦN MỀM (SRS)

**Luồng nghiệp vụ:** L2 – Tiếp nhận và phân loại yêu cầu bảo hành  
**Sinh viên:** Thái An Quốc  
**MSSV:** 2374802012635  
**Track:** Công nghệ Phần mềm (SE)  
**Phiên bản:** 2.0 – cập nhật sau phản hồi Bài tập 1 (buổi 8, 21/10/2026)

> Mọi thay đổi so với phiên bản 1.0 đều có mã TD-xx trong `docs/thay-doi-thiet-ke.md`.
> Từ phiên bản này dùng thống nhất một bộ mã: **US, FR, NFR, BR, UC** – trùng với báo cáo BT1,
> mã nguồn và bộ kiểm thử (TD-22).

---

## 1. Thông tin và phạm vi

### 1.1. Mục tiêu

Hệ thống hỗ trợ nhân viên tiếp nhận tại trung tâm bảo hành: xác định khách hàng (theo số điện thoại,
mã khách hàng hoặc họ tên), ghi nhận thiết bị, mô tả lỗi, phân loại nhóm sự cố, xác định mức độ ưu tiên và
tạo yêu cầu bảo hành. Khi tạo yêu cầu, hệ thống tự sinh mã yêu cầu và tự tính hạn cam kết xử lý theo SLA
của mức ưu tiên.

Sau khi tiếp nhận, yêu cầu được cập nhật trạng thái (Mới tiếp nhận → Đang xử lý → Hoàn tất) hoặc hủy kèm
lý do; mọi lần đổi trạng thái đều được ghi lịch sử. Quản lý trung tâm xem danh sách, thống kê và lọc các yêu
cầu để theo dõi tiến độ, phát hiện yêu cầu quá hạn.

### 1.2. Phạm vi

**Trong phạm vi:**

- Tra cứu khách hàng bằng số điện thoại, mã khách hàng hoặc họ tên.
- Thông báo khi không tìm thấy khách hàng.
- Ghi nhận thông tin thiết bị, nhập mô tả lỗi, phân loại nhóm sự cố, xác định mức độ ưu tiên.
- Tạo yêu cầu bảo hành; tự sinh mã yêu cầu; tự tính hạn cam kết xử lý.
- Cập nhật họ tên khách hàng khi tạo yêu cầu.
- Cập nhật trạng thái yêu cầu; hủy yêu cầu kèm lý do; lưu lịch sử trạng thái.
- Xem danh sách, thống kê, tìm kiếm, lọc, sắp xếp yêu cầu bảo hành.
- API JSON cho các chức năng trên (`docs/api-docs.md`).

**Ngoài phạm vi:**

- Đăng nhập và phân quyền theo vai trò (TD-11) – xem NFR05.
- Đăng ký khách hàng mới, sửa chữa thiết bị, quản lý linh kiện, thanh toán, giao trả thiết bị.

### 1.3. Đối tượng sử dụng

| Actor | Vai trò |
|---|---|
| Nhân viên tiếp nhận | Tra cứu khách hàng; ghi nhận thiết bị, mô tả lỗi; phân loại; tạo yêu cầu; cập nhật trạng thái, hủy yêu cầu. |
| Quản lý trung tâm | Xem danh sách, thống kê và trạng thái các yêu cầu; cập nhật trạng thái, hủy yêu cầu. |
| Hệ thống | Kiểm tra dữ liệu, sinh mã, tính hạn cam kết, ghi lịch sử, thông báo lỗi. |

Vì đăng nhập nằm ngoài phạm vi, hệ thống không phân biệt vai trò khi truy cập; người thao tác được ghi nhận
mặc định là nhân viên tiếp nhận đầu tiên trong dữ liệu (hạn chế đã biết, TD-11).

### 1.4. Dữ liệu chính

| Bảng | Mục đích |
|---|---|
| `customers` | Khách hàng: mã KH, họ tên, số điện thoại (duy nhất), email, địa chỉ. |
| `devices` | Thiết bị của khách hàng: loại, hãng, model, số serial/IMEI (duy nhất), ngày mua, số phiếu bảo hành. |
| `warranty_requests` | Yêu cầu bảo hành: mã yêu cầu, thiết bị, nhóm sự cố, mức ưu tiên, mô tả lỗi, trạng thái, hạn cam kết, thời điểm đóng. |
| `issue_categories` | Danh mục nhóm sự cố. |
| `priorities` | Danh mục mức ưu tiên và số giờ SLA (Thấp 72h, Trung bình 48h, Cao 24h, Khẩn cấp 8h). |
| `warranty_request_status_logs` | Lịch sử trạng thái: trạng thái cũ, trạng thái mới, ghi chú, người đổi, thời điểm. |
| `users` | Người dùng hệ thống (họ tên, vai trò) – dùng để ghi người tạo / người đổi trạng thái. |

Bản v1.0 dùng tên `ticket`, `ticket_status_log`; đã đổi thành tên bảng thật trong cơ sở dữ liệu (TD-22).

### 1.5. Thuật ngữ

| Thuật ngữ | Ý nghĩa |
|---|---|
| Hạn cam kết (SLA) | Thời điểm cam kết xử lý xong = thời điểm tạo yêu cầu + số giờ SLA của mức ưu tiên. |
| Quá hạn | Yêu cầu chưa đóng có hạn cam kết nhỏ hơn thời điểm hiện tại. **Giá trị tính toán, không lưu** (TD-09). |
| Yêu cầu đã đóng | Yêu cầu ở trạng thái Hoàn tất hoặc Đã hủy; không đổi trạng thái được nữa. |
| Hủy yêu cầu | Chuyển sang trạng thái Đã hủy kèm lý do; **không xóa dữ liệu** (TD-20). |

---

## 2. User Story

| Mã | Actor | User Story | MoSCoW |
|---|---|---|---|
| US1 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn tra cứu khách hàng theo số điện thoại, mã khách hàng hoặc họ tên để nhanh chóng xác định khách hàng trước khi tiếp nhận yêu cầu bảo hành. | MUST |
| US2 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn ghi nhận thông tin thiết bị của khách hàng để xác định chính xác thiết bị cần được bảo hành. | MUST |
| US3 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn nhập mô tả lỗi của thiết bị để ghi nhận chính xác vấn đề và cung cấp thông tin cho quá trình xử lý. | SHOULD |
| US4 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn phân loại nhóm sự cố để yêu cầu được ghi nhận theo đúng loại vấn đề. | SHOULD |
| US5 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn xác định mức độ ưu tiên để trung tâm sắp xếp thứ tự xử lý phù hợp. | SHOULD |
| US6 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn tạo yêu cầu bảo hành và được hệ thống tự sinh mã, tự tính hạn cam kết để báo lại cho khách hàng. | MUST |
| US7 | Quản lý trung tâm | Là quản lý trung tâm, tôi muốn xem danh sách, thống kê và trạng thái các yêu cầu để theo dõi tiến độ và phát hiện yêu cầu quá hạn. | SHOULD |
| US8 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn được thông báo rõ khi không tìm thấy khách hàng để kiểm tra lại thông tin và không tạo nhầm yêu cầu. | MUST |
| US9 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn sửa họ tên khách hàng ngay khi tạo yêu cầu để thông tin trên phiếu chính xác. | SHOULD |
| US10 | Nhân viên tiếp nhận, Quản lý trung tâm | Là người xử lý yêu cầu, tôi muốn cập nhật trạng thái yêu cầu (Đang xử lý, Hoàn tất) để mọi người biết tiến độ, và xem được lịch sử thay đổi. | MUST |
| US11 | Nhân viên tiếp nhận, Quản lý trung tâm | Là người xử lý yêu cầu, tôi muốn hủy yêu cầu kèm lý do khi khách không tiếp tục bảo hành, mà vẫn giữ lại dữ liệu để tra cứu. | SHOULD |

US8 đổi từ SHOULD (v1.0) thành MUST cho khớp với FR09 và BR07 (chặn tạo yêu cầu khi chưa có khách hàng).

---

## 3. Tiêu chí chấp nhận

### 3.1. US1 – Tra cứu khách hàng

**AC1.1 – Tìm thấy theo số điện thoại hoặc mã khách hàng**
- **Given:** Nhân viên đang ở màn hình tra cứu khách hàng.
- **When:** Nhân viên nhập số điện thoại hợp lệ (có thể có dấu cách, VD `0905 123 456`) hoặc mã khách hàng (`KH-000245` hoặc `245`) của khách hàng đã tồn tại.
- **Then:** Hệ thống hiển thị thông tin khách hàng trong ≤ 2 giây (NFR01) và cho phép chuyển sang tạo yêu cầu.

**AC1.2 – Số điện thoại sai định dạng**
- **Given:** Nhân viên đang tra cứu.
- **When:** Nhân viên nhập chuỗi bắt đầu bằng 0 nhưng không đủ 10 chữ số (VD `0905 12`).
- **Then:** Hệ thống báo "Số điện thoại phải gồm 10 chữ số, bắt đầu bằng 0" và **không truy vấn** cơ sở dữ liệu.

**AC1.3 – Tìm theo họ tên ra nhiều khách hàng**
- **Given:** Có nhiều khách hàng cùng chứa từ khóa trong họ tên.
- **When:** Nhân viên nhập một phần họ tên, có dấu hoặc không dấu (VD `thi`, `nguyen`).
- **Then:** Hệ thống hiển thị danh sách khách hàng phù hợp (tối đa 20), mỗi dòng có nút chọn.

**AC1.4 – Không tìm thấy khách hàng (US8)**
- **Given:** Nhân viên đang tra cứu.
- **When:** Từ khóa hợp lệ nhưng không khớp khách hàng nào.
- **Then:** Hệ thống thông báo không tìm thấy, nêu lại từ khóa đã nhập, và **không có** nút tiếp tục tạo yêu cầu.

### 3.2. US2 – Ghi nhận thông tin thiết bị

**AC2.1 – Thiếu thông tin thiết bị**
- **Given:** Nhân viên đang nhập thông tin thiết bị.
- **When:** Thiếu một hoặc nhiều trường bắt buộc (loại, hãng, model, serial/IMEI, ngày mua).
- **Then:** Hệ thống đánh dấu đỏ từng trường thiếu, nêu lý do và không tạo yêu cầu.

**AC2.2 – Serial đã thuộc khách hàng khác**
- **Given:** Số serial đã được đăng ký cho một khách hàng khác.
- **When:** Nhân viên tạo yêu cầu với serial đó.
- **Then:** Hệ thống báo "Số serial / IMEI này đã được đăng ký cho khách hàng khác" và không tạo yêu cầu (NFR04).

### 3.3. US6 – Tạo yêu cầu bảo hành và hạn cam kết

**AC6.1 – Tạo yêu cầu thành công**
- **Given:** Đã có khách hàng, thông tin thiết bị, mô tả lỗi, nhóm sự cố, mức ưu tiên hợp lệ.
- **When:** Nhân viên bấm "Tạo yêu cầu bảo hành".
- **Then:** Trong ≤ 3 giây (NFR02), hệ thống tạo yêu cầu có mã dạng `BH-YYYY-NNNNNN` duy nhất, trạng thái "Mới tiếp nhận", hạn cam kết = thời điểm tạo + số giờ SLA, ghi dòng lịch sử đầu tiên, và hiển thị phiếu tiếp nhận.

**AC6.2 – Thông tin không hợp lệ**
- **Given:** Nhân viên đang tạo yêu cầu.
- **When:** Thông tin bắt buộc bị thiếu hoặc sai.
- **Then:** Hệ thống báo lỗi tại từng trường và **không tạo** bất kỳ dữ liệu nào (kể cả thiết bị).

### 3.4. US7 – Xem danh sách yêu cầu

**AC7.1 – Lọc yêu cầu quá hạn**
- **Given:** Có yêu cầu chưa đóng đã qua hạn cam kết.
- **When:** Quản lý chọn trạng thái "Quá hạn" và bấm Lọc.
- **Then:** Chỉ các yêu cầu quá hạn được hiển thị, dòng tô đỏ; thẻ thống kê "Quá hạn cam kết" hiển thị đúng số lượng.

**AC7.2 – Yêu cầu mới tạo thấy ngay**
- **Given:** Nhân viên vừa tạo một yêu cầu.
- **When:** Mở danh sách yêu cầu với sắp xếp mặc định.
- **Then:** Yêu cầu vừa tạo nằm ở dòng đầu tiên (TD-14).

### 3.5. US10, US11 – Cập nhật trạng thái và hủy yêu cầu

**AC10.1 – Chuyển trạng thái hợp lệ**
- **Given:** Yêu cầu đang "Mới tiếp nhận".
- **When:** Người dùng bấm "Bắt đầu xử lý".
- **Then:** Trạng thái thành "Đang xử lý" và lịch sử có thêm dòng "Mới tiếp nhận → Đang xử lý".

**AC10.2 – Chuyển trạng thái sai thứ tự**
- **Given:** Yêu cầu đang "Mới tiếp nhận".
- **When:** Người dùng (hoặc API) yêu cầu chuyển thẳng sang "Hoàn tất".
- **Then:** Hệ thống từ chối, báo "Không thể chuyển từ … sang …", trạng thái giữ nguyên.

**AC11.1 – Hủy có lý do**
- **Given:** Yêu cầu chưa hoàn tất.
- **When:** Người dùng nhập lý do và bấm "Hủy yêu cầu".
- **Then:** Trạng thái thành "Đã hủy", ghi thời điểm đóng, lý do được lưu trong lịch sử; dữ liệu không bị xóa.

**AC11.2 – Hủy thiếu lý do hoặc yêu cầu đã đóng**
- **When:** Hủy mà không nhập lý do, hoặc đổi trạng thái một yêu cầu đã Hoàn tất / Đã hủy.
- **Then:** Hệ thống từ chối và giải thích lý do; không có thay đổi nào được lưu.

---

## 4. Use Case

### 4.1. Danh sách Use Case

| Mã | Tên Use Case | Actor chính | Mục tiêu | MoSCoW |
|---|---|---|---|---|
| UC01 | Tra cứu khách hàng | Nhân viên tiếp nhận | Xác định khách hàng theo SĐT, mã KH hoặc họ tên | MUST |
| UC02 | Ghi nhận thông tin thiết bị | Nhân viên tiếp nhận | Ghi nhận chính xác thiết bị cần bảo hành | MUST |
| UC03 | Nhập mô tả lỗi | Nhân viên tiếp nhận | Ghi nhận vấn đề của thiết bị | SHOULD |
| UC04 | Phân loại nhóm sự cố | Nhân viên tiếp nhận | Phân loại yêu cầu theo nhóm sự cố | SHOULD |
| UC05 | Xác định mức độ ưu tiên | Nhân viên tiếp nhận | Xác định mức ưu tiên làm căn cứ tính hạn | SHOULD |
| UC06 | Tạo yêu cầu bảo hành và hạn cam kết xử lý | Nhân viên tiếp nhận | Lưu yêu cầu, sinh mã, tính hạn cam kết | MUST |
| UC07 | Xem danh sách và trạng thái yêu cầu bảo hành | Quản lý trung tâm | Theo dõi tiến độ, phát hiện quá hạn | SHOULD |
| UC08 | Thông báo không tìm thấy khách hàng | Hệ thống (cho Nhân viên tiếp nhận) | Báo không tìm thấy, chặn tạo yêu cầu | MUST |
| UC09 | Cập nhật trạng thái yêu cầu | Nhân viên tiếp nhận, Quản lý trung tâm | Chuyển trạng thái theo đúng thứ tự, ghi lịch sử | MUST |
| UC10 | Hủy yêu cầu bảo hành | Nhân viên tiếp nhận, Quản lý trung tâm | Hủy kèm lý do, giữ lại dữ liệu | SHOULD |

### 4.2. Quan hệ giữa các Use Case

| Use Case | Quan hệ | Mô tả |
|---|---|---|
| UC01 – Tra cứu khách hàng | «include» bởi UC06 | Bắt buộc xác định khách hàng khi tạo yêu cầu. |
| UC02 – Ghi nhận thông tin thiết bị | «include» bởi UC06 | |
| UC03 – Nhập mô tả lỗi | «include» bởi UC06 | |
| UC04 – Phân loại nhóm sự cố | «include» bởi UC06 | |
| UC05 – Xác định mức độ ưu tiên | «include» bởi UC06 | |
| UC06 – Tạo yêu cầu bảo hành | Use Case chính | |
| UC07 – Xem danh sách | Độc lập | |
| UC08 – Thông báo không tìm thấy | «extend» UC01 | Chỉ xảy ra khi tra cứu không ra khách hàng (điểm mở rộng: UC01 bước 5). |
| UC09 – Cập nhật trạng thái | Độc lập | Thực hiện trên Phiếu tiếp nhận, sau UC06. |
| UC10 – Hủy yêu cầu | «extend» UC09 | Một nhánh của cập nhật trạng thái, có thêm bước nhập lý do. |

### 4.3. Đặc tả chi tiết

Luồng chính đánh số theo bước; luồng ngoại lệ đánh số theo bước phát sinh (VD **4a** xảy ra tại bước 4).

#### UC01 – Tra cứu khách hàng
- **Tiền điều kiện:** Không có.
- **Luồng chính:**
  1. Nhân viên chọn "Tra cứu khách hàng".
  2. Hệ thống hiển thị ô nhập từ khóa.
  3. Nhân viên nhập số điện thoại, mã khách hàng hoặc họ tên và bấm "Tra cứu".
  4. Hệ thống nhận biết loại từ khóa (bắt đầu bằng 0 → SĐT; `KH-…` hoặc ≤ 6 chữ số → mã KH; còn lại → họ tên) và kiểm tra định dạng.
  5. Hệ thống tìm khách hàng.
  6. Hệ thống hiển thị thông tin khách hàng: họ tên, mã KH, SĐT, email, địa chỉ, số yêu cầu trước đây.
  7. Nhân viên bấm "Chọn khách hàng & tiếp tục" → sang UC06.
- **Luồng ngoại lệ:**
  - **4a.** SĐT sai định dạng: báo "Số điện thoại phải gồm 10 chữ số, bắt đầu bằng 0", quay lại bước 3, không truy vấn CSDL.
  - **4b.** Họ tên ít hơn 2 ký tự: báo "Nhập ít nhất 2 ký tự để tìm theo tên", quay lại bước 3.
  - **5a.** Không tìm thấy khách hàng: chuyển sang UC08.
  - **5b.** Tìm theo họ tên ra nhiều khách hàng: hiển thị danh sách (tối đa 20), nhân viên chọn đúng người, tiếp tục bước 7.
- **Hậu điều kiện:** Khách hàng được xác định.
- **Liên quan:** FR01, FR09, BR01, BR07, NFR01.

#### UC02 – Ghi nhận thông tin thiết bị
- **Tiền điều kiện:** Khách hàng đã được xác định (UC01).
- **Luồng chính:**
  1. Hệ thống hiển thị form tạo yêu cầu, kèm thông tin khách hàng đã chọn.
  2. Nhân viên chọn loại thiết bị, hãng; nhập model.
  3. Nhân viên nhập số serial/IMEI, ngày mua, số phiếu bảo hành (không bắt buộc).
- **Luồng ngoại lệ:**
  - **3a.** Serial đã có và thuộc chính khách hàng này: dùng lại thiết bị cũ, không tạo thiết bị mới.
  - **3b.** Serial đã thuộc khách hàng khác: báo lỗi, không cho tạo yêu cầu (BR11).
  - **3c.** Ngày mua lớn hơn ngày hiện tại: báo lỗi tại trường ngày mua.
  - **3d.** Thiếu trường bắt buộc: đánh dấu đỏ trường thiếu (kiểm tra khi bấm tạo ở UC06 bước 2).
- **Liên quan:** FR02, BR02, BR11, NFR04.

#### UC03 – Nhập mô tả lỗi
- **Luồng chính:**
  1. Nhân viên nhập mô tả chi tiết tình trạng lỗi.
  2. Hệ thống đếm ký tự (tối đa 1000).
- **Luồng ngoại lệ:**
  - **1a.** Mô tả để trống: báo "Vui lòng nhập mô tả lỗi".
  - **2a.** Vượt 1000 ký tự: không cho nhập thêm.
- **Liên quan:** FR03, BR04.

#### UC04 – Phân loại nhóm sự cố
- **Luồng chính:**
  1. Hệ thống hiển thị danh sách nhóm sự cố.
  2. Nhân viên chọn một nhóm.
  3. Khung tóm tắt cập nhật nhóm sự cố đã chọn.
- **Luồng ngoại lệ:** **2a.** Chưa chọn nhóm: báo lỗi khi bấm tạo, không tạo yêu cầu.
- **Liên quan:** FR04, BR03.

#### UC05 – Xác định mức độ ưu tiên
- **Luồng chính:**
  1. Hệ thống hiển thị 4 mức ưu tiên kèm số giờ SLA.
  2. Nhân viên chọn một mức.
  3. Hệ thống hiển thị hạn cam kết dự kiến.
- **Luồng ngoại lệ:** **2a.** Chưa chọn mức ưu tiên: báo lỗi khi bấm tạo, không tạo yêu cầu.
- **Liên quan:** FR05, BR03.

#### UC06 – Tạo yêu cầu bảo hành và hạn cam kết xử lý
- **Tiền điều kiện:** UC01 thành công.
- **Luồng chính:**
  1. Nhân viên hoàn thành UC02–UC05 (có thể sửa họ tên khách hàng – FR10).
  2. Nhân viên bấm "Tạo yêu cầu bảo hành".
  3. Hệ thống kiểm tra toàn bộ dữ liệu bắt buộc.
  4. Hệ thống mở **một transaction**: cập nhật họ tên khách hàng nếu đổi; tìm hoặc tạo thiết bị; sinh mã `BH-YYYY-NNNNNN` có khóa chống trùng; đặt trạng thái "Mới tiếp nhận"; tính hạn cam kết = thời điểm tạo + số giờ SLA; ghi dòng lịch sử "Tiếp nhận yêu cầu".
  5. Hệ thống xác nhận transaction.
  6. Hệ thống hiển thị Phiếu tiếp nhận: mã yêu cầu, trạng thái, hạn cam kết.
- **Luồng ngoại lệ:**
  - **3a.** Thiếu / sai dữ liệu: báo lỗi tại từng trường, không tạo gì (BR04).
  - **4a.** Serial thuộc khách hàng khác hoặc lỗi khi lưu: hủy toàn bộ transaction, báo lỗi, không có dữ liệu dở dang.
  - **2a.** Nhân viên bấm "Hủy": quay về tra cứu, không lưu gì.
- **Hậu điều kiện:** Có đúng một yêu cầu mới, mã duy nhất, trạng thái "Mới tiếp nhận", có hạn cam kết và dòng lịch sử đầu tiên.
- **Liên quan:** FR06, FR07, FR10, BR01–BR06, NFR02, NFR04.

#### UC07 – Xem danh sách và trạng thái yêu cầu bảo hành
- **Luồng chính:**
  1. Quản lý chọn "Danh sách yêu cầu".
  2. Hệ thống hiển thị 4 thẻ thống kê (tổng yêu cầu hôm nay, mới tiếp nhận, đang xử lý, quá hạn) và danh sách 8 yêu cầu mỗi trang, mặc định mới tạo nhất trước.
  3. Quản lý tìm theo mã YC / tên KH / SĐT, lọc theo trạng thái (gồm Quá hạn, Đã hủy), nhóm sự cố, mức ưu tiên, khoảng ngày; chọn cách sắp xếp.
  4. Hệ thống trả về danh sách phù hợp; yêu cầu quá hạn được tô đỏ.
  5. Quản lý mở Phiếu tiếp nhận của một yêu cầu.
- **Luồng ngoại lệ:** **4a.** Không có yêu cầu phù hợp: hiển thị "Không có yêu cầu phù hợp với bộ lọc".
- **Liên quan:** FR08, BR10.
- **Ghi chú v2.0:** bỏ luồng ngoại lệ 2a (từ chối người không phải quản lý) vì đăng nhập nằm ngoài phạm vi (TD-11).

#### UC08 – Thông báo không tìm thấy khách hàng
- **Tiền điều kiện:** UC01 bước 5 không tìm thấy khách hàng.
- **Luồng chính:**
  1. Hệ thống hiển thị "Không tìm thấy khách hàng…" kèm từ khóa đã nhập (SĐT / mã / tên).
  2. Hệ thống không hiển thị nút tiếp tục tạo yêu cầu.
  3. Nhân viên bấm "Nhập lại" → quay lại UC01 bước 3.
- **Hậu điều kiện:** Không có yêu cầu nào được tạo.
- **Liên quan:** FR09, BR01, BR07.

#### UC09 – Cập nhật trạng thái yêu cầu
- **Tiền điều kiện:** Yêu cầu tồn tại và chưa đóng.
- **Luồng chính:**
  1. Người dùng mở Phiếu tiếp nhận.
  2. Hệ thống hiển thị các trạng thái được phép chuyển tiếp và lịch sử trạng thái.
  3. Người dùng bấm nút trạng thái mới ("Bắt đầu xử lý" hoặc "Hoàn tất") và xác nhận.
  4. Hệ thống khóa dòng yêu cầu, kiểm tra chuyển tiếp hợp lệ, cập nhật trạng thái (ghi thời điểm đóng nếu Hoàn tất), ghi dòng lịch sử – trong một transaction.
  5. Hệ thống hiển thị thông báo thành công và lịch sử mới.
- **Luồng ngoại lệ:**
  - **4a.** Chuyển sai thứ tự (VD Mới tiếp nhận → Hoàn tất): báo "Không thể chuyển từ … sang …", không đổi gì.
  - **4b.** Yêu cầu đã đóng (do người khác vừa đóng): báo "Yêu cầu đã đóng", không đổi gì.
- **Liên quan:** FR11, BR08, BR09, NFR04.

#### UC10 – Hủy yêu cầu bảo hành
- **Tiền điều kiện:** Yêu cầu chưa đóng.
- **Luồng chính:**
  1. Người dùng nhập lý do hủy trên Phiếu tiếp nhận.
  2. Người dùng bấm "Hủy yêu cầu" và xác nhận.
  3. Hệ thống chuyển trạng thái sang "Đã hủy", ghi thời điểm đóng và dòng lịch sử kèm lý do (như UC09 bước 4).
- **Luồng ngoại lệ:**
  - **2a.** Không nhập lý do: báo "Vui lòng nhập lý do hủy yêu cầu", không hủy.
  - **3a.** Yêu cầu đã đóng: báo lỗi, không hủy.
- **Hậu điều kiện:** Yêu cầu ở trạng thái Đã hủy, dữ liệu vẫn được giữ.
- **Liên quan:** FR12, BR08, BR09.

---

## 5. Yêu cầu chức năng

| Mã | Yêu cầu chức năng | US | UC | MoSCoW |
|---|---|---|---|---|
| FR01 | Hệ thống cho phép tra cứu khách hàng bằng số điện thoại, mã khách hàng hoặc họ tên (có dấu / không dấu), và kiểm tra tính hợp lệ của số điện thoại. | US1 | UC01 | MUST |
| FR02 | Hệ thống cho phép ghi nhận thông tin thiết bị và kiểm tra các trường bắt buộc. | US2 | UC02 | MUST |
| FR03 | Hệ thống cho phép nhập và lưu mô tả lỗi (1–1000 ký tự). | US3 | UC03 | SHOULD |
| FR04 | Hệ thống cho phép phân loại yêu cầu theo nhóm sự cố. | US4 | UC04 | SHOULD |
| FR05 | Hệ thống cho phép xác định và lưu mức độ ưu tiên. | US5 | UC05 | SHOULD |
| FR06 | Hệ thống cho phép tạo yêu cầu bảo hành và sinh mã yêu cầu duy nhất. | US6 | UC06 | MUST |
| FR07 | Hệ thống tự động tính và lưu hạn cam kết xử lý khi tạo yêu cầu thành công. | US6 | UC06 | MUST |
| FR08 | Hệ thống cho phép xem danh sách, thống kê và trạng thái các yêu cầu; tìm kiếm, lọc, sắp xếp, phân trang. | US7 | UC07 | SHOULD |
| FR09 | Hệ thống thông báo khi không tìm thấy khách hàng và không cho phép tiếp tục tạo yêu cầu. | US8 | UC08 | MUST |
| FR10 | Hệ thống cho phép cập nhật họ tên khách hàng khi tạo yêu cầu bảo hành. | US9 | UC06 | SHOULD |
| FR11 | Hệ thống cho phép cập nhật trạng thái yêu cầu theo đúng thứ tự và lưu lịch sử mỗi lần đổi. | US10 | UC09 | MUST |
| FR12 | Hệ thống cho phép hủy yêu cầu kèm lý do, không xóa dữ liệu. | US11 | UC10 | SHOULD |

Các chức năng FR06–FR08, FR11, FR12 được cung cấp cả qua giao diện web và qua API JSON (`docs/api-docs.md`).

---

## 6. Yêu cầu phi chức năng

| Mã | Yêu cầu | Ngưỡng | Cách hiện thực / kiểm chứng |
|---|---|---|---|
| NFR01 | Thời gian phản hồi khi tra cứu khách hàng | ≤ 2 giây | Chỉ mục UNIQUE trên `customers.phone`; kiểm tra định dạng trước khi truy vấn |
| NFR02 | Thời gian tạo yêu cầu và tính hạn cam kết | ≤ 3 giây | Một transaction; hạn cam kết tính tại server |
| NFR03 | Người dùng đồng thời | ≥ 50 | Puma đa luồng + connection pool; khóa chống trùng khi sinh mã |
| NFR04 | Toàn vẹn dữ liệu giữa khách hàng, thiết bị, yêu cầu | 0 yêu cầu được tạo khi thiếu dữ liệu bắt buộc; 0 thiết bị thuộc 2 khách hàng | Kiểm tra 2 lớp: validation ở Model + NOT NULL / UNIQUE / CHECK / FK ở PostgreSQL; transaction; khóa dòng khi đổi trạng thái |
| NFR05 | Kiểm soát quyền truy cập theo vai trò | **Ngoài phạm vi phiên bản này** (TD-11) | Hạn chế đã biết: mọi người dùng đều truy cập được mọi chức năng |
| NFR06 | Dễ sử dụng | Hoàn thành tiếp nhận một yêu cầu trên 2 màn hình, không cần thao tác ngoài luồng L2 | Thanh bước 1–2–3, khung tóm tắt cập nhật tức thì, thông báo lỗi tại từng trường |

---

## 7. Quy tắc nghiệp vụ

| Mã | Quy tắc | Mã cũ v1.0 |
|---|---|---|
| BR01 | Phải xác định được khách hàng trước khi tạo yêu cầu bảo hành. | QT-01, QT-02 |
| BR02 | Thông tin bắt buộc của thiết bị phải đầy đủ và hợp lệ (ngày mua không lớn hơn ngày hiện tại). | QT-03 |
| BR03 | Yêu cầu phải có nhóm sự cố và mức độ ưu tiên. | QT-05, QT-06 |
| BR04 | Không tạo yêu cầu khi thông tin bắt buộc thiếu hoặc không hợp lệ (bao gồm mô tả lỗi). | QT-04, QT-08 |
| BR05 | Mỗi yêu cầu có mã duy nhất dạng `BH-YYYY-NNNNNN` và trạng thái ban đầu "Mới tiếp nhận". Mã được sinh có khóa chống trùng khi tạo đồng thời (TD-17). | mới |
| BR06 | Hạn cam kết = thời điểm tạo + số giờ SLA của mức ưu tiên (Thấp 72h, Trung bình 48h, Cao 24h, Khẩn cấp 8h). | QT-07 |
| BR07 | Không tìm thấy khách hàng thì thông báo và không cho tiếp tục tạo yêu cầu. | mới |
| BR08 | Chuyển trạng thái chỉ theo thứ tự: Mới tiếp nhận → Đang xử lý → Hoàn tất; được hủy khi chưa hoàn tất; Hoàn tất / Đã hủy là đã đóng, không đổi được nữa. | mới |
| BR09 | Hủy yêu cầu bắt buộc có lý do; mọi lần đổi trạng thái đều ghi lịch sử (trạng thái cũ, mới, ghi chú, người đổi, thời điểm). | mới |
| BR10 | "Quá hạn" = yêu cầu chưa đóng và hạn cam kết nhỏ hơn hiện tại; tính khi truy vấn, không lưu. | mới |
| BR11 | Một thiết bị (số serial / IMEI) chỉ thuộc một khách hàng. | mới |

---

## 8. Bảng truy vết yêu cầu

| US | FR | UC | BR / NFR | Màn hình / API | Mã nguồn chính | Kiểm thử |
|---|---|---|---|---|---|---|
| US1 | FR01 | UC01 | BR01, NFR01 | Màn hình 1 | `CustomerLookupService` | `customer_lookup_test.rb` |
| US2 | FR02 | UC02 | BR02, BR11, NFR04 | Màn hình 2 · `POST /api/warranty_requests` | `WarrantyRequestForm`, `WarrantyRequestCreator` | `warranty_request_creation_test.rb`, `api_warranty_requests_test.rb` |
| US3 | FR03 | UC03 | BR04 | Màn hình 2 | `WarrantyRequestForm` | `warranty_request_creation_test.rb` |
| US4 | FR04 | UC04 | BR03 | Màn hình 2 | `WarrantyRequestForm` | `warranty_request_creation_test.rb` |
| US5 | FR05 | UC05 | BR03 | Màn hình 2 | `WarrantyRequestForm` | `warranty_request_creation_test.rb` |
| US6 | FR06, FR07 | UC06 | BR04–BR06, NFR02, NFR04 | Màn hình 2, Phiếu tiếp nhận · `POST /api/warranty_requests` | `WarrantyRequestCreator`, `RequestCodeGenerator`, `SlaDeadlineCalculator` | `warranty_request_creation_test.rb`, `request_code_generator_test.rb`, `sla_deadline_calculator_test.rb` |
| US7 | FR08 | UC07 | BR10 | Màn hình 3 · `GET /api/warranty_requests` | `WarrantyRequestSearch`, `WarrantyRequestStats` | `manager_warranty_requests_test.rb` |
| US8 | FR09 | UC08 | BR01, BR07 | Màn hình 1 | `CustomerLookupService` | `customer_lookup_test.rb` |
| US9 | FR10 | UC06 | BR01, NFR04 | Màn hình 2 | `WarrantyRequestCreator` | `warranty_request_creation_test.rb` |
| US10 | FR11 | UC09 | BR08, BR09, NFR04 | Phiếu tiếp nhận · `PATCH /api/warranty_requests/:id/status` | `WarrantyRequestStatusChanger` | `warranty_request_status_changer_test.rb`, `warranty_request_status_test.rb` |
| US11 | FR12 | UC10 | BR08, BR09 | Phiếu tiếp nhận · `PATCH …/status` | `WarrantyRequestStatusChanger` | `warranty_request_status_changer_test.rb`, `api_warranty_requests_test.rb` |

---

## Phụ lục C. Khai báo sử dụng công cụ AI

| Công cụ | Dùng vào việc gì | Áp dụng ở phần nào | Đã kiểm chứng thế nào |
|---|---|---|---|
| ChatGPT | Hỗ trợ gợi ý và diễn đạt User Story, tiêu chí chấp nhận và MoSCoW (v1.0). | Mục 2, Mục 3 | Đối chiếu từng User Story với phạm vi và dữ liệu của luồng L2; giữ lại các nội dung phù hợp với actor và nghiệp vụ. |
| ChatGPT | Hỗ trợ xây dựng danh sách Use Case, luồng chính, luồng ngoại lệ và quan hệ giữa các Use Case (v1.0). | Mục 4 | Đối chiếu UC01–UC08 với quy trình L2; kiểm tra actor, mục tiêu, các bước và quan hệ include / extend. |
| ChatGPT | Hỗ trợ diễn đạt yêu cầu chức năng, phi chức năng, quy tắc nghiệp vụ, bảng truy vết (v1.0). | Mục 5–8 | Đối chiếu FR với US và UC; kiểm tra NFR không đưa số liệu ngoài phạm vi L2. |
| Claude | Rà soát SRS v1.0 với báo cáo BT1 và mã nguồn; thống nhất bộ mã FR/BR; bổ sung FR10–FR12, UC09–UC10, BR08–BR11, đặc tả luồng ngoại lệ dạng 3a và bảng truy vết tới mã nguồn, kiểm thử (v2.0). | Toàn bộ v2.0 | Đối chiếu từng mã với `docs/thay-doi-thiet-ke.md`, mã nguồn trong `src/app` và bộ kiểm thử; chạy `bin/rails test` và `docs/scripts/goi-api.sh` (12 request trả đúng mã HTTP mong đợi). |

## Phụ lục E. Peer Review

- **Peer review với:** Võ Phạm Việt Phú – MSSV [ghi MSSV] (track SE)

- **Tóm tắt phạm vi bạn đọc đã trình bày lại sau 5 phút (ghi đúng lời bạn nói):**  
  Luồng L2 là tiếp nhận và phân loại yêu cầu bảo hành. Nhân viên tiếp nhận sẽ tra cứu khách hàng theo số điện thoại, ghi nhận thông tin thiết bị, nhập mô tả lỗi, phân loại nhóm sự cố, xác định mức độ ưu tiên và tạo yêu cầu bảo hành. Khi tạo yêu cầu, hệ thống tự động xác định hạn cam kết xử lý. Quản lý trung tâm có thể xem danh sách và trạng thái các yêu cầu bảo hành.

- **Đối chiếu với phạm vi gốc:**  
  [x] Đúng ☐ Đúng một phần ☐ Sai

- **Điểm bạn thấy chưa rõ hoặc mâu thuẫn:**  
  1. Cần làm rõ mối quan hệ giữa các Use Case trong quá trình tạo yêu cầu bảo hành, đặc biệt là quan hệ `<<include>>` giữa UC06 với UC01–UC05.
  2. Cần làm rõ trường hợp không tìm thấy khách hàng khi tra cứu bằng số điện thoại.

- **Tôi đã chỉnh sửa:**  
  1. Bổ sung bảng quan hệ giữa các Use Case và xác định UC06 là Use Case chính, sử dụng `<<include>>` với UC01, UC02, UC03, UC04 và UC05.
  2. Bổ sung UC08 – Thông báo không tìm thấy khách hàng và xác định quan hệ `<<extend>>` với UC01.
  3. Bổ sung luồng ngoại lệ theo từng bước (dạng 3a, 4a) cho mọi Use Case
