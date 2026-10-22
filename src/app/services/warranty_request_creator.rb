# UC06 – Tạo yêu cầu bảo hành và hạn cam kết xử lý
#
# Mọi thao tác ghi nằm trong MỘT transaction (NFR04):
#   1. Cập nhật họ tên khách hàng (nếu nhân viên sửa)
#   2. Tìm thiết bị theo serial, hoặc tạo thiết bị mới
#   3. Sinh mã yêu cầu (BR05) và tính hạn cam kết (BR06)
#   4. Lưu yêu cầu với trạng thái "Mới tiếp nhận" + dòng lịch sử đầu tiên
# Lỗi ở bất kỳ bước nào → rollback toàn bộ, không có dữ liệu dở dang.
class WarrantyRequestCreator
  # error_code: :invalid (thiếu/sai dữ liệu), :serial_taken (serial của khách khác),
  #             :not_found (nhóm sự cố / mức ưu tiên không tồn tại), :record_invalid
  Result = Data.define(:warranty_request, :error_code) do
    def success? = warranty_request.present?
  end

  class DeviceOwnedByAnotherCustomer < StandardError; end

  def self.call(...)
    new(...).call
  end

  def initialize(form:, customer:, created_by:)
    @form = form
    @customer = customer
    @created_by = created_by
  end

  def call
    return failure(:invalid) unless @form.valid?   # BR04 – thiếu/sai thì không tạo

    request = ActiveRecord::Base.transaction do
      update_customer_name!
      device   = find_or_create_device!
      priority = Priority.find(@form.priority_id)
      now      = Time.current

      request = WarrantyRequest.create!(
        code:              RequestCodeGenerator.next_code(year: now.year),
        device:            device,
        issue_category:    IssueCategory.find(@form.issue_category_id),
        priority:          priority,
        created_by:        @created_by,
        issue_description: @form.issue_description,
        status:            :received,
        due_at:            SlaDeadlineCalculator.call(priority, from: now)
      )

      # Dòng lịch sử đầu tiên: tiếp nhận yêu cầu
      request.status_logs.create!(from_status: nil, to_status: WarrantyRequest.statuses[:received],
                                  note: "Tiếp nhận yêu cầu", changed_by: @created_by)
      request
    end

    Result.new(warranty_request: request, error_code: nil)
  rescue DeviceOwnedByAnotherCustomer => e
    failure(:serial_taken, :serial_number, e.message)
  rescue ActiveRecord::RecordNotFound
    failure(:not_found, :base, "Nhóm sự cố hoặc mức ưu tiên không hợp lệ")
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors.each { |error| @form.errors.add(:base, error.full_message) }
    failure(:record_invalid)
  end

  private

  def update_customer_name!
    return if @customer.name == @form.customer_name

    @customer.update!(name: @form.customer_name)
  end

  def find_or_create_device!
    device = Device.find_by(serial_number: @form.serial_number)

    if device
      # NFR04 – một thiết bị không thể thuộc 2 khách hàng
      if device.customer_id != @customer.id
        raise DeviceOwnedByAnotherCustomer, "Số serial / IMEI này đã được đăng ký cho khách hàng khác"
      end
      return device
    end

    Device.create!(
      customer:             @customer,
      device_type:          @form.device_type,
      brand:                @form.brand,
      model:                @form.model,
      serial_number:        @form.serial_number,
      purchase_date:        @form.purchase_date,
      warranty_card_number: @form.warranty_card_number.presence
    )
  end

  def failure(code, attribute = nil, message = nil)
    @form.errors.add(attribute, message) if attribute
    Result.new(warranty_request: nil, error_code: code)
  end
end
