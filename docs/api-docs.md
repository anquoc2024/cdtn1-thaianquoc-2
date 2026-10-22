# API Docs – Luồng L2: Yêu cầu bảo hành

Tài liệu API JSON của hệ thống. Request và response **thật** của từng endpoint (kể cả các trường hợp lỗi)
được sinh tự động bằng `docs/scripts/goi-api.sh` và lưu ở `docs/api-ket-qua-thuc-te.md`.

- **Địa chỉ gốc:** `http://localhost:3000`
- **Định dạng:** gửi và nhận JSON (`Content-Type: application/json`)
- **Xác thực:** không có – đăng nhập đã đưa ra ngoài phạm vi (`docs/thay-doi-thiet-ke.md` TD-11).
  Người thao tác mặc định là nhân viên tiếp nhận đầu tiên trong dữ liệu. **Hạn chế đã biết.**
- **Mã nguồn:** `src/app/controllers/api/`, `src/app/serializers/warranty_request_serializer.rb`.
  API dùng chung service với giao diện, nên quy tắc nghiệp vụ giống hệt nhau.

## Dạng lỗi chung

Mọi lỗi trả về cùng một dạng:

```json
{
  "error": "MA_LOI_NGHIEP_VU",
  "message": "Câu mô tả cho người đọc",
  "chi_tiet": { "...": "chỉ có ở một số lỗi" }
}
```

| HTTP | `error` | Khi nào |
|---|---|---|
| 400 | `DU_LIEU_KHONG_HOP_LE` | Thiếu hoặc sai trường; `chi_tiet.cac_truong` liệt kê `{truong, ly_do}` |
| 400 | `TRANG_THAI_KHONG_HOP_LE` | `status` không thuộc tập cho phép |
| 400 | `THIEU_LY_DO_HUY` | Hủy yêu cầu mà không có `note` |
| 404 | `KHONG_TIM_THAY` | Không có yêu cầu với `id` đã cho |
| 404 | `KHACH_HANG_KHONG_TON_TAI` | `customer_id` không tồn tại (BR01) |
| 409 | `SERIAL_THUOC_KHACH_KHAC` | Số serial đã đăng ký cho khách hàng khác (NFR04) |
| 409 | `YEU_CAU_DA_DONG` | Yêu cầu đã Hoàn tất hoặc Đã hủy |
| 422 | `CHUYEN_TRANG_THAI_KHONG_HOP_LE` | Chuyển trạng thái sai thứ tự |
| 500 | `LOI_HE_THONG` | Lỗi không lường trước; chỉ trả `chi_tiet.request_id` để đối chiếu nhật ký, không lộ chi tiết bên trong |

---

## 1. `GET /api/health`

Kiểm tra dịch vụ còn chạy và còn kết nối được cơ sở dữ liệu.

| Mã | Thân phản hồi |
|---|---|
| 200 | `{"status":"ok","db":"ok"}` |
| 503 | `{"status":"degraded","db":"khong ket noi duoc"}` |

```bash
curl -s http://localhost:3000/api/health
```

---

## 2. `GET /api/warranty_requests`

Danh sách yêu cầu bảo hành – UC07. Mỗi trang 8 dòng.

**Tham số truy vấn** (đều không bắt buộc):

| Tham số | Kiểu | Ý nghĩa |
|---|---|---|
| `q` | chuỗi | Tìm theo mã yêu cầu, tên khách hàng, số điện thoại (bỏ qua dấu cách) |
| `status` | chuỗi | `received` · `in_progress` · `overdue` · `completed` · `cancelled` |
| `issue_category_id` | số nguyên | Lọc theo nhóm sự cố |
| `priority_id` | số nguyên | Lọc theo mức ưu tiên |
| `from`, `to` | `YYYY-MM-DD` | Khoảng ngày tiếp nhận |
| `sort` | chuỗi | `newest` (mặc định – mới tạo nhất trước) · `due_at` (hạn cam kết gần nhất trước) |
| `page` | số nguyên ≥ 1 | Số trang, mặc định 1 |

**Phản hồi 200:**

```json
{
  "data": [
    {
      "id": 5,
      "code": "BH-2026-000120",
      "status": "in_progress",
      "status_label": "Quá hạn",
      "overdue": true,
      "priority": "Khẩn cấp",
      "sla_hours": 8,
      "issue_category": "Cơ / Linh kiện",
      "customer_code": "KH-000248",
      "customer_name": "Hoàng Minh Đức",
      "customer_phone": "0934111222",
      "device": "Acer Aspire 7",
      "created_at": "2026-10-21T14:20:00+07:00",
      "due_at": "2026-10-21T05:09:00+07:00",
      "closed_at": null
    }
  ],
  "meta": { "trang": 1, "so_trang": 1, "tong_so": 2, "moi_trang": 8 }
}
```

`status_label` là `"Quá hạn"` khi `overdue = true` – giá trị **tính** từ `due_at`, không lưu (TD-09).

```bash
curl -s "http://localhost:3000/api/warranty_requests?status=overdue&sort=due_at"
```

---

## 3. `GET /api/warranty_requests/{id}`

Chi tiết một yêu cầu, kèm thông tin thiết bị, các trạng thái được phép chuyển tiếp và lịch sử trạng thái.

**Phản hồi 200** (ngoài các trường như mục 2):

```json
{
  "data": {
    "id": 9,
    "code": "BH-2026-000124",
    "status": "received",
    "issue_description": "Màn hình chớp tắt",
    "device_detail": {
      "device_type": "Điện thoại", "brand": "Samsung", "model": "Galaxy S24",
      "serial_number": "SN-CURL-1761030000", "purchase_date": "2026-05-01",
      "warranty_card_number": null
    },
    "allowed_next_statuses": ["in_progress", "cancelled"],
    "status_logs": [
      { "from": "—", "to": "Mới tiếp nhận", "note": "Tiếp nhận yêu cầu",
        "changed_by": "Thái An Quốc", "at": "2026-10-21T17:05:00+07:00" }
    ]
  }
}
```

| Mã | Tình huống |
|---|---|
| 200 | Tìm thấy |
| 404 | `KHONG_TIM_THAY` |

---

## 4. `POST /api/warranty_requests`

Tạo yêu cầu bảo hành – UC06. Hệ thống tự sinh mã (BR05), đặt trạng thái `received` và tính
`due_at = thời điểm tạo + sla_hours của mức ưu tiên` (BR06). Nếu serial đã thuộc chính khách hàng này
thì dùng lại thiết bị cũ; thuộc khách hàng khác thì từ chối (NFR04). Mọi thao tác ghi nằm trong một transaction.

**Thân yêu cầu:**

| Trường | Kiểu | Bắt buộc | Ràng buộc |
|---|---|---|---|
| `customer_id` | số nguyên | Có | Khách hàng phải tồn tại (BR01) |
| `customer_name` | chuỗi | Không | ≤ 100 ký tự; có thì cập nhật họ tên khách hàng (TD-13) |
| `device_type` | chuỗi | Có | VD: `Điện thoại`, `Laptop` |
| `brand` | chuỗi | Có | VD: `Samsung` |
| `model` | chuỗi | Có | |
| `serial_number` | chuỗi | Có | ≤ 50 ký tự |
| `purchase_date` | `YYYY-MM-DD` | Có | Không lớn hơn ngày hiện tại |
| `warranty_card_number` | chuỗi | Không | |
| `issue_description` | chuỗi | Có | 1–1000 ký tự |
| `issue_category_id` | số nguyên | Có | BR03 |
| `priority_id` | số nguyên | Có | BR03 |

```bash
curl -s -i -X POST http://localhost:3000/api/warranty_requests \
  -H 'Content-Type: application/json' \
  -d '{"customer_id":1,"device_type":"Điện thoại","brand":"Samsung","model":"Galaxy S24",
       "serial_number":"SN-90001","purchase_date":"2026-05-01",
       "issue_description":"Màn hình chớp tắt","issue_category_id":1,"priority_id":3}'
```

| Mã | Tình huống |
|---|---|
| 201 | Tạo thành công; header `Location: /api/warranty_requests/{id}`; thân như mục 3 |
| 400 | `DU_LIEU_KHONG_HOP_LE` – `chi_tiet.cac_truong` liệt kê từng trường sai |
| 404 | `KHACH_HANG_KHONG_TON_TAI` |
| 409 | `SERIAL_THUOC_KHACH_KHAC` |

---

## 5. `PATCH /api/warranty_requests/{id}/status`

Cập nhật trạng thái hoặc hủy yêu cầu (phần U, D của CRUD – TD-20). Khóa dòng khi cập nhật và ghi lịch sử
trong cùng transaction.

**Chuyển trạng thái hợp lệ:**

```
received ──► in_progress ──► completed
    └──────────┴──► cancelled        (completed / cancelled = đã đóng)
```

**Thân yêu cầu:**

| Trường | Kiểu | Bắt buộc | Ràng buộc |
|---|---|---|---|
| `status` | chuỗi | Có | `in_progress` · `completed` · `cancelled` |
| `note` | chuỗi | Bắt buộc khi `status = cancelled` | ≤ 500 ký tự, lưu vào lịch sử |

```bash
curl -s -X PATCH http://localhost:3000/api/warranty_requests/9/status \
  -H 'Content-Type: application/json' \
  -d '{"status":"cancelled","note":"Khách xin nhận lại máy"}'
```

| Mã | Tình huống |
|---|---|
| 200 | Thành công; thân như mục 3, `status_logs` có thêm dòng mới, `closed_at` có giá trị khi đóng |
| 400 | `DU_LIEU_KHONG_HOP_LE` (thiếu `status`), `TRANG_THAI_KHONG_HOP_LE`, `THIEU_LY_DO_HUY` |
| 404 | `KHONG_TIM_THAY` |
| 409 | `YEU_CAU_DA_DONG` |
| 422 | `CHUYEN_TRANG_THAI_KHONG_HOP_LE` – ví dụ đi thẳng từ `received` sang `completed` |

---

## Kiểm thử API

- Tự động: `src/test/integration/api_warranty_requests_test.rb` (12 test) – chạy bằng `cd src && bin/rails test`.
- Bằng tay: `bash docs/scripts/goi-api.sh` (12 request thật, kết quả ở `docs/api-ket-qua-thuc-te.md`).
