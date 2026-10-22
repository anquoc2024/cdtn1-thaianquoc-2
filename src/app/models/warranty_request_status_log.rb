# Lịch sử đổi trạng thái của yêu cầu bảo hành – mỗi lần đổi một dòng, không sửa không xóa
class WarrantyRequestStatusLog < ApplicationRecord
  belongs_to :warranty_request
  belongs_to :changed_by, class_name: "User"

  validates :to_status, presence: true, inclusion: { in: WarrantyRequest.statuses.values }
  validates :note, length: { maximum: 500 }

  # from_status / to_status lưu giá trị trong DB ("new", "in_progress"…) → nhãn tiếng Việt
  def self.label_for(db_value)
    return "—" if db_value.blank?

    WarrantyRequest::STATUS_LABELS[WarrantyRequest.statuses.key(db_value)]
  end

  def from_label = self.class.label_for(from_status)
  def to_label   = self.class.label_for(to_status)
end
