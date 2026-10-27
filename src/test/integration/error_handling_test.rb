require "test_helper"

# TD-27 – lỗi hệ thống: 503 khi mất CSDL, 500 có mã tra cứu, không lộ chi tiết kỹ thuật (Buổi 11)
# Giả lập sự cố bằng cách cho một phương thức ném lỗi trong phạm vi khối with_failure.
class ErrorHandlingTest < ActionDispatch::IntegrationTest
  self.auto_sign_in_as = nil

  test "API: mất CSDL trả 503 CSDL_KHONG_KHA_DUNG kèm mã tra cứu và Retry-After" do
    with_failure(User, :find_by, ActiveRecord::ConnectionNotEstablished.new("connection refused 5432")) do
      get api_customers_path, headers: { "Authorization" => "Bearer token-bat-ky" }
    end

    assert_response :service_unavailable
    body = response.parsed_body
    assert_equal "CSDL_KHONG_KHA_DUNG", body["error"]
    assert_equal response.headers["X-Request-Id"], body.dig("chi_tiet", "ma_tra_cuu")
    assert_includes body["message"], body.dig("chi_tiet", "ma_tra_cuu")
    assert_equal "30", response.headers["Retry-After"]
    assert_no_match(/ConnectionNotEstablished|5432/, response.body)
  end

  test "API: lỗi không lường trước trả 500 LOI_HE_THONG, không lộ câu lỗi kỹ thuật" do
    user = create_account(role: :receptionist)
    with_failure(DashboardStats, :call, RuntimeError.new("SELECT * FROM users – lỗi bí mật")) do
      get api_stats_path, headers: { "Authorization" => "Bearer #{user.api_token}" }
    end

    assert_response :internal_server_error
    body = response.parsed_body
    assert_equal "LOI_HE_THONG", body["error"]
    assert_equal response.headers["X-Request-Id"], body.dig("chi_tiet", "ma_tra_cuu")
    assert_no_match(/SELECT|bí mật|RuntimeError/, response.body)
  end

  test "Web: mất CSDL hiện trang 503 thân thiện có mã tra cứu và nút Thử lại" do
    sign_in_as(create_account(role: :receptionist))
    with_failure(Session, :find_by, ActiveRecord::ConnectionNotEstablished.new("connection refused")) do
      get search_customers_path
    end

    assert_response :service_unavailable
    assert_select "h1", /không truy cập được dữ liệu/
    assert_select ".lookup code", response.headers["X-Request-Id"]
    assert_select "a.btn--primary", /Thử lại/
    assert_no_match(/ConnectionNotEstablished/, response.body)
  end

  test "Web: lỗi không lường trước hiện trang 500 có mã tra cứu khi bật trang lỗi thân thiện" do
    sign_in_as(create_account(role: :manager))
    with_friendly_error_pages do
      with_failure(DashboardStats, :call, RuntimeError.new("lỗi bí mật")) do
        get manager_warranty_requests_path
      end
    end

    assert_response :internal_server_error
    assert_select "h1", /gặp sự cố/
    assert_select ".lookup code", response.headers["X-Request-Id"]
    assert_no_match(/bí mật|RuntimeError/, response.body)
  end

  private

  # Cho Klass.method_name ném lỗi trong khối, xong thì trả lại hành vi cũ
  def with_failure(klass, method_name, error)
    failing = Module.new { define_method(method_name) { |*, **| raise error } }
    klass.singleton_class.prepend(failing)
    yield
  ensure
    failing.send(:remove_method, method_name)
  end

  def with_friendly_error_pages
    previous = Rails.application.config.x.friendly_error_pages
    Rails.application.config.x.friendly_error_pages = true
    yield
  ensure
    Rails.application.config.x.friendly_error_pages = previous
  end
end
