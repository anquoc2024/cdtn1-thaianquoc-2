class Priority < ApplicationRecord
  has_many :warranty_requests, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :sla_hours, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # Thứ tự hiển thị: Thấp (72h) → Khẩn cấp (8h)
  scope :ordered, -> { order(sla_hours: :desc) }

  def label
    "#{name} · #{sla_hours}h"
  end
end
