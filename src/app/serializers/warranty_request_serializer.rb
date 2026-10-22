# Chuyển WarrantyRequest thành Hash để trả JSON (API)
# – summary: một dòng trong danh sách
# – detail : chi tiết một yêu cầu, kèm lịch sử trạng thái
class WarrantyRequestSerializer
  def self.summary(item)
    customer = item.device.customer
    {
      id:              item.id,
      code:            item.code,
      status:          item.status,              # received | in_progress | completed | cancelled
      status_label:    item.status_label,        # "Quá hạn" nếu đã quá hạn (tính, không lưu – TD-09)
      overdue:         item.overdue?,
      priority:        item.priority.name,
      sla_hours:       item.priority.sla_hours,
      issue_category:  item.issue_category.name,
      customer_code:   customer.code,
      customer_name:   customer.name,
      customer_phone:  customer.phone,
      device:          item.device.display_name,
      created_at:      item.created_at&.iso8601,
      due_at:          item.due_at&.iso8601,
      closed_at:       item.closed_at&.iso8601
    }
  end

  def self.detail(item)
    device = item.device
    summary(item).merge(
      issue_description: item.issue_description,
      device_detail: {
        device_type: device.device_type, brand: device.brand, model: device.model,
        serial_number: device.serial_number, purchase_date: device.purchase_date&.iso8601,
        warranty_card_number: device.warranty_card_number
      },
      allowed_next_statuses: item.allowed_next_statuses,
      status_logs: item.status_logs.map do |log|
        { from: log.from_label, to: log.to_label, note: log.note,
          changed_by: log.changed_by.full_name, at: log.created_at&.iso8601 }
      end
    )
  end
end
