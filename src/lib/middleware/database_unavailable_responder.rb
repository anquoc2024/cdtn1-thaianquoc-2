# Lưới an toàn ở tầng middleware cho lỗi mất CSDL (TD-27)
#
# Phần lớn lỗi mất CSDL được rescue_from trong controller xử lý (SystemErrorHandling). Nhưng có những
# bước chạy TRƯỚC controller cũng chạm CSDL – ví dụ ở môi trường phát triển, middleware kiểm tra migration
# (ActiveRecord::Migration::CheckPending). Lỗi ở đó không tới được controller, nên được bắt tại đây:
#   /api/...  → 503 JSON {"error":"CSDL_KHONG_KHA_DUNG", ...}
#   trang web → 503 trang lỗi thân thiện (cùng template errors/show)
# Cả hai kèm mã tra cứu = request_id và header Retry-After; ghi log ERROR một lần.
#
# Đăng ký trong config/application.rb, ngay sau ActionDispatch::DebugExceptions.
# Nằm trong lib/middleware (không tự nạp lại) vì middleware được tạo một lần khi khởi động.
class DatabaseUnavailableResponder
  RETRY_AFTER = "30"

  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::ConnectionFailed => e
    respond_unavailable(ActionDispatch::Request.new(env), e)
  end

  private

  def respond_unavailable(request, exception)
    code = request.request_id
    Rails.logger.error(
      "CSDL_KHONG_KHA_DUNG ma_tra_cuu=#{code} #{request.request_method} #{request.path} – " \
      "#{exception.class}: #{exception.message.lines.first.to_s.strip} (bắt ở middleware)"
    )
    message = "Hệ thống tạm thời không truy cập được dữ liệu. Vui lòng thử lại sau ít phút. Mã tra cứu: #{code}"

    if request.path.start_with?("/api")
      body = { error: "CSDL_KHONG_KHA_DUNG", message: message, chi_tiet: { ma_tra_cuu: code } }.to_json
      [503, { "content-type" => "application/json; charset=utf-8", "retry-after" => RETRY_AFTER }, [body]]
    else
      [503, { "content-type" => "text/html; charset=utf-8", "retry-after" => RETRY_AFTER }, [error_page(request, code)]]
    end
  end

  def error_page(request, code)
    ApplicationController.render(
      template: "errors/show", layout: "error",
      assigns: {
        status_code:   503,
        error_title:   "Hệ thống tạm thời không truy cập được dữ liệu",
        error_message: "Máy chủ cơ sở dữ liệu đang không phản hồi. Dữ liệu của bạn không bị mất. " \
                       "Vui lòng đợi ít phút rồi bấm Thử lại.",
        lookup_code:   code,
        retry_url:     request.get? ? request.fullpath : "/"
      }
    )
  end
end
