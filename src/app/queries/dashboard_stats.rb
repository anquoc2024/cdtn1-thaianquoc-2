# Số liệu thẻ thống kê Màn hình 3 (UC07) – MỖI con số đi kèm một mốc so sánh (BT2: "số liệu phải có ngữ cảnh")
#
#   tiep_nhan_hom_nay  so với hôm qua
#   moi_tiep_nhan      so với tổng số yêu cầu đang mở
#   dang_xu_ly         so với tổng số yêu cầu đang mở
#   qua_han            tỉ lệ trên số đang mở, mục tiêu = 0 (BR10)
class DashboardStats
  OPEN_STATUSES = %i[received in_progress].freeze

  def self.call(now: Time.current) = new(now).call

  def initialize(now)
    @now = now
  end

  def call
    open_scope = WarrantyRequest.where(status: OPEN_STATUSES)
    open_count = open_scope.count
    overdue    = open_scope.where("due_at < ?", @now).count
    today      = @now.all_day
    yesterday  = (@now - 1.day).all_day

    {
      tiep_nhan_hom_nay: { so: WarrantyRequest.where(created_at: today).count,
                           moc: { ten: "hôm qua", so: WarrantyRequest.where(created_at: yesterday).count } },
      moi_tiep_nhan:     { so: WarrantyRequest.where(status: :received).count,
                           moc: { ten: "đang mở", so: open_count } },
      dang_xu_ly:        { so: WarrantyRequest.where(status: :in_progress).count,
                           moc: { ten: "đang mở", so: open_count } },
      qua_han:           { so: overdue,
                           ty_le: open_count.zero? ? 0.0 : (overdue * 100.0 / open_count).round(1),
                           moc: { ten: "mục tiêu", so: 0 } },
      thoi_diem: @now.iso8601
    }
  end
end
