# Lớp cha của mọi API JSON (/api/...)
#
# – Kế thừa ActionController::API: không có view, cookie, CSRF – chỉ nhận và trả JSON
# – Mọi lỗi trả về cùng một dạng: {"error": "MA_LOI", "message": "...", "chi_tiet": {...}}
# – Không đăng nhập (TD-11): người thao tác mặc định là nhân viên tiếp nhận đầu tiên
module Api
  class BaseController < ActionController::API
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

    private

    def current_user
      @current_user ||= User.receptionist.first!
    end

    def render_error(status, code, message, chi_tiet = nil)
      body = { error: code, message: message }
      body[:chi_tiet] = chi_tiet if chi_tiet.present?
      render json: body, status: status
    end
  end
end
