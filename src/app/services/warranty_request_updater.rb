# TD-29 – Sửa thông tin yêu cầu bảo hành (Nhân viên tiếp nhận, mọi trạng thái)
#
#   1. Kiểm tra dữ liệu (WarrantyRequestEditForm) và nhóm sự cố / mức ưu tiên có tồn tại (BR03)
#   2. Cập nhật thiết bị và yêu cầu trong MỘT transaction (NFR04)
#   3. Đổi mức ưu tiên → tính lại hạn cam kết từ thời điểm tiếp nhận (BR06)
#   4. Ghi một dòng lịch sử "Cập nhật thông tin" liệt kê các trường đã sửa
# Không có thay đổi nào thì không ghi gì. Service không biết HTTP: trả ServiceResult.
class WarrantyRequestUpdater
  FIELD_LABELS = {
    "device_type" => "loại thiết bị", "brand" => "hãng", "model" => "model", "purchase_date" => "ngày mua",
    "warranty_card_number" => "số phiếu bảo hành", "issue_description" => "mô tả lỗi",
    "issue_category_id" => "nhóm sự cố", "priority_id" => "mức ưu tiên"
  }.freeze

  def self.call(...) = new(...).call

  def initialize(warranty_request:, form:, changed_by:)
    @warranty_request = warranty_request
    @form             = form
    @changed_by       = changed_by
  end

  def call
    return invalid unless @form.valid?

    category = IssueCategory.find_by(id: @form.issue_category_id)
    priority = Priority.find_by(id: @form.priority_id)
    @form.errors.add(:issue_category_id, "Nhóm sự cố không tồn tại") unless category
    @form.errors.add(:priority_id, "Mức ưu tiên không tồn tại") unless priority
    return invalid if @form.errors.any?

    ActiveRecord::Base.transaction do
      device = @warranty_request.device
      device.assign_attributes(@form.device_attributes)
      @warranty_request.assign_attributes(issue_description: @form.issue_description.to_s.strip,
                                          issue_category: category, priority: priority)
      @warranty_request.due_at = SlaDeadlineCalculator.call(priority, from: @warranty_request.created_at) if @warranty_request.priority_id_changed?

      changed = (device.changed + @warranty_request.changed).filter_map { |field| FIELD_LABELS[field] }.uniq
      next if changed.empty?

      device.save!
      @warranty_request.save!
      status = WarrantyRequest.statuses[@warranty_request.status]
      @warranty_request.status_logs.create!(from_status: status, to_status: status, changed_by: @changed_by,
                                            note: "Sửa thông tin: #{changed.join(', ')}".first(500))
    end

    ServiceResult.ok(@warranty_request)
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each { |error| @form.errors.add(error.attribute.in?(@form.attributes.keys.map(&:to_sym)) ? error.attribute : :base, error.message) }
    invalid
  end

  private

  def invalid
    errors = @form.errors.map { |error| { truong: error.attribute.to_s, ly_do: error.message } }
    ServiceResult.failure(:invalid, "Dữ liệu vào không hợp lệ ở các trường: #{errors.map { |e| e[:truong] }.uniq.join(', ')}",
                          errors: errors, record: @warranty_request)
  end
end
