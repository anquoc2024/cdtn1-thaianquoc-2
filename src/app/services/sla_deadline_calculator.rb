# BR06 – Hạn cam kết = thời điểm tạo + số giờ SLA của mức ưu tiên
class SlaDeadlineCalculator
  def self.call(priority, from: Time.current)
    from + priority.sla_hours.hours
  end
end
