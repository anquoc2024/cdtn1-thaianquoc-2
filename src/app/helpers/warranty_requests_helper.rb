module WarrantyRequestsHelper
  # Thêm viền đỏ khi trường có lỗi
  def field_classes(form, attribute, base = "input")
    [base, ("input--error" if form.object.errors.include?(attribute))].compact.join(" ")
  end

  # Dòng báo lỗi ngay dưới trường
  def field_error(form, attribute)
    message = form.object.errors[attribute].first
    tag.p("⚠︎ #{message}", class: "error-text") if message
  end

  def format_datetime(time)
    time&.strftime("%d/%m/%Y %H:%M")
  end

  # Màu nhãn trạng thái – "Quá hạn" được tính, không lưu (TD-09)
  def status_badge_class(warranty_request)
    return "badge--overdue" if warranty_request.overdue?

    status_badge_class_for(warranty_request.status)
  end

  def status_badge_class_for(status_key)
    { "received" => "badge--new", "in_progress" => "badge--doing",
      "completed" => "badge--done", "cancelled" => "badge--cancelled" }.fetch(status_key.to_s, "badge--low")
  end

  # Nhãn nút chuyển trạng thái trên phiếu tiếp nhận
  def status_action_label(status_key)
    { "in_progress" => "Bắt đầu xử lý", "completed" => "Hoàn tất" }.fetch(status_key, status_key)
  end

  def priority_badge_class(priority)
    case priority.sla_hours
    when ..8  then "badge--urgent"
    when ..24 then "badge--high"
    when ..48 then "badge--medium"
    else           "badge--low"
    end
  end
end
