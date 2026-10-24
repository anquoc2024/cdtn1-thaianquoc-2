# Đăng nhập / đăng xuất cho API JSON (TD-24) – lấy token để gọi các API khác
#
#   POST   /api/session   {"email_address": "...", "password": "..."}  → 200 + token
#   DELETE /api/session   (kèm Authorization: Bearer <token>)           → 204, token cũ hết hiệu lực
module Api
  class SessionsController < BaseController
    skip_before_action :authenticate_api_user!, only: :create
    rate_limit to: 10, within: 3.minutes, only: :create,
               with: -> { render_error(:too_many_requests, "QUA_NHIEU_LAN_THU",
                                       "Đăng nhập sai quá nhiều lần. Vui lòng thử lại sau ít phút.") }

    def create
      user = User.authenticate_by(email_address: params[:email_address].to_s, password: params[:password].to_s)
      unless user
        return render_error(:unauthorized, "SAI_THONG_TIN_DANG_NHAP", "Email hoặc mật khẩu không đúng.")
      end

      user.regenerate_api_token if user.api_token.blank?
      render json: {
        data: {
          token:      user.api_token,
          token_type: "Bearer",
          user: {
            id: user.id, full_name: user.full_name, email_address: user.email_address,
            role: user.role, role_label: user.role_label,
            permissions: User::PERMISSIONS.keys.select { |permission| user.can?(permission) }
          }
        }
      }
    end

    # Đăng xuất: cấp token mới để token đang dùng không gọi được nữa
    def destroy
      current_user.regenerate_api_token
      head :no_content
    end
  end
end
