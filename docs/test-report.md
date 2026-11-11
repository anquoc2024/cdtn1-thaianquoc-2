# Test Report — Luồng L2: Tiếp nhận và phân loại yêu cầu bảo hành

Thái An Quốc – 2374802012635 · Commit chạy test: `47593cf` · Ngày chạy: 10/11/2026

16 test case trình bày **theo chức năng** người dùng thấy: đăng nhập / đăng xuất, tra cứu khách hàng, thêm khách hàng,
tạo yêu cầu, danh sách yêu cầu, cập nhật trạng thái, sửa / xóa yêu cầu, phân quyền, nạp dữ liệu.
Chạy lại bất kỳ test case nào: `bash scripts/tc.sh TC-xx`. Ảnh chụp từng lần chạy: `docs/screenshots/TC-xx.png`.

**Tổng kết:** đã chạy thật 16 / 16 · PASS 16 · FAIL 0 · Bộ test tự động (`bin/rails test`): 129 runs, 578 assertions, 0 failures, 0 errors

Nhật ký chữ của lần chạy: `docs/tc-ket-qua.txt` (sinh bởi `bash scripts/chup-tc.sh`).

> Bảng đủ 8 cột theo đề: mã · tiền điều kiện · các bước · dữ liệu thử · kết quả mong đợi · mức ưu tiên · kết quả thực tế ·
> PASS/FAIL. Cột mã ghi kèm chức năng, loại test và quy tắc / yêu cầu được truy vết (bảng truy vết đầy đủ: `docs/test-plan.md`).
> Kết quả thực tế chép từ lần chạy thật (`docs/tc-ket-qua.txt`), không chép lại cột mong đợi.

| Mã · chức năng · loại · truy vết | Tiền điều kiện | Các bước | Dữ liệu thử | Kết quả mong đợi | Ưu tiên | Kết quả thực tế | P/F |
|---|---|---|---|---|---|---|---|
| **TC-01** · Đăng nhập · luồng đúng · *NFR05* | 2 tài khoản `quoc@mekong.vn` (Nhân viên tiếp nhận) và `phu@mekong.vn` (Quản lý) — dựng trong test | 1. `bash scripts/tc.sh TC-01` (đăng nhập Nhân viên → đăng xuất → đăng nhập Quản lý) | Mật khẩu đúng của từng tài khoản | Nhân viên được chuyển tới **Tra cứu khách hàng**; Quản lý tới **Danh sách yêu cầu** | Cao | 1 runs, 6 assertions, 0 failures – Nhân viên vào Tra cứu khách hàng, Quản lý vào Danh sách yêu cầu | PASS |
| **TC-02** · Đăng nhập · dữ liệu sai · *NFR05* | Tài khoản `quoc@mekong.vn` tồn tại | 1. `bash scripts/tc.sh TC-02` | Mật khẩu `sai-mat-khau` | `422`, ở lại trang đăng nhập, báo "Email hoặc mật khẩu không đúng."; số phiên (Session) KHÔNG tăng | Cao | 1 runs, 5 assertions, 0 failures – 422, báo lỗi, số phiên không tăng | PASS |
| **TC-03** · Tra cứu khách hàng · luồng đúng · *UC01, BR01* | Khách `KH-900001` "Nguyễn Văn Test", SĐT `0909000111` | 1. `bash scripts/tc.sh TC-03` | `q = "0909 000 111"` (có dấu cách) | Hiện đúng 1 khách "Nguyễn Văn Test", có nút tạo yêu cầu cho khách đó | Cao | 1 runs, 3 assertions, 0 failures – tìm thấy đúng "Nguyễn Văn Test" | PASS |
| **TC-04** · Tra cứu khách hàng · luồng ngoại lệ UC08 · *UC08, BR07* | Như TC-03 | 1. `bash scripts/tc.sh TC-04` | `0912000111`, `KH-000999`, `Không Có Ai` | Mỗi lần: khung "không tìm thấy" có lặp lại từ khóa; KHÔNG có khách nào, không có nút tiếp tục | Cao | 1 runs, 12 assertions, 0 failures – cả 3 từ khóa đều hiện khung không tìm thấy, không có khách | PASS |
| **TC-05** · Thêm khách hàng · giá trị biên (trong vùng) · *BR12* | `db:reset`; server đang chạy; đăng nhập `quoc@mekong.vn` | 1. Đếm khách. 2. `POST /api/customers`. 3. Đếm lại (`bash scripts/tc.sh TC-05`) | `phone` đúng **10** chữ số, bắt đầu bằng 0 | `201 Created`, mã `KH-0NNNNN`; số khách **+1** | Cao | Trước 310 → `HTTP/1.1 201 Created`, mã `KH-000001`, phone `0994316007` → sau 311 (+1) | PASS |
| **TC-06** · Thêm khách hàng · giá trị biên (ngoài vùng) · *BR01* | Như TC-05 | 1. Đếm khách. 2. `POST /api/customers`. 3. Đếm lại (`bash scripts/tc.sh TC-06`) | `phone = 091234567` (**9** chữ số) | `400 DU_LIEU_KHONG_HOP_LE`, `cac_truong` có `phone`; số khách KHÔNG đổi | Cao | Trước 311 → `HTTP/1.1 400 Bad Request`, `DU_LIEU_KHONG_HOP_LE`, `phone`: "phải gồm 10 chữ số, bắt đầu bằng 0" → sau 311 (không đổi) | PASS |
| **TC-07** · Tạo yêu cầu bảo hành · luồng đúng (BR05, BR06) · *BR01, BR03, BR05, BR06* | Khách `KH-900001`; nhóm sự cố; mức ưu tiên Cao 24h | 1. `bash scripts/tc.sh TC-07` (gửi form Màn hình 2) | Điện thoại Samsung Galaxy A55, serial `SN-NEW-001`, mô tả "Máy không lên nguồn" | Yêu cầu +1, thiết bị +1; mã `BH-YYYY-000001`; trạng thái **Mới tiếp nhận**; hạn = lúc tạo + 24h; chuyển tới Phiếu tiếp nhận | Cao | 1 runs, 13 assertions, 0 failures – mã BH, Mới tiếp nhận, hạn +24h, về Phiếu tiếp nhận | PASS |
| **TC-08** · Tạo yêu cầu bảo hành · dữ liệu sai (BR04) · *BR02, BR03, BR04* | Như TC-07 | 1. `bash scripts/tc.sh TC-08` | Bỏ trống **hãng** và **mức ưu tiên** | `422`; báo lỗi dưới ô hãng và ô mức ưu tiên; số yêu cầu và thiết bị KHÔNG đổi | Cao | 1 runs, 10 assertions, 0 failures – 422, báo lỗi hãng và mức ưu tiên, không tạo yêu cầu / thiết bị | PASS |
| **TC-09** · Danh sách yêu cầu · luồng đúng (UC07) · *UC07, BR10* | 3 yêu cầu: `…000001` còn hạn, `…000002` quá hạn, `…000003` đã hoàn tất | 1. `bash scripts/tc.sh TC-09` | Bộ lọc `status = overdue` | Bảng chỉ còn đúng 1 dòng `BH-2026-000002` | Trung bình | 1 runs, 1 assertions, 0 failures – chỉ còn `BH-2026-000002` | PASS |
| **TC-10** · Cập nhật trạng thái · vi phạm quy tắc (BR08) · *BR08* | Yêu cầu `BH-2099-000101` ở **Mới tiếp nhận** | 1. `bash scripts/tc.sh TC-10` | Chuyển thẳng sang `completed` | Báo "Không thể chuyển…"; trạng thái VẪN là Mới tiếp nhận | Cao | 1 runs, 3 assertions, 0 failures – báo không thể chuyển, vẫn Mới tiếp nhận | PASS |
| **TC-11** · Phân quyền · bảo mật (OWASP A01) · *TD-29, OWASP A01* | Đăng nhập **Quản lý**; yêu cầu `BH-2099-000901` mô tả "Lỗi" | 1. `bash scripts/tc.sh TC-11` (mở form sửa → gửi sửa → gửi xóa) | Mô tả mới "Sửa trộm" | Mở form sửa bị chuyển về Danh sách; mô tả VẪN là "Lỗi"; số yêu cầu KHÔNG đổi | Cao | 1 runs, 6 assertions, 0 failures – form sửa bị chuyển về Danh sách, mô tả vẫn "Lỗi", số yêu cầu không đổi | PASS |
| **TC-12** · Nạp dữ liệu · tính tái lập · *TD-28* | Test: CSDL test trống. Thực tế: `db:reset` đã nạp bộ L2 | 1. `bash scripts/tc.sh TC-12` (test tự động + `bin/rails import:l2` lần nữa) | `data/mau/*.csv` | Test PASS; `import:l2` báo "mới 0" cho khách, thiết bị, yêu cầu; số KH / TB / YC trước = sau | Cao | Test: 1 runs, 5 assertions, 0 failures. `import:l2` lần nữa: nhóm sự cố mới 0, khách hàng mới 0, thiết bị mới 0, yêu cầu mới 0 (loại 7 dòng). KH 311 · TB 31 · YC 30 trước = sau | PASS |
| **TC-13** · Đăng xuất · luồng đúng + bảo mật phiên (A07) · *NFR05, OWASP A07* | Đã đăng nhập `quoc@mekong.vn` | 1. `bash scripts/tc.sh TC-13` (bấm Đăng xuất → mở lại Tra cứu khách hàng) | — | Số phiên (Session) **−1**; chuyển về trang đăng nhập; mở lại Tra cứu khách hàng bị chuyển về đăng nhập | Cao | 1 runs, 8 assertions, 0 failures – phiên −1, về trang đăng nhập, mở lại Tra cứu bị chuyển về đăng nhập | PASS |
| **TC-14** · Sửa yêu cầu bảo hành · luồng đúng (TD-29) · *TD-29, BR06* | Đăng nhập Nhân viên tiếp nhận; yêu cầu `BH-2099-000960` mô tả "Pin chai", model A55 | 1. `bash scripts/tc.sh TC-14` (gửi form sửa) | Mô tả "Pin phồng", model "A56" | Về Phiếu tiếp nhận, báo "Đã cập nhật…"; lịch sử có dòng "Cập nhật thông tin"; CSDL lưu mô tả "Pin phồng", model "A56" | Trung bình | 1 runs, 9 assertions, 0 failures – về Phiếu, báo Đã cập nhật, lịch sử có Cập nhật thông tin, lưu "Pin phồng" / A56 | PASS |
| **TC-15** · Xóa yêu cầu bảo hành · luồng đúng (TD-29) · *TD-29* | Như TC-14 | 1. `bash scripts/tc.sh TC-15` (bấm Xóa yêu cầu) | Yêu cầu `BH-2099-000960` | Số yêu cầu **−1**; chuyển về Danh sách yêu cầu; thiết bị SN-GD-1 VẪN còn | Trung bình | 1 runs, 6 assertions, 0 failures – số yêu cầu −1, về Danh sách, thiết bị vẫn còn | PASS |
| **TC-16** · Tra cứu khách hàng · bảo mật – chống SQL injection (A05) · *UC01, OWASP A05* | Test: 2 khách `KH-900001`, `KH-900002`. Thực tế: `db:reset`, server đang chạy | 1. `bash scripts/tc.sh TC-16` (test tự động + `curl GET /api/customers?q=…`) | `' OR '1'='1` và `'; DROP TABLE customers; --` | Hiện "Không tìm thấy", KHÔNG có khách nào; số khách vẫn 2. API: `200`, `"data":[]`, `"tong_so":0` dù CSDL có nhiều khách | Cao | Test: 1 runs, 11 assertions, 0 failures. API thật: CSDL có 311 khách, `q=' OR '1'='1` → `200`, `"data":[]`, `"tong_so":0` | PASS |

## Đối chiếu năm loại test BT3

| Loại | Test case |
|---|---|
| Luồng đúng | TC-01, TC-03, TC-07, TC-09, TC-14, TC-15 |
| Giá trị biên – hai bên ranh giới SĐT 10 chữ số | TC-05 (10 chữ số – nhận), TC-06 (9 chữ số – từ chối) |
| Dữ liệu sai | TC-02 (sai mật khẩu), TC-08 (thiếu trường) |
| Bảo mật | TC-11 (A01 – Quản lý không sửa / xóa), TC-13 (A07 – phiên bị xóa khi đăng xuất), TC-16 (A05 – SQL injection) |
| Tái lập | TC-12 |
| Luồng ngoại lệ / vi phạm quy tắc (bổ sung) | TC-04 (UC08), TC-10 (BR08) |
