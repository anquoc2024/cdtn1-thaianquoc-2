class ApplicationController < ActionController::Base
  # Chỉ cho phép trình duyệt hiện đại (mặc định của Rails 8)
  allow_browser versions: :modern

  # TD-24: bắt buộc đăng nhập + phân quyền theo vai trò (thay cho DefaultCurrentUser của TD-11)
  include Authentication
  include Authorization
end
