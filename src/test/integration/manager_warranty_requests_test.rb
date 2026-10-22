require "test_helper"

# Kiểm thử Màn hình 3 – UC07, FR08
class ManagerWarrantyRequestsTest < ActionDispatch::IntegrationTest
  setup do
    @user     = User.create!(full_name: "Nhân viên Test", role: :receptionist)
    @category = IssueCategory.create!(name: "Màn hình")
    @other    = IssueCategory.create!(name: "Phần mềm")
    @priority = Priority.create!(name: "Cao", sla_hours: 24)

    @on_time   = create_request("BH-2026-000001", "0901000001", "Nguyễn An",  :received,    5.hours.from_now)
    @overdue   = create_request("BH-2026-000002", "0901000002", "Trần Bình",  :in_progress, 2.hours.ago)
    @completed = create_request("BH-2026-000003", "0901000003", "Lê Cường",   :completed,   3.hours.ago, @other)
  end

  def create_request(code, phone, name, status, due_at, category = @category)
    customer = Customer.create!(code: "KH-#{phone}", name: name, phone: phone)
    device   = Device.create!(customer: customer, device_type: "Điện thoại", brand: "Samsung", model: "A55",
                              serial_number: "SN-#{phone}", purchase_date: Date.current - 30)
    WarrantyRequest.create!(code: code, device: device, issue_category: category, priority: @priority,
                            created_by: @user, issue_description: "Lỗi", status: status, due_at: due_at)
  end

  test "mặc định: yêu cầu mới tạo nhất nằm đầu danh sách" do
    newest = create_request("BH-2026-000099", "0901000099", "Khách Mới", :received, 72.hours.from_now)

    get manager_warranty_requests_path
    assert_response :success
    assert_equal newest.code, css_select("tbody .code-link").first.text
  end

  test "sắp xếp theo hạn cam kết, dòng quá hạn tô đỏ" do
    get manager_warranty_requests_path(sort: "due_at")
    assert_response :success

    codes = css_select("tbody .code-link").map(&:text)
    assert_equal ["BH-2026-000003", "BH-2026-000002", "BH-2026-000001"], codes
    assert_select "tr.is-overdue", count: 1
    assert_select "tr.is-overdue .badge--overdue", "Quá hạn"
  end

  test "thẻ thống kê: mới tiếp nhận, đang xử lý (còn hạn), quá hạn" do
    get manager_warranty_requests_path
    assert_select ".stat--new .stat__value", "1"
    assert_select ".stat--doing .stat__value", "0"
    assert_select ".stat--overdue .stat__value", "1"
    assert_select ".stat--total .stat__value", "3"
  end

  test "lọc trạng thái Quá hạn" do
    get manager_warranty_requests_path(status: "overdue")
    assert_equal ["BH-2026-000002"], css_select("tbody .code-link").map(&:text)
  end

  test "tìm theo SĐT có dấu cách và theo tên khách hàng" do
    get manager_warranty_requests_path(q: "0901 000 003")
    assert_equal ["BH-2026-000003"], css_select("tbody .code-link").map(&:text)

    get manager_warranty_requests_path(q: "Trần")
    assert_equal ["BH-2026-000002"], css_select("tbody .code-link").map(&:text)
  end

  test "lọc theo nhóm sự cố" do
    get manager_warranty_requests_path(issue_category_id: @other.id)
    assert_equal ["BH-2026-000003"], css_select("tbody .code-link").map(&:text)
  end

  test "UC07 5a – không có kết quả phù hợp" do
    get manager_warranty_requests_path(q: "không-tồn-tại")
    assert_select ".table__empty", /Không có yêu cầu phù hợp/
  end

  test "phân trang 8 dòng mỗi trang" do
    7.times { |i| create_request("BH-2026-0001#{i}0", "09020000#{i}0", "KH #{i}", :received, (i + 10).hours.from_now) }

    get manager_warranty_requests_path
    assert_select "tbody tr", 8
    assert_select ".table-footer__info", /1–8 trên 10/

    get manager_warranty_requests_path(page: 2)
    assert_select "tbody tr", 2
    assert_select ".pagination .is-current", "2"
  end
end
