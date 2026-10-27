# Số liệu 4 thẻ thống kê Màn hình 3 (UC07) – MỖI con số đi kèm một mốc so sánh (BT2: số liệu phải có ngữ cảnh).
# Cách đếm giữ đúng quy ước của WarrantyRequestSearch: "Mới tiếp nhận" / "Đang xử lý" = còn trong hạn,
# "Quá hạn" = chưa đóng và đã qua hạn cam kết (BR10, tính – không lưu).
#
#   tiep_nhan_hom_nay  mốc: số tiếp nhận hôm qua
#   moi_tiep_nhan      mốc: tổng số yêu cầu đang mở
#   dang_xu_ly         mốc: tổng số yêu cầu đang mở
#   qua_han            kèm tỉ lệ % trên số đang mở; mốc: mục tiêu 0
class DashboardStats
  def self.call(now: Time.current) = new(now).call

  def initialize(now)
    @now = now
  end

  def call
    open_count = WarrantyRequest.open_requests.count
    overdue    = WarrantyRequest.overdue.count

    {
      tiep_nhan_hom_nay: { so: created_on(@now), moc: { ten: "hôm qua", so: created_on(@now - 1.day) } },
      moi_tiep_nhan:     { so: WarrantyRequest.received.where(due_at: @now..).count,
                           moc: { ten: "đang mở", so: open_count } },
      dang_xu_ly:        { so: WarrantyRequest.in_progress.where(due_at: @now..).count,
                           moc: { ten: "đang mở", so: open_count } },
      qua_han:           { so: overdue,
                           ty_le: open_count.zero? ? 0.0 : (overdue * 100.0 / open_count).round(1),
                           moc: { ten: "mục tiêu", so: 0 } },
      thoi_diem: @now.iso8601
    }
  end

  private

  def created_on(time)
    WarrantyRequest.where(created_at: time.all_day).count
  end
end
