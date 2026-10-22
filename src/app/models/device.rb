class Device < ApplicationRecord
  belongs_to :customer
  has_many :warranty_requests, dependent: :restrict_with_error

  # BR02 – thông tin bắt buộc của thiết bị
  validates :device_type, :brand, :model, presence: true
  validates :serial_number, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :purchase_date, presence: true
  validate  :purchase_date_cannot_be_in_the_future

  def display_name
    "#{brand} #{model}"
  end

  private

  def purchase_date_cannot_be_in_the_future
    return if purchase_date.blank? || purchase_date <= Date.current

    errors.add(:purchase_date, "không được lớn hơn ngày hiện tại")
  end
end
