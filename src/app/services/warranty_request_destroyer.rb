# TD-29 – Xóa yêu cầu bảo hành (Nhân viên tiếp nhận, mọi trạng thái)
# Xóa kèm lịch sử trạng thái; thiết bị và khách hàng giữ nguyên để tạo yêu cầu khác.
# Ghi log INFO mã yêu cầu + người xóa để còn dấu vết sau khi bản ghi không còn trong CSDL.
class WarrantyRequestDestroyer
  def self.call(...) = new(...).call

  def initialize(warranty_request:, deleted_by:)
    @warranty_request = warranty_request
    @deleted_by       = deleted_by
  end

  def call
    code = @warranty_request.code
    if @warranty_request.destroy
      Rails.logger.info("XOA_YEU_CAU code=#{code} trang_thai=#{@warranty_request.status} user_id=#{@deleted_by.id}")
      ServiceResult.ok(@warranty_request)
    else
      ServiceResult.failure(:in_use, "Không xóa được yêu cầu #{code}: #{@warranty_request.errors.full_messages.to_sentence}")
    end
  end
end
