require "test_helper"

# TD-26 – Giao diện gọi API bằng phiên đăng nhập web; số liệu thống kê có mốc so sánh; danh mục ưu tiên
class ApiWebSessionTest < ActionDispatch::IntegrationTest
  self.auto_sign_in_as = :receptionist

  XHR = { "X-Requested-With" => "XMLHttpRequest" }.freeze

  def json = JSON.parse(response.body)

  test "đã đăng nhập web + header XHR thì gọi được API không cần token" do
    get api_priorities_path, headers: XHR
    assert_response :ok
  end

  test "có cookie nhưng thiếu header X-Requested-With thì vẫn 401 (chống CSRF)" do
    get api_priorities_path
    assert_response :unauthorized
    assert_equal "CHUA_XAC_THUC", json["error"]
  end

  test "sau khi đăng xuất, cookie cũ không gọi được API" do
    delete session_path
    get api_priorities_path, headers: XHR
    assert_response :unauthorized
  end

  test "thống kê: mỗi con số có mốc so sánh; quá hạn tính trên số đang mở" do
    staff    = User.create!(full_name: "NV", role: :receptionist)
    customer = Customer.create!(code: "KH-960001", name: "KH", phone: "0960000001")
    device   = Device.create!(customer: customer, device_type: "Laptop", brand: "Dell", model: "X",
                              serial_number: "SN-STAT-1", purchase_date: Date.current)
    category = IssueCategory.create!(name: "Thống kê test")
    priority = Priority.create!(name: "Thống kê test", sla_hours: 24)
    base = { device: device, created_by: staff, issue_category: category, priority: priority, issue_description: "Lỗi" }
    WarrantyRequest.create!(base.merge(code: "BH-2099-000961", due_at: 1.hour.ago))                       # mở, quá hạn
    WarrantyRequest.create!(base.merge(code: "BH-2099-000962", due_at: 1.day.from_now))                   # mở
    WarrantyRequest.create!(base.merge(code: "BH-2099-000963", due_at: 1.hour.ago, status: :completed))   # đóng – không tính quá hạn

    get api_stats_path, headers: XHR
    data = json["data"]

    assert_equal 3, data["tiep_nhan_hom_nay"]["so"]
    assert_equal "hôm qua", data["tiep_nhan_hom_nay"]["moc"]["ten"]
    assert_equal 1, data["qua_han"]["so"]
    assert_equal 50.0, data["qua_han"]["ty_le"]
    assert_equal 2, data["moi_tiep_nhan"]["moc"]["so"]
  end
end
