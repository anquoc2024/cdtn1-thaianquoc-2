require "test_helper"

# TD-29 – Nhân viên tiếp nhận sửa và xóa yêu cầu bảo hành trên giao diện
class WarrantyRequestEditTest < ActionDispatch::IntegrationTest
  setup do
    staff    = User.create!(full_name: "NV tạo", role: :receptionist)
    customer = Customer.create!(code: "KH-960001", name: "Khách Giao Diện", phone: "0960000001")
    @device  = Device.create!(customer: customer, device_type: "Điện thoại", brand: "Samsung", model: "A55",
                              serial_number: "SN-GD-1", purchase_date: Date.current - 30)
    @priority = Priority.create!(name: "Cao", sla_hours: 24)
    @request  = WarrantyRequest.create!(code: "BH-2099-000960", device: @device, created_by: staff,
                                        issue_category: IssueCategory.create!(name: "Pin"), priority: @priority,
                                        issue_description: "Pin chai", due_at: 1.day.from_now)
  end

  test "phiếu tiếp nhận có nút Sửa và Xóa; mở được form sửa với dữ liệu cũ" do
    get warranty_request_path(@request)
    assert_select "a", text: "Sửa yêu cầu"
    assert_select "button", text: "Xóa yêu cầu"

    get edit_warranty_request_path(@request)
    assert_response :ok
    assert_select "textarea[name='warranty_request[issue_description]']", "Pin chai"
  end

  test "lưu thay đổi thì về phiếu, có thông báo và dòng Cập nhật thông tin trong lịch sử" do
    patch warranty_request_path(@request), params: { warranty_request: { issue_description: "Pin phồng", model: "A56" } }

    assert_redirected_to warranty_request_path(@request)
    follow_redirect!
    assert_select ".flash--notice", /Đã cập nhật/
    assert_select ".timeline__change", /Cập nhật thông tin/
    assert_equal "Pin phồng", @request.reload.issue_description
    assert_equal "A56", @device.reload.model
  end

  test "dữ liệu sai thì hiện lại form có lỗi, không lưu" do
    patch warranty_request_path(@request), params: { warranty_request: { issue_description: "" } }

    assert_response :unprocessable_entity
    assert_select ".error-text", /mô tả lỗi/
    assert_equal "Pin chai", @request.reload.issue_description
  end

  test "xóa yêu cầu thì về danh sách, thiết bị vẫn còn" do
    assert_difference "WarrantyRequest.count", -1 do
      delete warranty_request_path(@request)
    end

    assert_redirected_to manager_warranty_requests_path
    assert Device.exists?(@device.id)
  end
end
