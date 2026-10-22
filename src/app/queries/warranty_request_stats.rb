# Số liệu cho 4 thẻ thống kê trên Màn hình 3
class WarrantyRequestStats
  def self.call
    now = Time.current
    {
      today:       WarrantyRequest.where(created_at: now.all_day).count,
      received:    WarrantyRequest.received.where(due_at: now..).count,
      in_progress: WarrantyRequest.in_progress.where(due_at: now..).count,
      overdue:     WarrantyRequest.overdue.count
    }
  end
end
