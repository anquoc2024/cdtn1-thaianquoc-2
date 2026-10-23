require "test_helper"

# TD-24 – Phân quyền theo vai trò (NFR05)
class AuthorizationTest < ActionDispatch::IntegrationTest
  self.auto_sign_in_as = :receptionist

  test "Nhân viên tiếp nhận dùng được Tra cứu và Tạo yêu cầu" do
    get search_customers_path
    assert_response :ok
  end

  test "Nhân viên tiếp nhận vào Danh sách yêu cầu bị chặn và báo không có quyền" do
    get manager_warranty_requests_path
    assert_redirected_to search_customers_path
    follow_redirect!
    assert_select ".flash--alert", Authorization::DENIED_MESSAGE
  end

  test "sidebar luôn đủ 3 mục; mục Danh sách yêu cầu bị khóa với Nhân viên tiếp nhận" do
    get search_customers_path

    assert_select ".sidebar .nav__item", 3
    assert_select ".sidebar .nav__item--locked", 1
    assert_select ".sidebar .nav__item--locked span", "Danh sách yêu cầu"
    assert_select ".sidebar .nav__item--locked .nav__lock"
  end
end

class ManagerAuthorizationTest < ActionDispatch::IntegrationTest
  self.auto_sign_in_as = :manager

  test "Quản lý vào được Danh sách yêu cầu và không có mục nào bị khóa" do
    get manager_warranty_requests_path
    assert_response :ok
    assert_select ".sidebar .nav__item", 3
    assert_select ".sidebar .nav__item--locked", 0
  end

  test "Quản lý cũng dùng được Tra cứu khách hàng" do
    get search_customers_path
    assert_response :ok
  end
end
