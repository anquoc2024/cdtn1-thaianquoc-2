# UC07 – Lọc, tìm kiếm và phân trang danh sách yêu cầu bảo hành (Màn hình 3)
#
# Quy ước trạng thái hiển thị:
#   "Mới tiếp nhận" / "Đang xử lý" = còn trong hạn
#   "Quá hạn"  = chưa hoàn tất và due_at < hiện tại (giá trị tính, không lưu)
#   "Hoàn tất" = đã hoàn tất
#   "Đã hủy"   = đã hủy (S2)
class WarrantyRequestSearch
  PER_PAGE = 8

  STATUS_OPTIONS = [
    ["Tất cả", ""],
    ["Mới tiếp nhận", "received"],
    ["Đang xử lý", "in_progress"],
    ["Quá hạn", "overdue"],
    ["Hoàn tất", "completed"],
    ["Đã hủy", "cancelled"]
  ].freeze

  # Mặc định: yêu cầu MỚI TẠO lên đầu, để vừa tạo xong là thấy ngay
  SORT_OPTIONS = [
    ["Mới tạo nhất", "newest"],
    ["Hạn cam kết gần nhất", "due_at"]
  ].freeze

  def initialize(params = {})
    @params = params.to_h.with_indifferent_access
  end

  # ---------- Giá trị bộ lọc (để điền lại vào form) ----------
  def q                 = @params[:q].to_s.strip
  def status            = @params[:status].to_s
  def issue_category_id = @params[:issue_category_id].presence&.to_i
  def priority_id       = @params[:priority_id].presence&.to_i
  def from_date         = parse_date(@params[:from])
  def to_date           = parse_date(@params[:to])
  def sort              = SORT_OPTIONS.map(&:last).include?(@params[:sort]) ? @params[:sort] : "newest"

  def sort_label
    SORT_OPTIONS.find { |_label, value| value == sort }.first.downcase
  end

  def filtered?
    [q, status, issue_category_id, priority_id, from_date, to_date].any?(&:present?)
  end

  # ---------- Kết quả ----------
  def results
    scope.limit(PER_PAGE).offset((current_page - 1) * PER_PAGE)
  end

  def total_count
    @total_count ||= scope.count
  end

  def total_pages
    [(total_count / PER_PAGE.to_f).ceil, 1].max
  end

  def current_page
    @params[:page].to_i.clamp(1, total_pages)
  end

  def first_index
    total_count.zero? ? 0 : (current_page - 1) * PER_PAGE + 1
  end

  def last_index
    [current_page * PER_PAGE, total_count].min
  end

  private

  def scope
    relation = WarrantyRequest
                 .joins(device: :customer)
                 .includes(:issue_category, :priority, device: :customer)
    relation = filter_keyword(relation)
    relation = filter_status(relation)
    relation = relation.where(issue_category_id: issue_category_id) if issue_category_id
    relation = relation.where(priority_id: priority_id) if priority_id
    relation = filter_dates(relation)
    sort == "due_at" ? relation.order(:due_at, :id) : relation.order(created_at: :desc, id: :desc)
  end

  # Tìm theo mã YC, tên khách hàng, hoặc số điện thoại (bỏ dấu cách)
  def filter_keyword(relation)
    return relation if q.blank?

    like   = "%#{WarrantyRequest.sanitize_sql_like(q)}%"
    digits = q.gsub(/\D/, "")
    phone  = digits.present? ? "%#{digits}%" : nil

    relation.where(
      "warranty_requests.code ILIKE :like OR customers.name ILIKE :like OR customers.phone LIKE :phone",
      like: like, phone: phone
    )
  end

  def filter_status(relation)
    case status
    when "overdue"
      relation.merge(WarrantyRequest.overdue)
    when "received", "in_progress"
      relation.where(status: status).where(due_at: Time.current..)
    when "completed", "cancelled"
      relation.where(status: status)
    else
      relation
    end
  end

  # Lọc theo ngày tiếp nhận (created_at)
  def filter_dates(relation)
    relation = relation.where(created_at: from_date.beginning_of_day..) if from_date
    relation = relation.where(created_at: ..to_date.end_of_day) if to_date
    relation
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end
end
