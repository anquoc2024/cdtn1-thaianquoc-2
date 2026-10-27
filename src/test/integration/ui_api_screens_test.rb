require "test_helper"

# TD-26 – Ba màn hình gắn lớp gọi API (Stimulus + api/client.js) và thẻ thống kê có mốc so sánh
class UiApiScreensTest < ActionDispatch::IntegrationTest
  self.auto_sign_in_as = :receptionist

  test "Màn hình 1 gắn controller tra cứu qua API" do
    get search_customers_path
    assert_select "[data-controller='customer-lookup'] form[data-action='submit->customer-lookup#search']"
    assert_select "[data-customer-lookup-target='results']"
  end

  test "Màn hình 2 gửi form qua API, có vùng báo lỗi" do
    customer = Customer.create!(code: "KH-970001", name: "Khách UI", phone: "0970000001")
    IssueCategory.create!(name: "UI test")
    Priority.create!(name: "UI test", sla_hours: 24)

    get new_warranty_request_path(customer_id: customer.id)
    assert_select "form[data-controller='request-submit'][data-request-submit-customer-id-value='#{customer.id}']"
    assert_select "[data-request-submit-target='banner']"
  end

  test "Màn hình 2 báo trạng thái rỗng khi chưa có danh mục nhóm sự cố" do
    customer = Customer.create!(code: "KH-970002", name: "Khách UI 2", phone: "0970000002")

    get new_warranty_request_path(customer_id: customer.id)
    assert_select ".form-errors", /Chưa có danh mục nhóm sự cố/
  end

  test "Màn hình 3 gắn controller danh sách; mỗi thẻ thống kê có mốc so sánh" do
    get manager_warranty_requests_path
    assert_select "[data-controller='request-list'] [data-request-list-target='tbody']"
    assert_select ".stat--total .stat__ref", /hôm qua: 0/
    assert_select ".stat--overdue .stat__ref", /mục tiêu: 0/
  end
end
