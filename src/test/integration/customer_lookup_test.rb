require "test_helper"

# Kiểm thử Màn hình 1 – tra cứu theo SĐT / mã KH / tên (UC01, UC08, FR01, FR09)
class CustomerLookupTest < ActionDispatch::IntegrationTest
  setup do
    @customer = Customer.create!(code: "KH-900001", name: "Nguyễn Văn Test", phone: "0909000111")
  end

  def found_names
    css_select(".customer-card__name b, .customer-list__info b").map(&:text)
  end

  test "mở trang lần đầu: chỉ có ô tra cứu, chưa hiện kết quả" do
    get search_customers_path
    assert_response :success
    assert_select "input#q"
    assert_empty found_names
    assert_select ".alert-notfound", count: 0
  end

  test "tìm theo SĐT có dấu cách" do
    get search_customers_path, params: { q: "0909 000 111" }
    assert_equal ["Nguyễn Văn Test"], found_names
    assert_select "a[href=?]", new_warranty_request_path(customer_id: @customer.id)
  end

  test "tìm theo mã khách hàng đầy đủ, viết thường, hoặc chỉ phần số" do
    ["KH-900001", "kh900001", "900001"].each do |query|
      get search_customers_path, params: { q: query }
      assert_equal ["Nguyễn Văn Test"], found_names, "Không tìm được với '#{query}'"
    end
  end

  test "tìm theo tên không dấu, không phân biệt hoa thường" do
    get search_customers_path, params: { q: "nguyen van test" }
    assert_equal ["Nguyễn Văn Test"], found_names
    assert_select ".customer-card"
  end

  test "tìm theo tên ra nhiều khách hàng thì hiện danh sách để chọn" do
    other = Customer.create!(code: "KH-900002", name: "Nguyễn Thị Hai", phone: "0909000222")

    get search_customers_path, params: { q: "Nguyễn" }
    assert_select ".customer-list__row", 2
    assert_select "a[href=?]", new_warranty_request_path(customer_id: other.id)
    assert_select ".customer-card", count: 0
  end

  test "nút Quay lại ở Màn hình 2 (tham số phone cũ) vẫn tìm được" do
    get search_customers_path, params: { phone: "0909000111" }
    assert_equal ["Nguyễn Văn Test"], found_names
  end

  test "không tìm thấy theo SĐT / mã / tên (UC08): không có nút tiếp tục" do
    { "0912000111" => /0912 000 111/, "KH-000999" => /KH-000999/, "Không Có Ai" => /Không Có Ai/ }.each do |query, text|
      get search_customers_path, params: { q: query }
      assert_select ".alert-notfound", text
      assert_empty found_names
    end
  end

  test "SĐT sai định dạng: báo lỗi, không tìm" do
    get search_customers_path, params: { q: "0905 12" }
    assert_select "input.input--error"
    assert_select ".error-text", /10 chữ số/
    assert_select ".alert-notfound", count: 0
  end

  test "tên quá ngắn: báo lỗi" do
    get search_customers_path, params: { q: "a" }
    assert_select ".error-text", /ít nhất 2 ký tự/
  end
end
