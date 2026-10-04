from pathlib import Path

content = r"""# ĐẶC TẢ YÊU CẦU PHẦN MỀM (SRS)

**Luồng nghiệp vụ:** L2 – Tiếp nhận và phân loại yêu cầu bảo hành  
**Sinh viên:** Thai An Quoc  
**MSSV:** 2374802012635  
**Track:** Công nghệ Phần mềm (SE)

---

## 1. Thông tin và phạm vi

### 1.1. Mục tiêu

Hệ thống hỗ trợ nhân viên tiếp nhận trong việc tiếp nhận và phân loại yêu cầu bảo hành. Quy trình tập trung vào việc xác định khách hàng, ghi nhận thiết bị, ghi nhận lỗi, phân loại nhóm sự cố, xác định mức độ ưu tiên và tạo yêu cầu bảo hành.

Sau khi tạo yêu cầu, hệ thống tự động xác định hạn cam kết xử lý. Quản lý trung tâm có thể xem danh sách và trạng thái các yêu cầu để theo dõi tình hình tiếp nhận tại trung tâm.

### 1.2. Phạm vi

Luồng L2 bao gồm:

- Tra cứu khách hàng bằng số điện thoại.
- Ghi nhận thông tin thiết bị cần bảo hành.
- Nhập mô tả lỗi của thiết bị.
- Phân loại nhóm sự cố.
- Xác định mức độ ưu tiên.
- Tạo yêu cầu bảo hành.
- Tự động xác định hạn cam kết xử lý.
- Xem danh sách và trạng thái yêu cầu bảo hành.
- Thông báo khi không tìm thấy khách hàng.

### 1.3. Đối tượng sử dụng

| Actor | Vai trò |
|---|---|
| Nhân viên tiếp nhận | Tiếp nhận, ghi nhận và phân loại yêu cầu bảo hành. |
| Quản lý trung tâm | Theo dõi danh sách và trạng thái các yêu cầu bảo hành. |

### 1.4. Dữ liệu chính

| Dữ liệu | Mục đích |
|---|---|
| `customer` | Lưu thông tin khách hàng. |
| `device` | Lưu thông tin thiết bị của khách hàng. |
| `ticket` | Lưu yêu cầu bảo hành. |
| `issue_category` | Lưu nhóm sự cố. |
| `ticket_status_log` | Lưu lịch sử trạng thái của yêu cầu. |

---

## 2. User Story

| Mã | Actor | User Story | Ưu tiên |
|---|---|---|---|
| US1 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn tra cứu khách hàng theo số điện thoại để nhanh chóng xác định thông tin khách hàng trước khi tiếp nhận yêu cầu bảo hành. | MUST |
| US2 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn ghi nhận thông tin thiết bị của khách hàng để xác định chính xác thiết bị cần được bảo hành. | MUST |
| US3 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn nhập mô tả lỗi của thiết bị để ghi nhận chính xác vấn đề khách hàng đang gặp phải và cung cấp thông tin cho quá trình xử lý bảo hành. | SHOULD |
| US4 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn phân loại nhóm sự cố của thiết bị để yêu cầu bảo hành được ghi nhận theo đúng loại vấn đề và thuận tiện cho quá trình xử lý. | SHOULD |
| US5 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn xác định mức độ ưu tiên của yêu cầu bảo hành để hỗ trợ trung tâm phân loại và sắp xếp thứ tự xử lý phù hợp. | SHOULD |
| US6 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn tạo yêu cầu bảo hành và được hệ thống tự động xác định hạn cam kết xử lý để có thể theo dõi thời hạn hoàn thành yêu cầu của khách hàng. | MUST |
| US7 | Quản lý trung tâm | Là quản lý trung tâm, tôi muốn xem danh sách và trạng thái các yêu cầu bảo hành để theo dõi tình hình tiếp nhận và nắm được tiến độ xử lý yêu cầu tại trung tâm. | SHOULD |
| US8 | Nhân viên tiếp nhận | Là nhân viên tiếp nhận, tôi muốn hệ thống thông báo khi không tìm thấy khách hàng theo số điện thoại để biết khách hàng chưa có thông tin trong hệ thống và có hướng xử lý phù hợp. | SHOULD |

---

## 3. Tiêu chí chấp nhận

### 3.1. US1 – Tra cứu khách hàng

**AC1.1 – Tra cứu thành công**

- **Given:** Nhân viên tiếp nhận đã đăng nhập và đang ở chức năng tra cứu khách hàng.
- **When:** Nhân viên nhập số điện thoại hợp lệ của khách hàng đã tồn tại.
- **Then:** Hệ thống hiển thị thông tin tương ứng của khách hàng.

**AC1.2 – Không tìm thấy khách hàng**

- **Given:** Nhân viên đang thực hiện tra cứu khách hàng.
- **When:** Nhân viên nhập số điện thoại không tồn tại trong hệ thống.
- **Then:** Hệ thống thông báo không tìm thấy khách hàng và không hiển thị thông tin khách hàng không tồn tại.

### 3.2. US2 – Ghi nhận thông tin thiết bị

**AC2.1 – Ghi nhận thành công**

- **Given:** Khách hàng đã được xác định.
- **When:** Nhân viên nhập đầy đủ và hợp lệ thông tin thiết bị.
- **Then:** Hệ thống ghi nhận và hiển thị thông tin thiết bị.

**AC2.2 – Thiếu thông tin thiết bị**

- **Given:** Nhân viên đang nhập thông tin thiết bị.
- **When:** Một hoặc nhiều thông tin bắt buộc chưa được nhập.
- **Then:** Hệ thống thông báo thông tin còn thiếu và yêu cầu nhân viên bổ sung trước khi tiếp tục.

### 3.3. US6 – Tạo yêu cầu bảo hành và hạn cam kết

**AC6.1 – Tạo yêu cầu thành công**

- **Given:** Thông tin khách hàng, thiết bị, mô tả lỗi, nhóm sự cố và mức độ ưu tiên đã đầy đủ.
- **When:** Nhân viên xác nhận tạo yêu cầu bảo hành.
- **Then:** Hệ thống tạo yêu cầu bảo hành và tự động xác định hạn cam kết xử lý.

**AC6.2 – Thông tin tạo yêu cầu không hợp lệ**

- **Given:** Nhân viên đang tạo yêu cầu bảo hành.
- **When:** Thông tin bắt buộc bị thiếu hoặc không hợp lệ.
- **Then:** Hệ thống thông báo lỗi, không tạo yêu cầu và yêu cầu nhân viên bổ sung hoặc chỉnh sửa thông tin.

---

## 4. Use Case

### 4.1. Danh sách Use Case

| Mã | Tên Use Case | Actor chính | Mục tiêu | Ưu tiên | Ngoại lệ |
|---|---|---|---|---|---:|
| UC01 | Tra cứu khách hàng | Nhân viên tiếp nhận | Tra cứu và xác định thông tin khách hàng theo số điện thoại. | MUST | 2 |
| UC02 | Ghi nhận thông tin thiết bị | Nhân viên tiếp nhận | Ghi nhận chính xác thiết bị cần bảo hành. | MUST | 1 |
| UC03 | Nhập mô tả lỗi | Nhân viên tiếp nhận | Ghi nhận vấn đề của thiết bị. | SHOULD | 1 |
| UC04 | Phân loại nhóm sự cố | Nhân viên tiếp nhận | Phân loại yêu cầu theo nhóm sự cố. | SHOULD | 1 |
| UC05 | Xác định mức độ ưu tiên | Nhân viên tiếp nhận | Xác định mức độ ưu tiên xử lý yêu cầu. | SHOULD | 1 |
| UC06 | Tạo yêu cầu bảo hành và hạn cam kết xử lý | Nhân viên tiếp nhận | Tạo yêu cầu và xác định hạn cam kết xử lý. | MUST | 3 |
| UC07 | Xem danh sách và trạng thái yêu cầu bảo hành | Quản lý trung tâm | Theo dõi tình hình và trạng thái yêu cầu. | SHOULD | 1 |
| UC08 | Thông báo không tìm thấy khách hàng | Hệ thống | Thông báo khi không tìm thấy khách hàng theo số điện thoại. | SHOULD | 0 |

### 4.2. Luồng chính

| Use Case | Bước | Tác nhân | Mô tả |
|---|---:|---|---|
| UC01 | 1 | Nhân viên tiếp nhận | Chọn chức năng tra cứu khách hàng. |
| UC01 | 2 | Nhân viên tiếp nhận | Nhập số điện thoại khách hàng. |
| UC01 | 3 | Hệ thống | Kiểm tra tính hợp lệ của số điện thoại. |
| UC01 | 4 | Hệ thống | Tìm kiếm khách hàng theo số điện thoại. |
| UC01 | 5 | Hệ thống | Hiển thị thông tin khách hàng tìm thấy. |
| UC01 | 6 | Nhân viên tiếp nhận | Kiểm tra và xác nhận thông tin khách hàng. |
| UC02 | 1 | Nhân viên tiếp nhận | Chọn khách hàng đã được xác định từ UC01. |
| UC02 | 2 | Nhân viên tiếp nhận | Nhập thông tin thiết bị cần bảo hành. |
| UC02 | 3 | Hệ thống | Kiểm tra tính đầy đủ và hợp lệ của thông tin thiết bị. |
| UC02 | 4 | Hệ thống | Ghi nhận thông tin thiết bị của khách hàng. |
| UC02 | 5 | Hệ thống | Hiển thị thông tin thiết bị đã ghi nhận. |
| UC03 | 1 | Nhân viên tiếp nhận | Chọn thiết bị cần bảo hành từ UC02. |
| UC03 | 2 | Nhân viên tiếp nhận | Nhập mô tả lỗi của thiết bị. |
| UC03 | 3 | Hệ thống | Kiểm tra nội dung mô tả lỗi. |
| UC03 | 4 | Hệ thống | Lưu mô tả lỗi của thiết bị. |
| UC03 | 5 | Hệ thống | Hiển thị thông tin lỗi đã được ghi nhận. |
| UC04 | 1 | Nhân viên tiếp nhận | Xem thông tin mô tả lỗi từ UC03. |
| UC04 | 2 | Nhân viên tiếp nhận | Chọn nhóm sự cố phù hợp. |
| UC04 | 3 | Hệ thống | Kiểm tra nhóm sự cố được lựa chọn. |
| UC04 | 4 | Hệ thống | Lưu nhóm sự cố cho yêu cầu bảo hành. |
| UC04 | 5 | Hệ thống | Hiển thị nhóm sự cố đã được xác định. |
| UC05 | 1 | Nhân viên tiếp nhận | Xem thông tin yêu cầu và nhóm sự cố từ UC04. |
| UC05 | 2 | Nhân viên tiếp nhận | Đánh giá tình trạng yêu cầu bảo hành. |
| UC05 | 3 | Nhân viên tiếp nhận | Chọn mức độ ưu tiên. |
| UC05 | 4 | Hệ thống | Kiểm tra mức độ ưu tiên được lựa chọn. |
| UC05 | 5 | Hệ thống | Lưu mức độ ưu tiên cho yêu cầu bảo hành. |
| UC05 | 6 | Hệ thống | Hiển thị mức độ ưu tiên đã xác định. |
| UC06 | 1 | Nhân viên tiếp nhận | Chọn chức năng tạo yêu cầu bảo hành. |
| UC06 | 2 | Nhân viên tiếp nhận | Tra cứu và xác định khách hàng theo số điện thoại (UC01). |
| UC06 | 3 | Nhân viên tiếp nhận | Ghi nhận thông tin thiết bị (UC02). |
| UC06 | 4 | Nhân viên tiếp nhận | Nhập mô tả lỗi (UC03). |
| UC06 | 5 | Nhân viên tiếp nhận | Chọn nhóm sự cố (UC04). |
| UC06 | 6 | Nhân viên tiếp nhận | Xác định mức độ ưu tiên (UC05). |
| UC06 | 7 | Nhân viên tiếp nhận | Xác nhận tạo yêu cầu bảo hành. |
| UC06 | 8 | Hệ thống | Kiểm tra tính đầy đủ và hợp lệ của thông tin. |
| UC06 | 9 | Hệ thống | Tạo yêu cầu bảo hành và thiết lập trạng thái ban đầu. |
| UC06 | 10 | Hệ thống | Tự động xác định hạn cam kết xử lý. |
| UC06 | 11 | Hệ thống | Lưu yêu cầu bảo hành cùng hạn cam kết. |
| UC06 | 12 | Hệ thống | Thông báo tạo yêu cầu thành công. |
| UC07 | 1 | Quản lý trung tâm | Chọn chức năng xem danh sách yêu cầu bảo hành. |
| UC07 | 2 | Hệ thống | Truy xuất danh sách các yêu cầu bảo hành. |
| UC07 | 3 | Hệ thống | Hiển thị danh sách yêu cầu bảo hành. |
| UC07 | 4 | Quản lý trung tâm | Xem thông tin và trạng thái các yêu cầu. |
| UC07 | 5 | Hệ thống | Hiển thị trạng thái tương ứng của từng yêu cầu. |
| UC08 | 1 | Hệ thống | Phát hiện không tìm thấy khách hàng theo số điện thoại. |
| UC08 | 2 | Hệ thống | Hiển thị thông báo không tìm thấy khách hàng. |

### 4.3. Luồng ngoại lệ

| Mã | Tình huống ngoại lệ | Xử lý của hệ thống |
|---|---|---|
| E1 | Không tìm thấy khách hàng theo số điện thoại. | Thông báo không tìm thấy khách hàng và yêu cầu kiểm tra lại thông tin. |
| E2 | Số điện thoại không hợp lệ. | Thông báo số điện thoại không hợp lệ và yêu cầu nhập lại. |
| E3 | Thiếu thông tin thiết bị bắt buộc. | Thông báo thông tin còn thiếu và yêu cầu bổ sung. |
| E4 | Chưa nhập mô tả lỗi. | Thông báo yêu cầu nhập mô tả lỗi. |
| E5 | Chưa chọn nhóm sự cố. | Thông báo yêu cầu chọn nhóm sự cố. |
| E6 | Chưa xác định mức độ ưu tiên. | Thông báo yêu cầu xác định mức độ ưu tiên. |
| E7 | Thiếu thông tin bắt buộc khi tạo yêu cầu. | Hiển thị thông tin cần bổ sung và yêu cầu cập nhật. |
| E8 | Thông tin yêu cầu không hợp lệ. | Hiển thị lỗi và yêu cầu chỉnh sửa thông tin. |
| E9 | Lỗi khi lưu yêu cầu bảo hành. | Thông báo tạo yêu cầu thất bại và không ghi nhận yêu cầu chưa hoàn tất. |
| E10 | Không có yêu cầu bảo hành để hiển thị. | Thông báo danh sách hiện chưa có yêu cầu bảo hành. |

### 4.4. Quan hệ giữa các Use Case

| Use Case | Quan hệ | Mô tả |
|---|---|---|
| UC01 – Tra cứu khách hàng | `<<include>>` | Bắt buộc tra cứu và xác định khách hàng theo số điện thoại khi tạo yêu cầu bảo hành. |
| UC02 – Ghi nhận thông tin thiết bị | `<<include>>` | Ghi nhận thông tin thiết bị cần được bảo hành. |
| UC03 – Nhập mô tả lỗi | `<<include>>` | Ghi nhận mô tả vấn đề của thiết bị cần bảo hành. |
| UC04 – Phân loại nhóm sự cố | `<<include>>` | Xác định nhóm sự cố của yêu cầu bảo hành. |
| UC05 – Xác định mức độ ưu tiên | `<<include>>` | Xác định mức độ ưu tiên để hỗ trợ sắp xếp thứ tự xử lý. |
| UC06 – Tạo yêu cầu bảo hành và hạn cam kết xử lý | Use Case chính | Tạo yêu cầu bảo hành và tự động xác định hạn cam kết xử lý. |
| UC07 – Xem danh sách và trạng thái yêu cầu bảo hành | Độc lập | Quản lý trung tâm theo dõi danh sách và trạng thái các yêu cầu. |
| UC08 – Thông báo không tìm thấy khách hàng | `<<extend>>` UC01 | Chỉ xảy ra khi hệ thống không tìm thấy khách hàng theo số điện thoại. |

---

## 5. Yêu cầu chức năng

| Mã | Yêu cầu chức năng | Liên kết |
|---|---|---|
| FR-01 | Hệ thống cho phép nhân viên tiếp nhận tra cứu thông tin khách hàng bằng số điện thoại. | US1 / UC01 |
| FR-02 | Hệ thống cho phép nhân viên tiếp nhận ghi nhận thông tin thiết bị của khách hàng cần bảo hành. | US2 / UC02 |
| FR-03 | Hệ thống cho phép nhân viên tiếp nhận nhập và lưu mô tả lỗi của thiết bị. | US3 / UC03 |
| FR-04 | Hệ thống cho phép nhân viên tiếp nhận phân loại yêu cầu theo nhóm sự cố. | US4 / UC04 |
| FR-05 | Hệ thống cho phép nhân viên tiếp nhận xác định mức độ ưu tiên của yêu cầu bảo hành. | US5 / UC05 |
| FR-06 | Hệ thống cho phép nhân viên tiếp nhận tạo yêu cầu bảo hành và tự động xác định hạn cam kết xử lý. | US6 / UC06 |
| FR-07 | Hệ thống cho phép quản lý trung tâm xem danh sách và trạng thái các yêu cầu bảo hành. | US7 / UC07 |
| FR-08 | Hệ thống thông báo cho nhân viên tiếp nhận khi không tìm thấy khách hàng theo số điện thoại được nhập. | US8 / UC08 |

---

## 6. Yêu cầu phi chức năng

> Các ngưỡng dưới đây là tiêu chí đề xuất cho SRS của luồng L2, không phải số liệu lấy từ file mẫu.

| Mã | Yêu cầu | Ngưỡng/tiêu chí |
|---|---|---|
| NFR-01 | Hiệu năng tra cứu khách hàng | Kết quả tra cứu được trả về trong không quá 2 giây trong điều kiện hoạt động bình thường. |
| NFR-02 | Hiệu năng tạo yêu cầu | Tạo yêu cầu và xác định hạn cam kết hoàn thành trong không quá 3 giây sau khi dữ liệu hợp lệ. |
| NFR-03 | Khả năng phục vụ đồng thời | Hỗ trợ ít nhất 50 người dùng đồng thời trong phạm vi chức năng L2. |
| NFR-04 | Toàn vẹn dữ liệu | Yêu cầu bảo hành phải liên kết đúng với khách hàng, thiết bị, nhóm sự cố và thông tin liên quan. |
| NFR-05 | Phân quyền | Nhân viên tiếp nhận và quản lý trung tâm chỉ được thực hiện các chức năng phù hợp với vai trò. |
| NFR-06 | Dễ sử dụng | Giao diện hỗ trợ nhân viên hoàn thành quy trình tiếp nhận và phân loại mà không yêu cầu thao tác ngoài phạm vi L2. |

---

## 7. Quy tắc nghiệp vụ

| Mã | Quy tắc |
|---|---|
| QT-01 | Khách hàng được xác định bằng số điện thoại khi thực hiện tra cứu. |
| QT-02 | Không được tiếp tục quy trình khi chưa xác định được khách hàng. |
| QT-03 | Thông tin thiết bị bắt buộc phải được ghi nhận trước khi tạo yêu cầu bảo hành. |
| QT-04 | Yêu cầu bảo hành phải có mô tả lỗi. |
| QT-05 | Yêu cầu bảo hành phải được phân loại theo nhóm sự cố. |
| QT-06 | Yêu cầu bảo hành phải có mức độ ưu tiên trước khi được tạo hoàn chỉnh. |
| QT-07 | Khi tạo yêu cầu thành công, hệ thống tự động xác định hạn cam kết xử lý. |
| QT-08 | Nếu dữ liệu bắt buộc thiếu hoặc không hợp lệ, hệ thống không tạo yêu cầu bảo hành hoàn chỉnh. |

---

## 8. Bảng truy vết yêu cầu

| User Story | Functional Requirement | Use Case | NFR liên quan |
|---|---|---|---|
| US1 | FR-01 | UC01 | NFR-01, NFR-05 |
| US2 | FR-02 | UC02 | NFR-04, NFR-05 |
| US3 | FR-03 | UC03 | NFR-04, NFR-05 |
| US4 | FR-04 | UC04 | NFR-04, NFR-05 |
| US5 | FR-05 | UC05 | NFR-04, NFR-05 |
| US6 | FR-06 | UC06 | NFR-02, NFR-04, NFR-05 |
| US7 | FR-07 | UC07 | NFR-05, NFR-06 |
| US8 | FR-08 | UC08 | NFR-05, NFR-06 |

---

## 11. Phụ lục C. Khai báo sử dụng công cụ AI

| Công cụ | Dùng vào việc gì | Áp dụng ở phần nào | Đã kiểm chứng thế nào |
|---|---|---|---|
| ChatGPT | Hỗ trợ gợi ý và diễn đạt User Story, Acceptance Criteria và MoSCoW. | Mục 2, Mục 3 | Đối chiếu từng User Story với phạm vi và dữ liệu của luồng L2; giữ lại các nội dung phù hợp với actor và nghiệp vụ đã xác định. |
| ChatGPT | Hỗ trợ xây dựng danh sách Use Case, luồng chính, luồng ngoại lệ và quan hệ giữa các Use Case. | Mục 4 | Đối chiếu UC01–UC08 với quy trình L2; kiểm tra lại actor, mục tiêu, các bước xử lý và quan hệ `include` / `extend`. |
| ChatGPT | Hỗ trợ diễn đạt yêu cầu chức năng, yêu cầu phi chức năng và quy tắc nghiệp vụ. | Mục 5, Mục 6, Mục 7 | Đối chiếu FR với từng User Story và Use Case; kiểm tra NFR để không đưa các số liệu không có trong dữ liệu L2. |
| ChatGPT | Hỗ trợ lập bảng truy vết yêu cầu. | Mục 8 | Kiểm tra quan hệ US → FR → UC → NFR để bảo đảm mỗi yêu cầu chức năng có nguồn truy vết rõ ràng. |

## Phụ lục E. Peer review
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
  3. Bổ sung các luồng ngoại lệ E1–E10 để mô tả cách hệ thống xử lý các trường hợp dữ liệu thiếu, không hợp lệ hoặc không tìm thấy thông tin.