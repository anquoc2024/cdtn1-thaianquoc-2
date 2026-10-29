require "test_helper"

# TD-24 – Phân quyền theo vai trò (NFR05, theo User Story)
#   Nhân viên tiếp nhận: tra cứu, tạo yêu cầu, xem phiếu, đổi trạng thái, xem danh sách
#   Quản lý trung tâm:   tra cứu, tạo yêu cầu, xem danh sách / thống kê / phiếu (TD-29);
#                        không đổi trạng thái, không sửa / xóa yêu cầu
class ReceptionistAuthorizationTest < ActionDispatch::IntegrationTest
  self.auto_sign_in_as = :receptionist

  test "Nhân viên tiếp nhận dùng được Tra cứu và xem Danh sách yêu cầu" do
    get search_customers_path
    assert_response :ok

    get manager_warranty_requests_path
    assert_response :ok
  end

  test "sidebar đủ 3 mục, không mục nào bị khóa với Nhân viên tiếp nhận" do
    get search_customers_path

    assert_select ".sidebar .nav__item", 3
    assert_select ".sidebar .nav__item--locked", 0
  end
end

class ManagerAuthorizationTest < ActionDispatch::IntegrationTest
  self.auto_sign_in_as = :manager

  setup do
    staff    = User.create!(full_name: "NV Test", role: :receptionist)
    customer = Customer.create!(code: "KH-940001", name: "Khách Quyền", phone: "0940000001")
    device   = Device.create!(customer: customer, device_type: "Laptop", brand: "Dell", model: "X",
                              serial_number: "SN-QUYEN-1", purchase_date: Date.current - 10)
    @warranty_request = WarrantyRequest.create!(
      code: "BH-2099-000901", device: device, created_by: staff,
      issue_category: IssueCategory.create!(name: "Quyền test"),
      priority: Priority.create!(name: "Quyền test", sla_hours: 24),
      issue_description: "Lỗi", due_at: 1.day.from_now
    )
  end

  test "Quản lý xem được Danh sách yêu cầu và Phiếu tiếp nhận" do
    get manager_warranty_requests_path
    assert_response :ok

    get warranty_request_path(@warranty_request)
    assert_response :ok
    assert_select ".status-panel button", 0
    assert_select "a", text: "Sửa yêu cầu", count: 0
    assert_select "button", text: "Xóa yêu cầu", count: 0
  end

  test "sidebar đủ 3 mục, không mục nào bị khóa với Quản lý (TD-29)" do
    get manager_warranty_requests_path

    assert_select ".sidebar .nav__item", 3
    assert_select ".sidebar .nav__item--locked", 0
  end

  test "Quản lý tra cứu khách hàng và mở được form tạo yêu cầu (TD-29)" do
    get search_customers_path
    assert_response :ok

    get new_warranty_request_path(customer_id: @warranty_request.device.customer_id)
    assert_response :ok
  end

  test "Quản lý không sửa, không xóa được yêu cầu" do
    get edit_warranty_request_path(@warranty_request)
    assert_redirected_to manager_warranty_requests_path

    patch warranty_request_path(@warranty_request), params: { warranty_request: { issue_description: "Sửa trộm" } }
    assert_equal "Lỗi", @warranty_request.reload.issue_description

    assert_no_difference "WarrantyRequest.count" do
      delete warranty_request_path(@warranty_request)
    end
  end

  test "Quản lý không đổi được trạng thái yêu cầu" do
    patch update_status_warranty_request_path(@warranty_request), params: { to_status: "in_progress" }

    assert_redirected_to manager_warranty_requests_path
    assert_equal "received", @warranty_request.reload.status
  end
end
