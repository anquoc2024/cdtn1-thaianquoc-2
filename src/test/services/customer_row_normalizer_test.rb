require "test_helper"

# TD-23 – làm sạch một dòng customers_raw.csv (không cần database)
class CustomerRowNormalizerTest < ActiveSupport::TestCase
  def normalize(**raw)
    CustomerRowNormalizer.call({ "record_id" => "1", "ho_ten" => "Phan Hữu Bình",
                                 "so_dien_thoai" => "0763247885" }.merge(raw.transform_keys(&:to_s)),
                               today: Date.new(2026, 10, 22))
  end

  test "chuẩn hóa SĐT có dấu chấm, khoảng trắng, +84 và 84 về dạng 0xxxxxxxxx" do
    assert_equal "0760833592", normalize(so_dien_thoai: "0760.833.592").phone
    assert_equal "0793619834", normalize(so_dien_thoai: "0793 619 834").phone
    assert_equal "0899260912", normalize(so_dien_thoai: "+84899260912").phone
    assert_equal "0899260912", normalize(so_dien_thoai: "84899260912").phone
  end

  test "họ tên: bỏ khoảng trắng thừa, viết hoa chữ đầu khi toàn chữ thường hoặc toàn chữ hoa" do
    assert_equal "Hồ Hữu Linh",       normalize(ho_ten: "  hồ hữu   linh ").name
    assert_equal "Dương Quang Trung", normalize(ho_ten: "DƯƠNG QUANG TRUNG").name
    assert_equal "Hoang Kim Ha",      normalize(ho_ten: "Hoang Kim Ha").name
  end

  test "email viết thường; email sai định dạng bị bỏ trống nhưng dòng vẫn hợp lệ" do
    assert_equal "binh72@yahoo.com", normalize(email: " Binh72@Yahoo.com ").email
    row = normalize(email: "khong-phai-email")
    assert_nil row.email
    assert row.valid?
  end

  test "loại dòng thiếu SĐT, SĐT sai định dạng hoặc thiếu họ tên – kèm lý do" do
    assert_equal "Thiếu số điện thoại", normalize(so_dien_thoai: "").error
    assert_equal "SĐT sai định dạng: 0905 12", normalize(so_dien_thoai: "0905 12").error
    assert_equal "Thiếu họ tên", normalize(ho_ten: "   ").error
  end

  test "ngày tạo sai hoặc ở tương lai thì bỏ qua" do
    assert_equal Date.new(2024, 5, 26), normalize(ngay_tao: "2024-05-26").created_on
    assert_nil normalize(ngay_tao: "26/05/2024").created_on
    assert_nil normalize(ngay_tao: "2030-01-01").created_on
  end
end
