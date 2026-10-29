# Form object sửa yêu cầu bảo hành (TD-29): thiết bị, mô tả lỗi, phân loại.
# Không cho đổi khách hàng và số serial – đó là danh tính của thiết bị (NFR04, BR11).
class WarrantyRequestEditForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :device_type, :string
  attribute :brand, :string
  attribute :model, :string
  attribute :purchase_date, :date
  attribute :warranty_card_number, :string
  attribute :issue_description, :string
  attribute :issue_category_id, :integer
  attribute :priority_id, :integer

  validates :device_type, presence: { message: "Vui lòng chọn loại thiết bị" }
  validates :brand, presence: { message: "Vui lòng nhập hãng" }
  validates :model, presence: { message: "Vui lòng nhập model" }
  validates :purchase_date, presence: { message: "Vui lòng nhập ngày mua" }
  validates :warranty_card_number, length: { maximum: 50, message: "Số phiếu bảo hành tối đa 50 ký tự" }
  validates :issue_description, presence: { message: "Vui lòng nhập mô tả lỗi" },
                                length: { maximum: 1000, message: "Mô tả lỗi tối đa 1000 ký tự" }
  validates :issue_category_id, presence: { message: "Vui lòng chọn nhóm sự cố" }
  validates :priority_id, presence: { message: "Vui lòng chọn mức độ ưu tiên" }
  validate  :purchase_date_cannot_be_in_the_future

  # Để form_with sinh tên tham số warranty_request[...]
  def self.model_name
    ActiveModel::Name.new(self, nil, "WarrantyRequest")
  end

  def self.from(warranty_request)
    device = warranty_request.device
    new(device_type: device.device_type, brand: device.brand, model: device.model,
        purchase_date: device.purchase_date, warranty_card_number: device.warranty_card_number,
        issue_description: warranty_request.issue_description,
        issue_category_id: warranty_request.issue_category_id, priority_id: warranty_request.priority_id)
  end

  def device_attributes
    { device_type: device_type.to_s.strip, brand: brand.to_s.strip, model: model.to_s.strip,
      purchase_date: purchase_date, warranty_card_number: warranty_card_number.to_s.strip.presence }
  end

  private

  def purchase_date_cannot_be_in_the_future
    return if purchase_date.blank? || purchase_date <= Date.current

    errors.add(:purchase_date, "Ngày mua không được lớn hơn ngày hiện tại")
  end
end
