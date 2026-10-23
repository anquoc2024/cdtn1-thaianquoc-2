# Đăng nhập / đăng xuất (TD-24)
#   GET    /session/new  form đăng nhập
#   POST   /session      kiểm tra email + mật khẩu, tạo phiên
#   DELETE /session      đăng xuất
class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_session_path, alert: "Đăng nhập sai quá nhiều lần. Vui lòng thử lại sau ít phút." }

  layout "auth"

  def new
    redirect_to home_path_for(Current.user) if authenticated?
  end

  def create
    user = User.authenticate_by(email_address: params[:email_address].to_s, password: params[:password].to_s)

    if user
      start_new_session_for(user, remember: params[:remember_me] == "1")
      redirect_to after_authentication_url, notice: "Xin chào #{user.full_name} (#{user.role_label})."
    else
      @email_address = params[:email_address]
      flash.now[:alert] = "Email hoặc mật khẩu không đúng."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: "Bạn đã đăng xuất.", status: :see_other
  end
end
