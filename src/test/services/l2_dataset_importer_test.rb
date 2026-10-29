require "test_helper"
require "tmpdir"

# TD-28 – nạp bộ dữ liệu L2 của giảng viên: khách, thiết bị, phiếu bảo hành; loại dòng lỗi; chạy lại không nhân đôi
class L2DatasetImporterTest < ActiveSupport::TestCase
  FILES = {
    "issue_categories.csv" => <<~CSV,
      category_id,category_name,default_priority
      1,Màn hình,CAO
      2,Pin,TRUNG_BINH
    CSV
    "customers.csv" => <<~CSV,
      customer_id,full_name,phone,email,address,source
      561,Lý Văn Như,0793573965,,"211 Trần Hưng Đạo, Thốt Nốt",customers_raw.csv
      728,Trần Tuấn Mỹ,+84336424821,MY97@outlook.com,,customers_raw.csv
      900,Khách SĐT lỗi,0123,,,customers_raw.csv
    CSV
    "products.csv" => <<~CSV,
      product_id,product_name,default_warranty_months
      34,Samsung Pro+ 13,12
      130,realme Tab A11,12
      246,Nokia Cáp Type-C Lite7,6
    CSV
    "devices.csv" => <<~CSV,
      device_id,customer_id,product_id,serial_no,purchase_date,warranty_months,is_warranty,source
      1,561,34,SN-A,2026-06-09,12,true,tickets_history.csv
      2,728,130,SN-B,2026-09-14,12,true,tickets_history.csv
      3,728,246,SN-C,,6,,TU_BO_SUNG
    CSV
    "tickets.csv" => <<~CSV
      source_ticket_id,customer_id,product_id,serial_no,center_id,issue_desc,category_id,priority,is_warranty,hours_ago
      1,561,34,SN-A,1,  CẮM SẠC MÁY NÓNG BẤT THƯỜNG ,2,TRUNG_BINH,true,100
      2,728,130,SN-B,1,màn hình bị sọc dọc,1,CAO,true,4
      3,728,246,SN-C,1,cáp không sạc được,2,THAP,true,1
    CSV
  }.freeze

  setup do
    @dir = Dir.mktmpdir("l2")
    FILES.each { |name, content| File.write(File.join(@dir, name), content) }
    @user = User.create!(full_name: "NV test", role: :receptionist)
    @now  = Time.zone.parse("2026-10-29 10:00")
  end

  teardown { FileUtils.remove_entry(@dir) }

  test "nạp khách, thiết bị, yêu cầu hợp lệ; loại SĐT sai và thiết bị thiếu ngày mua" do
    result = L2DatasetImporter.call(@dir, created_by: @user, now: @now)

    assert_equal [2, 0], result.counts[:khach_hang]
    assert_equal [2, 0], result.counts[:thiet_bi]
    assert_equal [2, 0], result.counts[:yeu_cau]
    assert_equal ["customers.csv", "devices.csv", "tickets.csv"], result.rejected.map(&:first)

    customer = Customer.find_by!(phone: "0336424821")                    # +84 → 0
    assert_equal "KH-100728", customer.code
    assert_equal "my97@outlook.com", customer.email

    tablet = Device.find_by!(serial_number: "SN-B")
    assert_equal ["Realme", "Tab A11", "Máy tính bảng"], [tablet.brand, tablet.model, tablet.device_type]

    request = Device.find_by!(serial_number: "SN-A").warranty_requests.first
    assert_equal "Cắm sạc máy nóng bất thường", request.issue_description  # bỏ IN HOA, khoảng trắng thừa
    assert_equal @now - 100.hours, request.created_at
    assert_equal request.created_at + 48.hours, request.due_at             # Trung bình 48h (BR06)
    assert request.received?
    assert_equal 1, request.status_logs.count
  end

  test "chạy lại lần hai không nhân đôi dữ liệu" do
    L2DatasetImporter.call(@dir, created_by: @user, now: @now)

    assert_no_difference ["Customer.count", "Device.count", "WarrantyRequest.count"] do
      result = L2DatasetImporter.call(@dir, created_by: @user, now: @now)
      assert_equal [0, 2], result.counts[:yeu_cau]
    end
  end

  test "báo thiếu tệp thay vì nạp dở dang" do
    File.delete(File.join(@dir, "tickets.csv"))

    error = assert_raises(ArgumentError) { L2DatasetImporter.call(@dir, created_by: @user, now: @now) }
    assert_match "tickets.csv", error.message
  end
end
