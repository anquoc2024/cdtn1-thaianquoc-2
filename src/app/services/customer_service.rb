# CRUD Khách hàng (TD-25) – lớp nghiệp vụ, không chứa params / render / mã HTTP
#
# Quy tắc nghiệp vụ:
#   BR01  Số điện thoại 10 chữ số, bắt đầu bằng 0, DUY NHẤT (chuẩn hóa "0905 123 456" → "0905123456")
#   BR12  Mã khách hàng tự sinh KH-NNNNNN, dải 000001–099999 (dải 1xxxxx dành cho dữ liệu nạp từ CSV – TD-23)
#   BR13  Không xóa khách hàng đã có thiết bị – giữ lịch sử bảo hành
class CustomerService
  FIELDS          = %i[name phone email address].freeze
  MANUAL_CODE_MAX = 99_999
  CODE_LOCK_KEY   = 2_026_001   # khóa advisory riêng cho việc sinh mã khách hàng

  def self.create(attributes)                   = new.create(attributes)
  def self.update(customer, attributes)         = new.update(customer, attributes)
  def self.destroy(customer)                    = new.destroy(customer)

  def create(attributes)
    Customer.transaction do
      Customer.connection.execute("SELECT pg_advisory_xact_lock(#{CODE_LOCK_KEY})")
      customer = Customer.new(attributes.to_h.symbolize_keys.slice(*FIELDS))
      customer.code = next_code
      save(customer)
    end
  end

  def update(customer, attributes)
    customer.assign_attributes(attributes.to_h.symbolize_keys.slice(*FIELDS))
    save(customer)
  end

  def destroy(customer)
    if customer.devices.exists?
      return ServiceResult.failure(:in_use,
                                "Không xóa được khách hàng #{customer.code} vì đã có thiết bị và lịch sử bảo hành (BR13).",
                                record: customer)
    end

    customer.destroy!
    ServiceResult.ok(customer)
  end

  private

  def save(customer)
    return ServiceResult.ok(customer) if customer.save

    code = customer.errors.of_kind?(:phone, :taken) ? :duplicate : :invalid
    ServiceResult.failure(code, "Thông tin khách hàng không hợp lệ.", errors: FieldErrors.of(customer), record: customer)
  rescue ActiveRecord::RecordNotUnique
    ServiceResult.failure(:duplicate, "Số điện thoại đã thuộc khách hàng khác.",
                       errors: [{ truong: "phone", ly_do: "đã tồn tại" }], record: customer)
  end

  # KH-000253 → KH-000254; bỏ qua dải 1xxxxx của dữ liệu nạp
  def next_code
    last = Customer.where("code ~ '^KH-0[0-9]{5}$'").maximum(:code)
    number = last.to_s.delete_prefix("KH-").to_i + 1
    raise "Đã hết dải mã khách hàng nhập tay" if number > MANUAL_CODE_MAX

    format("KH-%06d", number)
  end
end
