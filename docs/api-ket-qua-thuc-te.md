# Kết quả gọi API thực tế

Sinh tự động bởi `docs/scripts/goi-api.sh` lúc 21/10/2026 10:12:43, trên http://localhost:3000.
Mọi request và response dưới đây là **thật**, chép nguyên từ hệ thống đang chạy.

## 1. GET /api/health – dịch vụ còn sống

```bash
curl 'http://localhost:3000/api/health'
```

**HTTP 200**

```json
{
    "status": "ok",
    "db": "ok"
}
```

## 2. GET /api/warranty_requests – lọc Quá hạn

```bash
curl 'http://localhost:3000/api/warranty_requests?status=overdue'
```

**HTTP 200**

```json
{
    "data": [
        {
            "id": 7,
            "code": "BH-2026-000117",
            "status": "received",
            "status_label": "Quá hạn",
            "overdue": true,
            "priority": "Trung bình",
            "sla_hours": 48,
            "issue_category": "Bàn phím",
            "customer_code": "KH-000251",
            "customer_name": "Đặng Mai Lan",
            "customer_phone": "0911666777",
            "device": "HP Pavilion",
            "created_at": "2026-10-21T15:09:37+07:00",
            "due_at": "2026-10-20T09:09:37+07:00",
            "closed_at": null
        },
        {
            "id": 4,
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
            "created_at": "2026-10-21T15:09:37+07:00",
            "due_at": "2026-10-21T05:09:37+07:00",
            "closed_at": null
        }
    ],
    "meta": {
        "trang": 1,
        "so_trang": 1,
        "tong_so": 2,
        "moi_trang": 8
    }
}
```

## 3. GET /api/warranty_requests/:id – chi tiết

```bash
curl 'http://localhost:3000/api/warranty_requests/1'
```

**HTTP 200**

```json
{
    "data": {
        "id": 1,
        "code": "BH-2026-000123",
        "status": "received",
        "status_label": "Mới tiếp nhận",
        "overdue": false,
        "priority": "Cao",
        "sla_hours": 24,
        "issue_category": "Nguồn / Pin / Sạc",
        "customer_code": "KH-000245",
        "customer_name": "Trần Thị Bình",
        "customer_phone": "0905123456",
        "device": "Samsung Galaxy A55",
        "created_at": "2026-10-21T15:09:37+07:00",
        "due_at": "2026-10-22T11:09:37+07:00",
        "closed_at": null,
        "issue_description": "Dữ liệu mẫu: thiết bị gặp sự cố nhóm Nguồn / Pin / Sạc.",
        "device_detail": {
            "device_type": "Điện thoại",
            "brand": "Samsung",
            "model": "Galaxy A55",
            "serial_number": "R58T20A0001",
            "purchase_date": "2026-08-21",
            "warranty_card_number": null
        },
        "allowed_next_statuses": [
            "in_progress",
            "cancelled"
        ],
        "status_logs": []
    }
}
```

## 4. GET /api/warranty_requests/:id – không tồn tại (404)

```bash
curl 'http://localhost:3000/api/warranty_requests/999999'
```

**HTTP 404**

```json
{
    "error": "KHONG_TIM_THAY",
    "message": "Không tìm thấy dữ liệu với mã đã cho."
}
```

## 5. POST /api/warranty_requests – tạo thành công (201)

```bash
curl '-X' 'POST' '-H' 'Content-Type: application/json' '-d' '{"customer_id":1,"device_type":"Điện thoại","brand":"Samsung","model":"Galaxy S24","serial_number":"SN-CURL-1792577563","purchase_date":"2026-05-01","issue_description":"Màn hình chớp tắt","issue_category_id":1,"priority_id":3}' 'http://localhost:3000/api/warranty_requests'
```

**HTTP 201**

Header trả về: `location: /api/warranty_requests/10`

```json
{
    "data": {
        "id": 10,
        "code": "BH-2026-000125",
        "status": "received",
        "status_label": "Mới tiếp nhận",
        "overdue": false,
        "priority": "Cao",
        "sla_hours": 24,
        "issue_category": "Nguồn / Pin / Sạc",
        "customer_code": "KH-000245",
        "customer_name": "Trần Thị Bình",
        "customer_phone": "0905123456",
        "device": "Samsung Galaxy S24",
        "created_at": "2026-10-21T17:12:44+07:00",
        "due_at": "2026-10-22T17:12:44+07:00",
        "closed_at": null,
        "issue_description": "Màn hình chớp tắt",
        "device_detail": {
            "device_type": "Điện thoại",
            "brand": "Samsung",
            "model": "Galaxy S24",
            "serial_number": "SN-CURL-1792577563",
            "purchase_date": "2026-05-01",
            "warranty_card_number": null
        },
        "allowed_next_statuses": [
            "in_progress",
            "cancelled"
        ],
        "status_logs": [
            {
                "from": "—",
                "to": "Mới tiếp nhận",
                "note": "Tiếp nhận yêu cầu",
                "changed_by": "Thái An Quốc",
                "at": "2026-10-21T17:12:44+07:00"
            }
        ]
    }
}
```

## 6. POST – thiếu trường bắt buộc (400)

```bash
curl '-X' 'POST' '-H' 'Content-Type: application/json' '-d' '{"customer_id":1}' 'http://localhost:3000/api/warranty_requests'
```

**HTTP 400**

```json
{
    "error": "DU_LIEU_KHONG_HOP_LE",
    "message": "Dữ liệu vào không hợp lệ ở các trường: device_type, brand, model, serial_number, purchase_date, issue_description, issue_category_id, priority_id",
    "chi_tiet": {
        "cac_truong": [
            {
                "truong": "device_type",
                "ly_do": "Vui lòng chọn loại thiết bị"
            },
            {
                "truong": "brand",
                "ly_do": "Vui lòng chọn hãng"
            },
            {
                "truong": "model",
                "ly_do": "Vui lòng nhập model"
            },
            {
                "truong": "serial_number",
                "ly_do": "Vui lòng nhập số serial / IMEI"
            },
            {
                "truong": "purchase_date",
                "ly_do": "Vui lòng nhập ngày mua"
            },
            {
                "truong": "issue_description",
                "ly_do": "Vui lòng nhập mô tả lỗi"
            },
            {
                "truong": "issue_category_id",
                "ly_do": "Vui lòng chọn nhóm sự cố"
            },
            {
                "truong": "priority_id",
                "ly_do": "Vui lòng chọn mức độ ưu tiên"
            }
        ]
    }
}
```

## 7. POST – khách hàng không tồn tại (404)

```bash
curl '-X' 'POST' '-H' 'Content-Type: application/json' '-d' '{"customer_id":999999,"device_type":"Điện thoại","brand":"Samsung","model":"Galaxy S24","serial_number":"SN-CURL-1792577563","purchase_date":"2026-05-01","issue_description":"Màn hình chớp tắt","issue_category_id":1,"priority_id":3}' 'http://localhost:3000/api/warranty_requests'
```

**HTTP 404**

```json
{
    "error": "KHACH_HANG_KHONG_TON_TAI",
    "message": "Không tìm thấy khách hàng có mã 999999 (BR01)."
}
```

## 8. POST – serial đã thuộc khách hàng khác (409)

```bash
curl '-X' 'POST' '-H' 'Content-Type: application/json' '-d' '{"customer_id":1,"device_type":"Điện thoại","brand":"Samsung","model":"Galaxy S24","serial_number":"DL-INS-0002","purchase_date":"2026-05-01","issue_description":"Màn hình chớp tắt","issue_category_id":1,"priority_id":3}' 'http://localhost:3000/api/warranty_requests'
```

**HTTP 409**

```json
{
    "error": "SERIAL_THUOC_KHACH_KHAC",
    "message": "Số serial / IMEI này đã được đăng ký cho khách hàng khác"
}
```

## 9. PATCH status – nhảy cóc sang completed (422)

```bash
curl '-X' 'PATCH' '-H' 'Content-Type: application/json' '-d' '{"status":"completed"}' 'http://localhost:3000/api/warranty_requests/10/status'
```

**HTTP 422**

```json
{
    "error": "CHUYEN_TRANG_THAI_KHONG_HOP_LE",
    "message": "Không thể chuyển từ “Mới tiếp nhận” sang “Hoàn tất”."
}
```

## 10. PATCH status – hủy không có lý do (400)

```bash
curl '-X' 'PATCH' '-H' 'Content-Type: application/json' '-d' '{"status":"cancelled"}' 'http://localhost:3000/api/warranty_requests/10/status'
```

**HTTP 400**

```json
{
    "error": "THIEU_LY_DO_HUY",
    "message": "Vui lòng nhập lý do hủy yêu cầu."
}
```

## 11. PATCH status – hủy có lý do (200)

```bash
curl '-X' 'PATCH' '-H' 'Content-Type: application/json' '-d' '{"status":"cancelled","note":"Khách xin nhận lại máy"}' 'http://localhost:3000/api/warranty_requests/10/status'
```

**HTTP 200**

```json
{
    "data": {
        "id": 10,
        "code": "BH-2026-000125",
        "status": "cancelled",
        "status_label": "Đã hủy",
        "overdue": false,
        "priority": "Cao",
        "sla_hours": 24,
        "issue_category": "Nguồn / Pin / Sạc",
        "customer_code": "KH-000245",
        "customer_name": "Trần Thị Bình",
        "customer_phone": "0905123456",
        "device": "Samsung Galaxy S24",
        "created_at": "2026-10-21T17:12:44+07:00",
        "due_at": "2026-10-22T17:12:44+07:00",
        "closed_at": "2026-10-21T17:12:45+07:00",
        "issue_description": "Màn hình chớp tắt",
        "device_detail": {
            "device_type": "Điện thoại",
            "brand": "Samsung",
            "model": "Galaxy S24",
            "serial_number": "SN-CURL-1792577563",
            "purchase_date": "2026-05-01",
            "warranty_card_number": null
        },
        "allowed_next_statuses": [],
        "status_logs": [
            {
                "from": "—",
                "to": "Mới tiếp nhận",
                "note": "Tiếp nhận yêu cầu",
                "changed_by": "Thái An Quốc",
                "at": "2026-10-21T17:12:44+07:00"
            },
            {
                "from": "Mới tiếp nhận",
                "to": "Đã hủy",
                "note": "Khách xin nhận lại máy",
                "changed_by": "Thái An Quốc",
                "at": "2026-10-21T17:12:45+07:00"
            }
        ]
    }
}
```

## 12. PATCH status – yêu cầu đã đóng (409)

```bash
curl '-X' 'PATCH' '-H' 'Content-Type: application/json' '-d' '{"status":"in_progress"}' 'http://localhost:3000/api/warranty_requests/10/status'
```

**HTTP 409**

```json
{
    "error": "YEU_CAU_DA_DONG",
    "message": "Yêu cầu đã đóng (Hoàn tất hoặc Đã hủy), không thể đổi trạng thái."
}
```

