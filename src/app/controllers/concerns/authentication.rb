# Đăng nhập bằng email + mật khẩu (TD-24) – theo bộ sinh mã authentication của Rails 8, không dùng Devise.
# Mọi controller kế thừa ApplicationController đều bắt buộc đăng nhập, trừ khi gọi allow_unauthenticated_access.
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?, :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    resume_session.present?
  end

  def current_user
    Current.user
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url if request.get?
    redirect_to new_session_path, alert: "Vui lòng đăng nhập để tiếp tục."
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || home_path_for(Current.user)
  end

  # Trang mở đầu theo vai trò
  def home_path_for(user)
    user&.manager? ? manager_warranty_requests_path : search_customers_path
  end

  # remember = true: cookie lưu lâu dài ("Ghi nhớ đăng nhập"); false: hết khi đóng trình duyệt
  def start_new_session_for(user, remember: false)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |new_session|
      Current.session = new_session
      cookie = { value: new_session.id, httponly: true, same_site: :lax }
      if remember
        cookies.signed.permanent[:session_id] = cookie
      else
        cookies.signed[:session_id] = cookie
      end
    end
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_id)
  end
end
