require "test_helper"

# Kiểm thử Màn hình 2 – UC02–UC06, BR01–BR06, NFR04
class WarrantyRequestCreationTest < ActionDispatch::IntegrationTest
  setup do
    User.create!(full_name: "Nhân viên Test", role: :receptionist)
    @customer = Customer.create!(code: "KH-900001", name: "Nguyễn Văn Test", phone: "0909000111")
    @category = IssueCategory.create!(name: "Nguồn / Pin / Sạc")
    @priority = Priority.create!(name: "Cao", sla_hours: 24)
  end

  def valid_params(overrides = {})
    { warranty_request: {
        customer_name: "Nguyễn Văn Test", device_type: "Điện thoại", brand: "Samsung", model: "Galaxy A55",
        serial_number: "SN-NEW-001", purchase_date: Date.current - 30, warranty_card_number: "",
        issue_description: "Máy không lên nguồn", issue_category_id: @category.id, priority_id: @priority.id
      }.merge(overrides) }
  end

  test "BR01 – chưa chọn khách hàng thì quay về trang tra cứu" do
    get new_warranty_request_path
    assert_redirected_to search_customers_path
  end

  test "mở form với khách hàng đã chọn" do
    get new_warranty_request_path(customer_id: @customer.id)
    assert_response :success
    assert_select ".customer-bar b", "Nguyễn Văn Test"
    assert_select "input[name='warranty_request[customer_name]'][value=?]", "Nguyễn Văn Test"
  end

  test "UC06 – tạo thành công: sinh mã, trạng thái Mới tiếp nhận, hạn = +24h" do
    assert_difference ["WarrantyRequest.count", "Device.count"], 1 do
      post warranty_requests_path(customer_id: @customer.id), params: valid_params
    end

    request = WarrantyRequest.last
    assert_redirected_to warranty_request_path(request)
    assert_match(/\ABH-\d{4}-000001\z/, request.code)
    assert request.received?
    assert_in_delta request.created_at + 24.hours, request.due_at, 5
    assert_equal @customer, request.device.customer

    follow_redirect!
    assert_select ".receipt__code", request.code
  end

  test "sửa họ tên khách hàng trên form thì cập nhật lại khách hàng" do
    post warranty_requests_path(customer_id: @customer.id), params: valid_params(customer_name: "Nguyễn Văn Mới")
    assert_equal "Nguyễn Văn Mới", @customer.reload.name
  end

  test "BR04 – thiếu trường bắt buộc thì không tạo gì cả" do
    assert_no_difference ["WarrantyRequest.count", "Device.count"] do
      post warranty_requests_path(customer_id: @customer.id), params: valid_params(brand: "", priority_id: "")
    end
    assert_response :unprocessable_entity
    assert_select ".form-errors"
    assert_select ".error-text", /chọn hãng/
    assert_select ".error-text", /mức độ ưu tiên/
  end

  test "NFR04 – serial đã thuộc khách hàng khác thì báo lỗi, không tạo" do
    other = Customer.create!(code: "KH-900002", name: "Khách khác", phone: "0909000222")
    Device.create!(customer: other, device_type: "Laptop", brand: "Dell", model: "X",
                   serial_number: "SN-NEW-001", purchase_date: Date.current - 10)

    assert_no_difference "WarrantyRequest.count" do
      post warranty_requests_path(customer_id: @customer.id), params: valid_params
    end
    assert_response :unprocessable_entity
    assert_select ".error-text", /khách hàng khác/
  end

  test "serial đã thuộc chính khách hàng này thì dùng lại thiết bị cũ" do
    Device.create!(customer: @customer, device_type: "Điện thoại", brand: "Samsung", model: "Galaxy A55",
                   serial_number: "SN-NEW-001", purchase_date: Date.current - 30)

    assert_difference "WarrantyRequest.count", 1 do
      assert_no_difference "Device.count" do
        post warranty_requests_path(customer_id: @customer.id), params: valid_params
      end
    end
  end
end
