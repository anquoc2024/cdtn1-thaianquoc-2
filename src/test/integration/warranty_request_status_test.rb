require "test_helper"

# S2 – Cập nhật trạng thái / hủy yêu cầu trên Phiếu tiếp nhận
class WarrantyRequestStatusTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(full_name: "Nhân viên Test", role: :receptionist)
    customer = Customer.create!(code: "KH-920001", name: "Khách Phiếu", phone: "0920000001")
    device   = Device.create!(customer: customer, device_type: "Laptop", brand: "Dell", model: "X",
                              serial_number: "SN-S2-101", purchase_date: Date.current - 30)
    @warranty_request = WarrantyRequest.create!(code: "BH-2099-000101", device: device, created_by: @user,
                                       issue_category: IssueCategory.create!(name: "Màn hình"),
                                       priority: Priority.create!(name: "Cao", sla_hours: 24),
                                       issue_description: "Lỗi", due_at: 1.day.from_now)
  end

  test "phiếu mới tiếp nhận có nút Bắt đầu xử lý và khung hủy" do
    get warranty_request_path(@warranty_request)
    assert_response :success
    assert_select ".status-panel__btn", "Bắt đầu xử lý"
    assert_select ".status-panel__cancel textarea[name=note]"
  end

  test "bấm Bắt đầu xử lý thì đổi trạng thái và hiện trong lịch sử" do
    patch update_status_warranty_request_path(@warranty_request), params: { to_status: "in_progress" }
    assert_redirected_to warranty_request_path(@warranty_request)
    assert @warranty_request.reload.in_progress?

    follow_redirect!
    assert_select ".flash--notice", /Đang xử lý/
    assert_select ".timeline__change", /Mới tiếp nhận → Đang xử lý/
  end

  test "chuyển sai thứ tự thì báo lỗi, không đổi gì" do
    patch update_status_warranty_request_path(@warranty_request), params: { to_status: "completed" }
    follow_redirect!
    assert_select ".flash--alert", /Không thể chuyển/
    assert @warranty_request.reload.received?
  end

  test "hủy yêu cầu có lý do; phiếu đã hủy không còn nút đổi trạng thái" do
    patch update_status_warranty_request_path(@warranty_request), params: { to_status: "cancelled", note: "Khách xin nhận lại máy" }
    assert @warranty_request.reload.cancelled?

    follow_redirect!
    assert_select ".badge--cancelled", "Đã hủy"
    assert_select ".status-panel__btn", count: 0
    assert_select ".timeline__note", "Khách xin nhận lại máy"
  end

  test "danh sách quản lý lọc được trạng thái Đã hủy" do
    patch update_status_warranty_request_path(@warranty_request), params: { to_status: "cancelled", note: "Hủy" }

    get manager_warranty_requests_path(status: "cancelled")
    assert_equal ["BH-2099-000101"], css_select("tbody .code-link").map(&:text)
  end
end
