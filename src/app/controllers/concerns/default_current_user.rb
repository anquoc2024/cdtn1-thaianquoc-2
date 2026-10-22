# Hệ thống KHÔNG có chức năng đăng nhập (đã bỏ khỏi phạm vi).
# Người tạo yêu cầu bảo hành (created_by) mặc định là nhân viên tiếp nhận đầu tiên trong dữ liệu.
module DefaultCurrentUser
  extend ActiveSupport::Concern

  included do
    helper_method :current_user
  end

  private

  def current_user
    @current_user ||= User.receptionist.first!
  end
end
