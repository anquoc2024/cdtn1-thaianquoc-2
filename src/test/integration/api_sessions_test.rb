require "test_helper"

# TD-24 – Đăng nhập API để lấy token (POST /api/session), đăng xuất (DELETE /api/session)
class ApiSessionsTest < ActionDispatch::IntegrationTest
  self.auto_sign_in_as = nil

  setup do
    @receptionist = create_account(role: :receptionist, email: "quoc@mekong.vn")
    @manager      = create_account(role: :manager, email: "phu@mekong.vn")
  end

  def json = JSON.parse(response.body)

  test "đăng nhập đúng: 200, trả token, vai trò và danh sách quyền" do
    post api_session_path, params: { email_address: "quoc@mekong.vn", password: PASSWORD }, as: :json

    assert_response :ok
    assert_equal @receptionist.api_token, json["data"]["token"]
    assert_equal "Bearer", json["data"]["token_type"]
    assert_equal "receptionist", json["data"]["user"]["role"]
    assert_includes json["data"]["user"]["permissions"], "create_requests"
    assert_includes json["data"]["user"]["permissions"], "view_request_list"
  end

  test "sai mật khẩu hoặc thiếu thông tin: 401 SAI_THONG_TIN_DANG_NHAP" do
    post api_session_path, params: { email_address: "quoc@mekong.vn", password: "sai-mat-khau" }, as: :json
    assert_response :unauthorized
    assert_equal "SAI_THONG_TIN_DANG_NHAP", json["error"]

    post api_session_path, params: {}, as: :json
    assert_response :unauthorized
  end

  test "token lấy từ đăng nhập gọi được API theo đúng quyền (Quản lý chỉ xem)" do
    post api_session_path, params: { email_address: "phu@mekong.vn", password: PASSWORD }, as: :json
    assert_equal %w[view_requests view_request_list], json["data"]["user"]["permissions"]
    token = json["data"]["token"]

    get api_warranty_requests_path, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :ok

    post api_warranty_requests_path, params: {}, headers: { "Authorization" => "Bearer #{token}" }, as: :json
    assert_response :forbidden
  end

  test "đăng xuất: 204, token cũ không dùng được nữa" do
    old_token = @receptionist.api_token

    delete api_session_path, headers: { "Authorization" => "Bearer #{old_token}" }
    assert_response :no_content
    assert_not_equal old_token, @receptionist.reload.api_token

    get api_warranty_request_path(id: 1), headers: { "Authorization" => "Bearer #{old_token}" }
    assert_response :unauthorized
  end
end
