# Form object cho Màn hình 2: gom dữ liệu khách hàng + thiết bị + yêu cầu
# và kiểm tra dữ liệu bắt buộc trước khi lưu (BR02, BR03, BR04).
class WarrantyRequestForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  DEVICE_TYPES = ["Điện thoại", "Laptop", "Máy tính bảng", "Tai nghe", "Đồng hồ thông minh", "Khác"].freeze
  BRANDS = ["Samsung", "Apple", "Xiaomi", "Oppo", "Dell", "HP", "Acer", "Asus", "Lenovo", "Sony", "Khác"].freeze

  attribute :customer_name, :string
  attribute :device_type, :string
  attribute :brand, :string
  attribute :model, :string
  attribute :serial_number, :string
  attribute :purchase_date, :date
  attribute :warranty_card_number, :string
  attribute :issue_description, :string
  attribute :issue_category_id, :integer
  attribute :priority_id, :integer

  validates :customer_name, presence: { message: "Vui lòng nhập họ tên khách hàng" },
                            length: { maximum: 100, message: "Họ tên tối đa 100 ký tự" }
  validates :device_type, presence: { message: "Vui lòng chọn loại thiết bị" }
  validates :brand, presence: { message: "Vui lòng chọn hãng" }
  validates :model, presence: { message: "Vui lòng nhập model" }
  validates :serial_number, presence: { message: "Vui lòng nhập số serial / IMEI" },
                            length: { maximum: 50, message: "Số serial / IMEI tối đa 50 ký tự" }
  validates :purchase_date, presence: { message: "Vui lòng nhập ngày mua" }
  validates :issue_description, presence: { message: "Vui lòng nhập mô tả lỗi" },
                                length: { maximum: 1000, message: "Mô tả lỗi tối đa 1000 ký tự" }
  validates :issue_category_id, presence: { message: "Vui lòng chọn nhóm sự cố" }
  validates :priority_id, presence: { message: "Vui lòng chọn mức độ ưu tiên" }
  validate  :purchase_date_cannot_be_in_the_future

  # Để form_with sinh tên tham số warranty_request[...]
  def self.model_name
    ActiveModel::Name.new(self, nil, "WarrantyRequest")
  end

  def serial_number=(value)
    super(value.to_s.strip.presence)
  end

  def customer_name=(value)
    super(value.to_s.squish.presence)
  end

  private

  def purchase_date_cannot_be_in_the_future
    return if purchase_date.blank? || purchase_date <= Date.current

    errors.add(:purchase_date, "Ngày mua không được lớn hơn ngày hiện tại")
  end
end
