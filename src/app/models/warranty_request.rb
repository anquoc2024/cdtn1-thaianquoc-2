class WarrantyRequest < ApplicationRecord
  # Giá trị "new" lưu trong DB; tên trong Ruby là :received
  # (không đặt là :new vì trùng với WarrantyRequest.new – xem TD-18)
  enum :status, { received: "new", in_progress: "in_progress", completed: "completed", cancelled: "cancelled" },
       default: :received, validate: true

  STATUS_LABELS = {
    "received"    => "Mới tiếp nhận",
    "in_progress" => "Đang xử lý",
    "completed"   => "Hoàn tất",
    "cancelled"   => "Đã hủy"
  }.freeze

  # Chuyển trạng thái hợp lệ (máy trạng thái):
  #   Mới tiếp nhận → Đang xử lý → Hoàn tất
  #   Hủy được khi chưa hoàn tất; đã Hoàn tất / Đã hủy thì đóng, không đổi nữa
  TRANSITIONS = {
    "received"    => %w[in_progress cancelled],
    "in_progress" => %w[completed cancelled],
    "completed"   => [],
    "cancelled"   => []
  }.freeze

  CLOSED_STATUSES = %w[completed cancelled].freeze

  belongs_to :device
  belongs_to :issue_category                     # BR03
  belongs_to :priority                           # BR03
  belongs_to :created_by, class_name: "User"
  has_one    :customer, through: :device
  has_many   :status_logs, -> { order(:created_at, :id) },
             class_name: "WarrantyRequestStatusLog", dependent: :destroy

  validates :code, presence: true, uniqueness: true, length: { maximum: 20 }  # BR05
  validates :issue_description, presence: true, length: { maximum: 1000 }    # FR03
  validates :due_at, presence: true                                          # BR06

  # "Quá hạn" không lưu thành trạng thái, mà tính từ due_at (TD-09)
  scope :open_requests, -> { where.not(status: CLOSED_STATUSES) }
  scope :overdue, -> { open_requests.where(due_at: ...Time.current) }
  scope :by_due_at, -> { order(:due_at) }

  def closed?
    CLOSED_STATUSES.include?(status)
  end

  def overdue?
    !closed? && due_at.present? && due_at < Time.current
  end

  def allowed_next_statuses
    TRANSITIONS.fetch(status)
  end

  def status_label
    overdue? ? "Quá hạn" : STATUS_LABELS[status]
  end
end
