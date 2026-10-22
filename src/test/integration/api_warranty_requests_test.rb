require "test_helper"

# S3 – Kiểm thử API JSON (/api/...)
class ApiWarrantyRequestsTest < ActionDispatch::IntegrationTest
  setup do
    @user     = User.create!(full_name: "Nhân viên Test", role: :receptionist)
    @customer = Customer.create!(code: "KH-930001", name: "Khách API", phone: "0930000001")
    @category = IssueCategory.create!(name: "Màn hình")
    @priority = Priority.create!(name: "Cao", sla_hours: 24)

    device = Device.create!(customer: @customer, device_type: "Laptop", brand: "Dell", model: "X",
                            serial_number: "SN-API-001", purchase_date: Date.current - 30)
    @existing = WarrantyRequest.create!(code: "BH-2099-000500", device: device, created_by: @user,
                                        issue_category: @category, priority: @priority,
                                        issue_description: "Lỗi màn hình", due_at: 2.hours.ago)
  end

  def json = JSON.parse(response.body)

  def valid_body(overrides = {})
    { customer_id: @customer.id, device_type: "Điện thoại", brand: "Samsung", model: "Galaxy A55",
      serial_number: "SN-API-NEW", purchase_date: (Date.current - 10).iso8601,
      issue_description: "Không lên nguồn", issue_category_id: @category.id, priority_id: @priority.id }.merge(overrides)
  end

  # ---------- GET ----------
  test "GET /api/health trả về ok" do
    get api_health_path
    assert_response :ok
    assert_equal({ "status" => "ok", "db" => "ok" }, json)
  end

  test "GET /api/warranty_requests trả danh sách và thông tin phân trang" do
    get api_warranty_requests_path
    assert_response :ok
    assert_equal "BH-2099-000500", json["data"].first["code"]
    assert_equal true, json["data"].first["overdue"]
    assert_equal "Quá hạn", json["data"].first["status_label"]
    assert_equal 1, json["meta"]["tong_so"]
  end

  test "GET /api/warranty_requests lọc theo trạng thái" do
    get api_warranty_requests_path(status: "completed")
    assert_empty json["data"]
  end

  test "GET /api/warranty_requests/:id trả chi tiết; mã không tồn tại trả 404" do
    get api_warranty_request_path(@existing)
    assert_response :ok
    assert_equal "SN-API-001", json["data"]["device_detail"]["serial_number"]
    assert_equal %w[in_progress cancelled], json["data"]["allowed_next_statuses"]

    get api_warranty_request_path(id: 999_999)
    assert_response :not_found
    assert_equal "KHONG_TIM_THAY", json["error"]
  end

  # ---------- POST ----------
  test "POST tạo thành công: 201, header Location, mã BH, trạng thái received, hạn +24h" do
    assert_difference "WarrantyRequest.count", 1 do
      post api_warranty_requests_path, params: valid_body, as: :json
    end
    assert_response :created
    created = WarrantyRequest.find(json["data"]["id"])
    assert_equal api_warranty_request_path(created), response.headers["Location"]
    assert_match(/\ABH-\d{4}-\d{6}\z/, json["data"]["code"])
    assert_equal "received", json["data"]["status"]
    assert_in_delta created.created_at + 24.hours, created.due_at, 5
    assert_equal "Tiếp nhận yêu cầu", json["data"]["status_logs"].first["note"]
  end

  test "POST thiếu trường bắt buộc: 400, liệt kê tên trường" do
    assert_no_difference "WarrantyRequest.count" do
      post api_warranty_requests_path, params: { customer_id: @customer.id }, as: :json
    end
    assert_response :bad_request
    assert_equal "DU_LIEU_KHONG_HOP_LE", json["error"]
    fields = json["chi_tiet"]["cac_truong"].map { |f| f["truong"] }
    assert_includes fields, "serial_number"
    assert_includes fields, "priority_id"
  end

  test "POST khách hàng không tồn tại: 404 (BR01)" do
    post api_warranty_requests_path, params: valid_body(customer_id: 999_999), as: :json
    assert_response :not_found
    assert_equal "KHACH_HANG_KHONG_TON_TAI", json["error"]
  end

  test "POST serial đã thuộc khách hàng khác: 409 (NFR04)" do
    other = Customer.create!(code: "KH-930002", name: "Khách Khác", phone: "0930000002")
    post api_warranty_requests_path, params: valid_body(customer_id: other.id, serial_number: "SN-API-001"), as: :json
    assert_response :conflict
    assert_equal "SERIAL_THUOC_KHACH_KHAC", json["error"]
  end

  # ---------- PATCH ----------
  test "PATCH đổi trạng thái hợp lệ: 200, ghi lịch sử" do
    patch status_api_warranty_request_path(@existing), params: { status: "in_progress" }, as: :json
    assert_response :ok
    assert_equal "in_progress", json["data"]["status"]
    assert_equal "Đang xử lý", json["data"]["status_logs"].last["to"]
  end

  test "PATCH nhảy cóc sang completed: 422" do
    patch status_api_warranty_request_path(@existing), params: { status: "completed" }, as: :json
    assert_response 422
    assert_equal "CHUYEN_TRANG_THAI_KHONG_HOP_LE", json["error"]
  end

  test "PATCH hủy không có lý do: 400; yêu cầu đã đóng: 409" do
    patch status_api_warranty_request_path(@existing), params: { status: "cancelled" }, as: :json
    assert_response :bad_request
    assert_equal "THIEU_LY_DO_HUY", json["error"]

    patch status_api_warranty_request_path(@existing), params: { status: "cancelled", note: "Khách hủy" }, as: :json
    assert_response :ok

    patch status_api_warranty_request_path(@existing), params: { status: "in_progress" }, as: :json
    assert_response :conflict
    assert_equal "YEU_CAU_DA_DONG", json["error"]
  end

  test "PATCH thiếu tham số status: 400" do
    patch status_api_warranty_request_path(@existing), params: {}, as: :json
    assert_response :bad_request
    assert_equal "DU_LIEU_KHONG_HOP_LE", json["error"]
  end
end
