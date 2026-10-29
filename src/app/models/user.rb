class User < ApplicationRecord
  # NFR05 – 2 vai trò: Nhân viên tiếp nhận, Quản lý trung tâm
  enum :role, { receptionist: "receptionist", manager: "manager" }, validate: true

  ROLE_LABELS = { "receptionist" => "Nhân viên tiếp nhận", "manager" => "Quản lý trung tâm" }.freeze

  # Bảng phân quyền (TD-24, mở rộng ở TD-29):
  #   Nhân viên tiếp nhận – làm toàn bộ nghiệp vụ: tra cứu, tạo, đổi trạng thái, SỬA và XÓA yêu cầu, CRUD danh mục
  #   Quản lý trung tâm   – tra cứu khách hàng, tạo yêu cầu, xem danh sách / thống kê / phiếu;
  #                         KHÔNG đổi trạng thái, không sửa / xóa yêu cầu, không sửa danh mục
  PERMISSIONS = {
    lookup_customers:  %w[receptionist manager],   # UC01, UC08 (Quản lý được thêm ở TD-29)
    create_requests:   %w[receptionist manager],   # UC02–UC06 (Quản lý được thêm ở TD-29)
    change_status:     %w[receptionist],           # UC09, UC10
    view_requests:     %w[receptionist manager],   # Phiếu tiếp nhận
    view_request_list: %w[receptionist manager],   # UC07
    manage_customers:  %w[receptionist],           # CRUD Khách hàng (TD-25)
    manage_catalog:    %w[receptionist],           # CRUD Nhóm sự cố (TD-25)
    edit_requests:     %w[receptionist],           # Sửa yêu cầu bảo hành (TD-29)
    delete_requests:   %w[receptionist]            # Xóa yêu cầu bảo hành (TD-29)
  }.freeze

  # validations: false – tài khoản cũ / tạo trong test chưa có mật khẩu thì vẫn lưu được,
  # nhưng KHÔNG đăng nhập được (authenticate_by trả nil khi chưa có password_digest).
  has_secure_password validations: false
  has_secure_token :api_token

  has_many :sessions, dependent: :destroy
  has_many :warranty_requests, foreign_key: :created_by_id, inverse_of: :created_by,
                               dependent: :restrict_with_error

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :full_name, presence: true, length: { maximum: 100 }
  validates :email_address, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP },
                            length: { maximum: 255 }, allow_nil: true
  validates :password, length: { minimum: 8, maximum: 72 }, allow_nil: true
  validates :password, presence: true, if: -> { email_address.present? && password_digest.blank? }

  def role_label
    ROLE_LABELS[role]
  end

  def can?(permission)
    PERMISSIONS.fetch(permission).include?(role)
  end

  # "Thái An Quốc" → "TQ"
  def initials
    words = full_name.to_s.split
    [words.first, words.last].compact.uniq.map { |word| word[0] }.join.upcase
  end
end
