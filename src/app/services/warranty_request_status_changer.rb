# Cập nhật trạng thái / hủy yêu cầu bảo hành (phần U và D của CRUD)
#
# Quy tắc:
#   – Chỉ chuyển theo WarrantyRequest::TRANSITIONS (Mới → Đang xử lý → Hoàn tất, hủy khi chưa hoàn tất)
#   – Yêu cầu đã Hoàn tất / Đã hủy thì không đổi được nữa
#   – Hủy bắt buộc ghi lý do
#   – Đổi trạng thái và ghi lịch sử nằm trong CÙNG một transaction, có khóa dòng
#     để 2 người bấm cùng lúc không ghi đè nhau (NFR04)
class WarrantyRequestStatusChanger
  Result = Data.define(:warranty_request, :error_code, :error) do
    def success? = error_code.nil?
  end

  MESSAGES = {
    invalid_status:     "Trạng thái không hợp lệ.",
    closed:             "Yêu cầu đã đóng (Hoàn tất hoặc Đã hủy), không thể đổi trạng thái.",
    invalid_transition: "Không thể chuyển từ “%<from>s” sang “%<to>s”.",
    note_required:      "Vui lòng nhập lý do hủy yêu cầu."
  }.freeze

  def self.call(...)
    new(...).call
  end

  def initialize(warranty_request:, to_status:, changed_by:, note: nil)
    @warranty_request    = warranty_request
    @to_status  = to_status.to_s
    @changed_by = changed_by
    @note       = note.to_s.strip.presence
  end

  def call
    return failure(:invalid_status) unless WarrantyRequest::STATUS_LABELS.key?(@to_status)
    return failure(:note_required) if @to_status == "cancelled" && @note.nil?

    error_code = nil

    @warranty_request.with_lock do                      # SELECT … FOR UPDATE
      if @warranty_request.closed?
        error_code = :closed
      elsif !@warranty_request.allowed_next_statuses.include?(@to_status)
        error_code = :invalid_transition
      else
        from_db_value = WarrantyRequest.statuses[@warranty_request.status]   # "new", "in_progress"…
        @warranty_request.status    = @to_status
        @warranty_request.closed_at = Time.current if @warranty_request.closed?
        @warranty_request.save!

        @warranty_request.status_logs.create!(
          from_status: from_db_value,
          to_status:   WarrantyRequest.statuses[@to_status],
          note:        @note,
          changed_by:  @changed_by
        )
      end
    end

    return failure(error_code) if error_code

    Result.new(warranty_request: @warranty_request, error_code: nil, error: nil)
  end

  private

  def failure(code)
    message = format(MESSAGES.fetch(code),
                     from: WarrantyRequest::STATUS_LABELS[@warranty_request.status],
                     to:   WarrantyRequest::STATUS_LABELS[@to_status] || @to_status)
    Result.new(warranty_request: @warranty_request, error_code: code, error: message)
  end
end
