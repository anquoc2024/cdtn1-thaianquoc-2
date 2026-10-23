# Lớp cha của mọi API JSON (/api/...)
#
# – Kế thừa ActionController::API: không có view, cookie, CSRF – chỉ nhận và trả JSON
# – Mọi lỗi trả về cùng một dạng: {"error": "MA_LOI", "message": "...", "chi_tiet": {...}}
# – Xác thực bằng token (TD-24): header Authorization: Bearer <users.api_token>
#     thiếu / sai token → 401 CHUA_XAC_THUC · không đủ quyền → 403 KHONG_CO_QUYEN
module Api
  class BaseController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    rescue_from StandardError do |exception|
      Rails.logger.error("[API] #{exception.class}: #{exception.message}")
      render_error(:internal_server_error, "LOI_HE_THONG",
                   "Đã xảy ra lỗi không mong đợi. Vui lòng thử lại sau.",
                   request_id: request.request_id)
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
      return if @current_user

      render_error(:unauthorized, "CHUA_XAC_THUC",
                   "Thiếu hoặc sai token. Gửi header Authorization: Bearer <api_token>.")
    end

    def require_permission!(permission)
      return if current_user.can?(permission)

      render_error(:forbidden, "KHONG_CO_QUYEN",
                   "Vai trò #{current_user.role_label} không có quyền thực hiện thao tác này.")
    end

    def render_error(status, code, message, chi_tiet = nil)
      body = { error: code, message: message }
      body[:chi_tiet] = chi_tiet if chi_tiet.present?
      render json: body, status: status
    end
  end
end
