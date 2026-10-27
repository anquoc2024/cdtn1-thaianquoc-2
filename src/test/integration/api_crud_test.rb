require "test_helper"

# TD-25 – API CRUD Khách hàng và Nhóm sự cố: mã HTTP, định dạng lỗi, phân quyền
class ApiCrudTest < ActionDispatch::IntegrationTest
  self.auto_sign_in_as = nil

  setup do
    @staff   = create_account(role: :receptionist, email: "nv-crud@test.vn")
    @manager = create_account(role: :manager, email: "ql-crud@test.vn")
  end

  def json = JSON.parse(response.body)
  def auth(user = @staff) = { "Authorization" => "Bearer #{user.api_token}" }

  test "Khách hàng: tạo 201 → đọc 200 → sửa 200 → xóa 204 → đọc lại 404" do
    post api_customers_path, params: { name: "Khách API", phone: "0933 111 222" }, headers: auth, as: :json
    assert_response :created
    id = json["data"]["id"]
    assert_match(/\AKH-0\d{5}\z/, json["data"]["code"])
    assert_equal api_customer_path(id), response.headers["Location"]

    get api_customer_path(id), headers: auth
    assert_equal "0933111222", json["data"]["phone"]

    patch api_customer_path(id), params: { address: "1 Nguyễn Huệ" }, headers: auth, as: :json
    assert_response :ok
    assert_equal "1 Nguyễn Huệ", json["data"]["address"]

    delete api_customer_path(id), headers: auth
    assert_response :no_content

    get api_customer_path(id), headers: auth
    assert_response :not_found
  end

  test "Khách hàng: thiếu họ tên và SĐT sai → 400 kèm tên trường" do
    post api_customers_path, params: { phone: "0905" }, headers: auth, as: :json

    assert_response :bad_request
    assert_equal "DU_LIEU_KHONG_HOP_LE", json["error"]
    assert_equal %w[name phone], json["chi_tiet"]["cac_truong"].map { |f| f["truong"] }.uniq.sort
  end

  test "Khách hàng: trùng SĐT → 409 TRUNG_DU_LIEU; tìm theo q trả đúng khách" do
    post api_customers_path, params: { name: "A", phone: "0933000001" }, headers: auth, as: :json
    post api_customers_path, params: { name: "B", phone: "0933000001" }, headers: auth, as: :json
    assert_response :conflict
    assert_equal "TRUNG_DU_LIEU", json["error"]

    get api_customers_path(q: "0933 000 001"), headers: auth
    assert_equal ["A"], json["data"].map { |c| c["name"] }
  end

  test "Nhóm sự cố: CRUD đủ 4 thao tác; danh sách có số yêu cầu đang dùng" do
    post api_issue_categories_path, params: { name: "Camera" }, headers: auth, as: :json
    assert_response :created
    id = json["data"]["id"]

    get api_issue_categories_path, headers: auth
    assert_equal 0, json["data"].find { |c| c["id"] == id }["usage_count"]

    patch api_issue_category_path(id), params: { description: "Lỗi camera trước/sau" }, headers: auth, as: :json
    assert_response :ok

    delete api_issue_category_path(id), headers: auth
    assert_response :no_content
  end

  test "Quản lý chỉ xem: đọc nhóm sự cố được, thêm khách hàng / nhóm sự cố bị 403" do
    get api_issue_categories_path, headers: auth(@manager)
    assert_response :ok

    post api_customers_path, params: { name: "X", phone: "0933999999" }, headers: auth(@manager), as: :json
    assert_response :forbidden

    post api_issue_categories_path, params: { name: "X" }, headers: auth(@manager), as: :json
    assert_response :forbidden
    assert_equal "KHONG_CO_QUYEN", json["error"]
  end
end
