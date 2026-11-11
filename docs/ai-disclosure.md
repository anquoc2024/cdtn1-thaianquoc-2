# PHỤ LỤC: KHAI BÁO SỬ DỤNG CÔNG CỤ AI

| Công cụ | Phần áp dụng | Cách dùng (tóm tắt yêu cầu đã gửi) | Em đã chỉnh sửa / kiểm chứng gì |
|---|---|---|---|
| Trợ lý AI dạng chat (ChatGPT) | **Mục 1 – Bản SRS rút gọn** | Hỗ trợ xây dựng SRS rút gọn cho luồng L2 – Tiếp nhận và phân loại yêu cầu bảo hành, gồm yêu cầu chức năng, yêu cầu phi chức năng và quy tắc nghiệp vụ. | Chỉnh sửa nội dung theo phạm vi L2; rà soát mã FR, NFR, BR và bảng truy vết giữa User Story, yêu cầu chức năng và Use Case. |
| Trợ lý AI dạng chat (ChatGPT) | **Mục 2 – Use Case** | Hỗ trợ xác định các Use Case của quy trình tiếp nhận bảo hành và mô tả quan hệ `<<include>>` / `<<extend>>`. | Đối chiếu với các chức năng đã nêu trong SRS; rà soát vai trò của UC01–UC08 và điều kiện xảy ra UC08 khi không tìm thấy khách hàng. |
| Trợ lý AI dạng chat (ChatGPT) | **Mục 3 – Thiết kế kiến trúc** | Hỗ trợ trình bày kiến trúc MVC kết hợp Service Layer trong Ruby on Rails và PostgreSQL. | Điều chỉnh phần lập luận theo kiến trúc đã chọn; rà soát nội dung về phân tách thành phần, lưu trữ dữ liệu và hỗ trợ truy vấn. |
| Trợ lý AI dạng chat (ChatGPT) | **Mục 4 – Mô hình dữ liệu ERD và SQL** | Gợi ý mô hình dữ liệu cho hệ thống bảo hành, gồm các bảng, thuộc tính, khóa chính, khóa ngoại và mối quan hệ. | Đối chiếu các bảng với nghiệp vụ khách hàng, thiết bị, nhóm sự cố, mức ưu tiên và yêu cầu bảo hành; rà soát các quan hệ và ràng buộc dữ liệu trong mô hình đề xuất. |
| Trợ lý AI dạng chat (Claude) | **Mục 5 – Wireframe** | Hỗ trợ đề xuất bố cục giao diện Wireframe cho hệ thống tiếp nhận và phân loại yêu cầu bảo hành. | Kiểm tra và điều chỉnh bố cục giao diện theo yêu cầu nghiệp vụ, bảo đảm các thành phần phù hợp với luồng L2. Chỉ giữ nội dung này nếu thực tế có sử dụng Claude để hỗ trợ thiết kế. |
| Không sử dụng AI | **Mục 5 – Wireframe (nếu tự thực hiện)** | Wireframe được tự thiết kế và thực hiện mà không có sự hỗ trợ của công cụ AI. | Tự xây dựng, kiểm tra và điều chỉnh bố cục giao diện theo yêu cầu của hệ thống. Chỉ sử dụng dòng này nếu thực tế không dùng AI cho phần Wireframe. |
Tôi đã đọc, hiểu và chịu trách nhiệm về toàn bộ nội dung nôp.
Họ và tên: Thái An Quốc
MSSV: 2374802012635
Ngày: 29/10/2026


---

# PHỤ LỤC (cập nhật Bài tập 3 – giai đoạn 3, buổi 13–16): KHAI BÁO SỬ DỤNG CÔNG CỤ AI

| Công cụ | Dùng vào việc gì | Áp dụng ở tệp / hàm nào | Em đã kiểm chứng thế nào |
|---|---|---|---|
| Trợ lý AI dạng chat (ChatGPT) | Gợi ý test case và cách viết một mục Bug Log đủ 7 dòng | `docs/test-report.md`, `docs/bug-log.md` | Chỉ giữ test case em tự chạy được trên hệ thống thật; kết quả thực tế ghi từ log chạy thật; nguyên nhân của từng bug em đối chiếu với mã nguồn và bản sửa |
| Trợ lý AI dạng chat (Claude) | Chọn 16 test case theo chức năng, viết script chạy và chụp từng test case; viết test chống SQL injection | `docs/test-plan.md`, `docs/test-report.md`, `scripts/tc.sh`, `scripts/chup-tc.sh`, `src/test/integration/customer_lookup_test.rb` | Tự chạy cả 16 test case, chụp 16 ảnh `docs/screenshots/TC-xx.png`; điền P/F theo `docs/tc-ket-qua.txt`; `bin/rails test` 131 runs, 0 failures |
| Trợ lý AI dạng chat (Claude) | Tìm nguyên nhân bug, viết bản sửa và test hồi quy | `Api::BaseController` (BUG-07), `db/seeds.rb` + `seeds_output_test.rb` (BUG-08), `Gemfile.lock` (BUG-06), `.gitattributes` (BUG-09), `warranty_request_edit_test.rb` (BUG-05) | Tự tái lập lỗi trước khi sửa (ảnh `BUG-0x-truoc.png`), chạy lại test sau khi sửa; mỗi bug một commit `fix(...)` riêng, mở lại link commit để kiểm |
| Trợ lý AI dạng chat (Claude) | Viết gói Docker và Deployment Guide tiếng Anh | `Dockerfile`, `docker-compose.yml`, `.dockerignore`, `.env.example`, `src/bin/docker-entrypoint`, `src/config/database.yml`, `docs/deployment-guide.md` | Tự cài Docker Engine trong WSL, chạy phép thử máy trắng theo tag `v1.0-rc1` và `v1.0`; mọi số liệu trong Guide (thời gian build, số bản ghi, kết quả test) lấy từ lần chạy thật |
| Trợ lý AI dạng chat (Claude) | Viết script tự kiểm 7 mục checklist bảo mật | `scripts/kiem-bao-mat.sh`, `docs/checklist-bao-mat.md` | Tự chạy script, chụp ảnh từng mục; phát hiện và sửa BUG-06, 07, 08; ghi trung thực phần chưa làm (API token không hết hạn) |
| Trợ lý AI dạng chat (Claude) | Viết script gọi 46 request và tài liệu API tiếng Anh | `docs/scripts/goi-api-docker.sh`, `docs/api-examples.md`, `docs/api-docs.md` | Tự chạy script trên Docker (46/46 đúng mã HTTP); ví dụ trong tài liệu chép nguyên từ kết quả chạy; kiểm tra tệp không lộ token |

Tôi đã đọc, hiểu và chịu trách nhiệm về toàn bộ nội dung nộp ở Bài tập 3.
Họ và tên: Thái An Quốc · MSSV: 2374802012635
