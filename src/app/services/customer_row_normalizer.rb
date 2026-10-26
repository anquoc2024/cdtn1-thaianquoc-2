require "date"

# Làm sạch MỘT dòng của customers_raw.csv (bộ dữ liệu mẫu của giảng viên) – TD-23
#
#   ho_ten        "  hồ hữu linh "     → "Hồ Hữu Linh"   (bỏ khoảng trắng thừa, viết hoa chữ đầu
#                                                          khi cả tên toàn chữ thường / toàn chữ HOA)
#   so_dien_thoai "0760.833.592"       → "0760833592"
#                 "0793 619 834"       → "0793619834"
#                 "+84899260912"/"84…" → "0899260912"
#   email         "  Binh72@Yahoo.com" → "binh72@yahoo.com" (sai định dạng → bỏ trống, không loại dòng)
#   ngay_tao      "2024-05-26"         → Date (sai / ở tương lai → nil)
#
# Dòng bị LOẠI khi: thiếu họ tên, thiếu SĐT, SĐT sau chuẩn hóa không đúng FR01 (0 + 9 chữ số).
# Lớp này không phụ thuộc database nên kiểm thử độc lập được.
class CustomerRowNormalizer
  PHONE_FORMAT = /\A0\d{9}\z/
  EMAIL_FORMAT = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

  Row = Data.define(:record_id, :name, :phone, :email, :address, :created_on, :error) do
    def valid? = error.nil?
  end

  def self.call(raw, today: Date.today)
    new(raw, today).call
  end

  def initialize(raw, today)
    @raw   = raw.to_h.transform_keys(&:to_s)
    @today = today
  end

  def call
    Row.new(record_id: record_id, name: name, phone: phone, email: email,
            address: address, created_on: created_on, error: error)
  end

  private

  def record_id
    Integer(@raw["record_id"].to_s.strip, 10)
  rescue ArgumentError
    nil
  end

  def name
    value = clean(@raw["ho_ten"])
    return nil if value.nil?

    value = value.split(" ").map(&:capitalize).join(" ") if value == value.downcase || value == value.upcase
    value[0, 100]
  end

  def phone
    digits = @raw["so_dien_thoai"].to_s.gsub(/\D/, "")
    digits = "0#{digits[2..]}" if digits.length == 11 && digits.start_with?("84")
    digits.empty? ? nil : digits
  end

  def email
    value = clean(@raw["email"])&.downcase
    value if value&.match?(EMAIL_FORMAT)
  end

  def address
    clean(@raw["dia_chi"])&.slice(0, 255)
  end

  def created_on
    date = Date.iso8601(@raw["ngay_tao"].to_s.strip)
    date unless date > @today
  rescue Date::Error
    nil
  end

  def error
    return "record_id không hợp lệ" if record_id.nil?
    return "Thiếu họ tên" if name.nil?
    return "Thiếu số điện thoại" if phone.nil?
    return "SĐT sai định dạng: #{@raw['so_dien_thoai'].to_s.strip}" unless phone.match?(PHONE_FORMAT)

    nil
  end

  def clean(value)
    value = value.to_s.strip.gsub(/\s+/, " ")
    value.empty? ? nil : value
  end
end
