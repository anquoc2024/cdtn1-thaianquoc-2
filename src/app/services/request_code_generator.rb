# BR05 – Sinh mã yêu cầu duy nhất dạng BH-2026-000123
#
# Phải gọi BÊN TRONG một transaction: pg_advisory_xact_lock khóa lại cho đến khi
# transaction kết thúc, nên 2 nhân viên bấm "Tạo" cùng lúc không thể nhận cùng một mã.
# Chỉ mục UNIQUE trên warranty_requests.code là lớp chặn cuối cùng.
class RequestCodeGenerator
  PREFIX = "BH".freeze
  LOCK_KEY = 2_026_102_101

  def self.next_code(year: Time.current.year)
    WarrantyRequest.connection.execute("SELECT pg_advisory_xact_lock(#{LOCK_KEY})")

    last_code = WarrantyRequest.where("code LIKE ?", "#{PREFIX}-#{year}-%").maximum(:code)
    sequence  = last_code ? last_code.split("-").last.to_i + 1 : 1

    format("%<prefix>s-%<year>d-%<seq>06d", prefix: PREFIX, year: year, seq: sequence)
  end
end
