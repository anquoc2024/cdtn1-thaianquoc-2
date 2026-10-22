class Customer < ApplicationRecord
  PHONE_FORMAT = /\A0\d{9}\z/  # FR01 – 10 chữ số, bắt đầu bằng 0

  has_many :devices, dependent: :restrict_with_error
  has_many :warranty_requests, through: :devices

  # Bỏ khoảng trắng, dấu chấm, gạch ngang: "0905 123 456" -> "0905123456"
  normalizes :phone, with: ->(phone) { phone.to_s.gsub(/\D/, "") }

  validates :code, presence: true, uniqueness: true, length: { maximum: 20 }
  validates :name, presence: true, length: { maximum: 100 }
  validates :phone, presence: true, uniqueness: true,
                    format: { with: PHONE_FORMAT, message: "phải gồm 10 chữ số, bắt đầu bằng 0" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def initials
    name.split.last(2).map { |word| word[0] }.join.upcase
  end
end
