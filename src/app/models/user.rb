class User < ApplicationRecord
  # NFR05 – 2 vai trò: Nhân viên tiếp nhận, Quản lý trung tâm
  enum :role, { receptionist: "receptionist", manager: "manager" }, validate: true

  ROLE_LABELS = { "receptionist" => "Nhân viên tiếp nhận", "manager" => "Quản lý trung tâm" }.freeze

  has_many :warranty_requests, foreign_key: :created_by_id, inverse_of: :created_by,
                               dependent: :restrict_with_error

  validates :full_name, presence: true, length: { maximum: 100 }

  def role_label
    ROLE_LABELS[role]
  end
end
