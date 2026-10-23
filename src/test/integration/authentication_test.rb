require "test_helper"

# TD-24 – Đăng nhập / đăng xuất
class AuthenticationTest < ActionDispatch::IntegrationTest
  self.auto_sign_in_as = nil

  setup do
    @receptionist = create_account(role: :receptionist, email: "quoc@mekong.vn", full_name: "Thái An Quốc")
    @manager      = create_account(role: :manager, email: "phu@mekong.vn", full_name: "Võ Phạm Việt Phú")
  end

  test "chưa đăng nhập thì bị chuyển về trang đăng nhập" do
    get search_customers_path
    assert_redirected_to new_session_path

    get new_session_path
    assert_response :ok
    assert_select "h1", "Chào mừng trở lại"
    assert_select "input[type=email][name=email_address]"
    assert_select "input[type=password][name=password]"
  end

  test "sai mật khẩu: ở lại trang đăng nhập, báo lỗi, không tạo phiên" do
    assert_no_difference "Session.count" do
      sign_in_as(@receptionist, password: "sai-mat-khau")
    end
    assert_response :unprocessable_entity
    assert_select ".flash--alert", "Email hoặc mật khẩu không đúng."
  end

  test "Nhân viên tiếp nhận đăng nhập → vào Tra cứu khách hàng; Quản lý → vào Danh sách yêu cầu" do
    sign_in_as(@receptionist)
    assert_redirected_to search_customers_path

    delete session_path
    sign_in_as(@manager)
    assert_redirected_to manager_warranty_requests_path
  end

  test "sau khi đăng nhập quay về đúng trang đã định mở" do
    get new_warranty_request_path
    assert_redirected_to new_session_path

    sign_in_as(@receptionist)
    assert_redirected_to new_warranty_request_path
  end

  test "thanh tiêu đề hiện tên, vai trò người đăng nhập và nút Đăng xuất" do
    sign_in_as(@receptionist)
    follow_redirect!

    assert_select ".topbar__who b", "Thái An Quốc"
    assert_select ".topbar__who small", "Nhân viên tiếp nhận"
    assert_select "form[action='#{session_path}'] button.topbar__logout"
  end

  test "đăng xuất xóa phiên; vào lại trang bị chuyển về đăng nhập" do
    sign_in_as(@receptionist)

    assert_difference "Session.count", -1 do
      delete session_path
    end
    assert_redirected_to new_session_path

    get search_customers_path
    assert_redirected_to new_session_path
  end
end
