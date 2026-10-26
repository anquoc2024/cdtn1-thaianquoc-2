require "test_helper"
require "tempfile"

# TD-23 – nạp khách hàng từ customers_raw.csv: làm sạch, gộp trùng SĐT, bỏ qua khách đã có, ghi dòng bị loại
class CustomerCsvImporterTest < ActiveSupport::TestCase
  CSV_CONTENT = <<~CSV
    record_id,ho_ten,so_dien_thoai,email,dia_chi,ngay_tao
    1,Phan Hữu Bình,0763247885,,"252 Điện Biên Phủ, TP. Thủ Đức",2024-05-26
    2,đỗ đức tâm,0760.833.592,,"203 Nguyễn Trãi, Cầu Giấy",2025-01-13
    3,Trần Kim Linh,+84899260912,,,2025-02-01
    4,Vũ Hoài Yến,,,"252 Cách Mạng Tháng 8",2025-05-24
    5,Ngô Gia Vinh,0905 12,,,2024-09-09
    6,Phan Hữu Bình,0763 247 885,binh72@yahoo.com,,2025-06-01
    7,Khách Trùng Hệ Thống,0811111111,,,2025-01-01
  CSV

  setup do
    Customer.create!(code: "KH-000001", name: "Khách có sẵn", phone: "0811111111")
    @file = Tempfile.new(["customers_raw", ".csv"])
    @file.write(CSV_CONTENT)
    @file.close
  end

  teardown { @file.unlink }

  test "nạp khách hợp lệ, gộp trùng SĐT, bỏ qua khách đã có và loại dòng lỗi" do
    result = nil
    assert_difference "Customer.count", 3 do
      result = CustomerCsvImporter.call(@file.path)
    end

    assert_equal 7, result.read
    assert_equal 3, result.imported
    assert_equal 1, result.merged
    assert_equal 1, result.skipped
    assert_equal [[4, "Thiếu số điện thoại"], [5, "SĐT sai định dạng: 0905 12"]], result.rejected
  end

  test "dòng trùng SĐT giữ bản mới nhất và lấy thêm email, địa chỉ từ bản còn lại" do
    CustomerCsvImporter.call(@file.path)

    binh = Customer.find_by!(phone: "0763247885")
    assert_equal "KH-100006", binh.code
    assert_equal "binh72@yahoo.com", binh.email
    assert_equal "252 Điện Biên Phủ, TP. Thủ Đức", binh.address
    assert_equal Date.new(2025, 6, 1), binh.created_at.to_date

    assert_equal "Đỗ Đức Tâm", Customer.find_by!(phone: "0760833592").name
    assert_equal "KH-100003", Customer.find_by!(phone: "0899260912").code
  end

  test "chạy lại không tạo trùng (idempotent)" do
    CustomerCsvImporter.call(@file.path)

    assert_no_difference "Customer.count" do
      assert_equal 0, CustomerCsvImporter.call(@file.path).imported
    end
  end

  test "giới hạn số dòng đọc và ghi file danh sách dòng bị loại" do
    reject_path = Rails.root.join("tmp/test/customers_reject.csv")
    result = CustomerCsvImporter.call(@file.path, limit: 4, reject_path: reject_path)

    assert_equal 4, result.read
    assert_equal ["record_id,ly_do", "4,Thiếu số điện thoại"], File.readlines(reject_path, chomp: true)
  ensure
    FileUtils.rm_f(reject_path)
  end

  test "khách nạp từ bộ mẫu tra cứu được theo mã KH và họ tên không dấu (UC01)" do
    CustomerCsvImporter.call(@file.path)

    assert_equal "Đỗ Đức Tâm", CustomerLookupService.call("KH-100002").customer.name
    assert CustomerLookupService.call("tran kim linh").found?
  end
end
