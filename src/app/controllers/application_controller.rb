class ApplicationController < ActionController::Base
  # Chỉ cho phép trình duyệt hiện đại (mặc định của Rails 8)
  allow_browser versions: :modern

  # Hệ thống không có đăng nhập – xem app/controllers/concerns/default_current_user.rb
  include DefaultCurrentUser
end
