require "test_helper"

# BR06 – hạn cam kết = thời điểm tạo + số giờ SLA
class SlaDeadlineCalculatorTest < ActiveSupport::TestCase
  test "mức Cao 24h" do
    from = Time.zone.local(2026, 10, 10, 9, 40)
    assert_equal Time.zone.local(2026, 10, 11, 9, 40),
                 SlaDeadlineCalculator.call(Priority.new(sla_hours: 24), from: from)
  end

  test "mức Khẩn cấp 8h" do
    from = Time.zone.local(2026, 10, 10, 20, 0)
    assert_equal Time.zone.local(2026, 10, 11, 4, 0),
                 SlaDeadlineCalculator.call(Priority.new(sla_hours: 8), from: from)
  end
end
