# Xử lý lỗi hệ thống dùng chung cho giao diện web và API (Buổi 11 – TD-27)
#
# Hai loại lỗi, hai đường đi:
#   – Lỗi nghiệp vụ (BR..): service trả ServiceResult có mã → controller dịch sang 4xx. KHÔNG đi qua đây.
#   – Lỗi hệ thống: không lớp nào bên dưới bắt (service, model để lỗi đi lên) → tới đây:
#       mất CSDL                → 503 CSDL_KHONG_KHA_DUNG
#       lỗi không lường trước   → 500 LOI_HE_THONG
#     Ghi log ERROR ĐÚNG MỘT LẦN tại đây, kèm mã tra cứu (= request_id, có trong header X-Request-Id).
#     Người dùng chỉ thấy câu thông báo chung + mã tra cứu; tên lớp lỗi, câu SQL, ngăn xếp chỉ nằm trong log.
#
# Tìm sự cố theo mã người dùng báo:  grep "<mã tra cứu>" log/development.log
module SystemErrorHandling
  extend ActiveSupport::Concern

  # Các lỗi nghĩa là "không nói chuyện được với CSDL" (PostgreSQL tắt, mất mạng, hết kết nối trong pool)
  DATABASE_UNAVAILABLE_ERRORS = [
    ActiveRecord::ConnectionNotEstablished,   # gồm DatabaseConnectionError, ConnectionTimeoutError
    ActiveRecord::ConnectionFailed,           # mất kết nối giữa chừng khi đang chạy câu lệnh
    *([PG::ConnectionBad] if defined?(PG::ConnectionBad))
  ].freeze

  RETRY_AFTER_SECONDS = 30

  private

  def lookup_code
    request.request_id
  end

  def log_system_error(exception, code)
    trace = Rails.backtrace_cleaner.clean(Array(exception.backtrace)).first(5)
    Rails.logger.error(
      "#{code} ma_tra_cuu=#{lookup_code} user_id=#{user_id_for_log || '-'} " \
      "#{request.method} #{request.path} – #{exception.class}: #{exception.message}" +
      trace.map { |line| "\n    #{line}" }.join
    )
  end

  # Chỉ đọc giá trị ĐÃ CÓ trong bộ nhớ – không truy vấn CSDL (có thể chính CSDL đang hỏng)
  def user_id_for_log
    instance_variable_get(:@current_user)&.id || Current.session&.user_id
  end

  def database_unavailable_message
    "Hệ thống tạm thời không truy cập được dữ liệu. Vui lòng thử lại sau ít phút. Mã tra cứu: #{lookup_code}"
  end

  def internal_error_message
    "Hệ thống đang gặp sự cố. Vui lòng thử lại; nếu vẫn lỗi, báo cho quản trị kèm mã tra cứu: #{lookup_code}"
  end
end
