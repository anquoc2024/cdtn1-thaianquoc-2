# Lớp cha của mọi API JSON (/api/...)
#
# – Kế thừa ActionController::API: không có view, cookie, CSRF – chỉ nhận và trả JSON
# – Mọi lỗi trả về cùng một dạng: {"error": "MA_LOI", "message": "...", "chi_tiet": {...}}
# – Xác thực (TD-24, TD-26), theo thứ tự:
#     1. Token: header Authorization: Bearer <users.api_token>   – curl, Postman
#     2. Cookie đăng nhập web + header X-Requested-With: XMLHttpRequest – api/client.js trên giao diện.
#        Header bắt buộc này cùng cookie SameSite=Lax chặn trang web lạ gọi API thay người dùng (CSRF).
#     thiếu / sai → 401 CHUA_XAC_THUC · không đủ quyền → 403 KHONG_CO_QUYEN
# – Lỗi hệ thống (TD-27, xem SystemErrorHandling): mất CSDL → 503 · lỗi khác → 500, cả hai kèm mã tra cứu.
#   rescue_from khai báo SAU được ưu tiên, nên StandardError đứng đầu, lỗi cụ thể đứng sau.
module Api
  class BaseController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods
    include ActionController::Cookies
    include SystemErrorHandling

    rescue_from StandardError do |exception|
      log_system_error(exception, "LOI_HE_THONG")
      render_error(:internal_server_error, "LOI_HE_THONG", internal_error_message, ma_tra_cuu: lookup_code)
    end

    rescue_from(*SystemErrorHandling::DATABASE_UNAVAILABLE_ERRORS) do |exception|
      log_system_error(exception, "CSDL_KHONG_KHA_DUNG")
      response.set_header("Retry-After", SystemErrorHandling::RETRY_AFTER_SECONDS.to_s)
      render_error(:service_unavailable, "CSDL_KHONG_KHA_DUNG", database_unavailable_message, ma_tra_cuu: lookup_code)
    end

    rescue_from ActiveRecord::RecordNotFound do
      render_error(:not_found, "KHONG_TIM_THAY", "Không tìm thấy dữ liệu với mã đã cho.")
    end

    rescue_from ActionController::ParameterMissing do |exception|
      render_error(:bad_request, "DU_LIEU_KHONG_HOP_LE", "Thiếu tham số bắt buộc: #{exception.param}.")
    end

    before_action :authenticate_api_user!

    private

    attr_reader :current_user

    def authenticate_api_user!
      @current_user = authenticate_with_http_token do |token, _options|
        User.find_by(api_token: token) if token.present?
      end
      @current_user ||= user_from_web_session
      return if @current_user

      render_error(:unauthorized, "CHUA_XAC_THUC",
                   "Thiếu hoặc sai token. Gửi header Authorization: Bearer <api_token>.")
    end

    # Giao diện web gọi API bằng fetch: dùng lại phiên đăng nhập (cookie session_id đã ký)
    def user_from_web_session
      return unless request.headers["X-Requested-With"] == "XMLHttpRequest"

      session_id = cookies.signed[:session_id]
      Session.find_by(id: session_id)&.user if session_id
    end

    def require_permission!(permission)
      return if current_user.can?(permission)

      render_error(:forbidden, "KHONG_CO_QUYEN",
                   "Vai trò #{current_user.role_label} không có quyền thực hiện thao tác này.")
    end

    # Lỗi phía người dùng (4xx) ghi INFO – là tình huống bình thường, không phải sự cố.
    # Lỗi 5xx đã được ghi ERROR một lần trong rescue_from ở trên.
    def render_error(status, code, message, chi_tiet = nil)
      if Rack::Utils.status_code(status) < 500
        Rails.logger.info("#{code} ma_tra_cuu=#{lookup_code} user_id=#{user_id_for_log || '-'} #{request.method} #{request.path}")
      end
      body = { error: code, message: message }
      body[:chi_tiet] = chi_tiet if chi_tiet.present?
      render json: body, status: status
    end
  end
end
