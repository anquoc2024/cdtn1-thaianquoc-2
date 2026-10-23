ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Chạy test song song theo số nhân CPU
    parallelize(workers: :number_of_processors)

    fixtures :all
  end
end

# TD-24 – tạo tài khoản và đăng nhập trong test
module SignInHelper
  PASSWORD = "Matkhau@2026".freeze

  def create_account(role:, email: "#{role}@test.vn", full_name: "TK #{role}")
    User.create!(full_name: full_name, role: role, email_address: email, password: PASSWORD)
  end

  def sign_in_as(user, password: PASSWORD, remember_me: "0")
    post session_path, params: { email_address: user.email_address, password: password, remember_me: remember_me }
  end
end

module ActionDispatch
  class IntegrationTest
    include SignInHelper

    # Mặc định mỗi test giao diện đăng nhập sẵn bằng tài khoản Quản lý (làm được mọi chức năng),
    # để các test nghiệp vụ cũ chạy như trước. Test cần trạng thái khác đặt:
    #   self.auto_sign_in_as = nil            # chưa đăng nhập (test đăng nhập, test API)
    #   self.auto_sign_in_as = :receptionist  # đăng nhập bằng Nhân viên tiếp nhận
    class_attribute :auto_sign_in_as, default: :manager

    setup do
      if auto_sign_in_as
        sign_in_as(create_account(role: auto_sign_in_as, email: "auto-#{auto_sign_in_as}@test.vn"))
      end
    end
  end
end
