# UC01 – Tra cứu khách hàng theo SỐ ĐIỆN THOẠI, MÃ KHÁCH HÀNG hoặc TÊN
# UC08 – Thông báo khi không tìm thấy khách hàng
#
# Cách nhận biết từ khóa:
#   "0905 123 456"         → số điện thoại (bắt đầu bằng 0, phải đủ 10 chữ số – FR01)
#   "KH-000245" / "245"    → mã khách hàng
#   "Trần Thị Bình" / "binh" → tên (không phân biệt hoa thường, có dấu hay không dấu)
#
# Trạng thái trả về:
#   :blank     – chưa nhập gì
#   :invalid   – từ khóa sai định dạng → không truy vấn database
#   :found     – tìm thấy đúng 1 khách hàng
#   :multiple  – tìm theo tên ra nhiều khách hàng
#   :not_found – không tìm thấy (BR07)
class CustomerLookupService
  Result = Data.define(:status, :query, :mode, :customers, :error) do
    def customer   = customers.first
    def found?     = status == :found
    def multiple?  = status == :multiple
    def not_found? = status == :not_found
    def invalid?   = status == :invalid
  end

  CODE_PATTERN   = /\AKH-?(\d{1,6})\z/i
  MAX_RESULTS    = 20
  PHONE_INVALID  = "Số điện thoại phải gồm 10 chữ số, bắt đầu bằng 0.".freeze
  NAME_TOO_SHORT = "Nhập ít nhất 2 ký tự để tìm theo tên.".freeze

  def self.call(query)
    new(query).call
  end

  def initialize(query)
    @query = query.to_s.squish
  end

  def call
    return result(:blank) if @query.empty?

    if (match = @query.delete(" ").match(CODE_PATTERN))
      by_code(match[1])
    elsif @query.match?(/\A[\d\s.\-]+\z/)       # chỉ gồm chữ số
      by_digits(@query.gsub(/\D/, ""))
    else
      by_name
    end
  end

  private

  # Bắt đầu bằng 0 → số điện thoại; còn lại (tối đa 6 số) → mã khách hàng
  def by_digits(digits)
    if digits.start_with?("0")
      return result(:invalid, mode: :phone, error: PHONE_INVALID) unless digits.match?(Customer::PHONE_FORMAT)

      single(Customer.find_by(phone: digits), :phone)   # chỉ mục UNIQUE trên phone (NFR01)
    elsif digits.length <= 6
      by_code(digits)
    else
      result(:invalid, mode: :phone, error: PHONE_INVALID)
    end
  end

  def by_code(number)
    single(Customer.find_by(code: format("KH-%06d", number.to_i)), :code)
  end

  def by_name
    return result(:invalid, mode: :name, error: NAME_TOO_SHORT) if @query.length < 2

    pattern   = "%#{Customer.sanitize_sql_like(@query)}%"
    customers = Customer.where("unaccent(name) ILIKE unaccent(?)", pattern)
                        .order(:name).limit(MAX_RESULTS).to_a

    case customers.size
    when 0 then result(:not_found, mode: :name)
    when 1 then result(:found, mode: :name, customers: customers)
    else        result(:multiple, mode: :name, customers: customers)
    end
  end

  def single(customer, mode)
    customer ? result(:found, mode: mode, customers: [customer]) : result(:not_found, mode: mode)
  end

  def result(status, mode: nil, customers: [], error: nil)
    Result.new(status: status, query: @query, mode: mode, customers: customers, error: error)
  end
end
