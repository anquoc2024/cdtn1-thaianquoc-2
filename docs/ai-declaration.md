# PHỤ LỤC: KHAI BÁO SỬ DỤNG CÔNG CỤ AI

| Công cụ | Phần áp dụng | Cách dùng (tóm tắt yêu cầu đã gửi) | Em đã chỉnh sửa / kiểm chứng gì |
|---|---|---|---|
| Trợ lý AI dạng chat (ChatGPT) | **Mục 1 – Bản SRS rút gọn** | Hỗ trợ xây dựng SRS rút gọn cho luồng L2 – Tiếp nhận và phân loại yêu cầu bảo hành, gồm yêu cầu chức năng, yêu cầu phi chức năng và quy tắc nghiệp vụ. | Chỉnh sửa nội dung theo phạm vi L2; rà soát mã FR, NFR, BR và bảng truy vết giữa User Story, yêu cầu chức năng và Use Case. |
| Trợ lý AI dạng chat (ChatGPT) | **Mục 2 – Use Case** | Hỗ trợ xác định các Use Case của quy trình tiếp nhận bảo hành và mô tả quan hệ `<<include>>` / `<<extend>>`. | Đối chiếu với các chức năng đã nêu trong SRS; rà soát vai trò của UC01–UC08 và điều kiện xảy ra UC08 khi không tìm thấy khách hàng. |
| Trợ lý AI dạng chat (ChatGPT) | **Mục 3 – Thiết kế kiến trúc** | Hỗ trợ trình bày kiến trúc MVC kết hợp Service Layer trong Ruby on Rails và PostgreSQL. | Điều chỉnh phần lập luận theo kiến trúc đã chọn; rà soát nội dung về phân tách thành phần, lưu trữ dữ liệu và hỗ trợ truy vấn. |
| Trợ lý AI dạng chat (ChatGPT) | **Mục 4 – Mô hình dữ liệu ERD và SQL** | Gợi ý mô hình dữ liệu cho hệ thống bảo hành, gồm các bảng, thuộc tính, khóa chính, khóa ngoại và mối quan hệ. | Đối chiếu các bảng với nghiệp vụ khách hàng, thiết bị, nhóm sự cố, mức ưu tiên và yêu cầu bảo hành; rà soát các quan hệ và ràng buộc dữ liệu trong mô hình đề xuất. |
| Trợ lý AI dạng chat (Claude) | **Mục 5 – Wireframe** | Hỗ trợ đề xuất bố cục giao diện Wireframe cho hệ thống tiếp nhận và phân loại yêu cầu bảo hành. | Kiểm tra và điều chỉnh bố cục giao diện theo yêu cầu nghiệp vụ, bảo đảm các thành phần phù hợp với luồng L2. Chỉ giữ nội dung này nếu thực tế có sử dụng Claude để hỗ trợ thiết kế. |
| Không sử dụng AI | **Mục 5 – Wireframe (nếu tự thực hiện)** | Wireframe được tự thiết kế và thực hiện mà không có sự hỗ trợ của công cụ AI. | Tự xây dựng, kiểm tra và điều chỉnh bố cục giao diện theo yêu cầu của hệ thống. Chỉ sử dụng dòng này nếu thực tế không dùng AI cho phần Wireframe. |

