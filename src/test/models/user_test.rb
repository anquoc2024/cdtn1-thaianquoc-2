require "test_helper"

# TD-24 – tài khoản, mật khẩu và bảng phân quyền (theo User Story)
class UserTest < ActiveSupport::TestCase
  test "Nhân viên tiếp nhận làm toàn bộ nghiệp vụ; Quản lý chỉ xem danh sách và phiếu" do
    receptionist = User.new(full_name: "NV", role: :receptionist)
    manager      = User.new(full_name: "QL", role: :manager)

    User::PERMISSIONS.each_key { |permission| assert receptionist.can?(permission), permission.to_s }

    assert manager.can?(:view_request_list)
    assert manager.can?(:view_requests)
    assert_not manager.can?(:lookup_customers)
    assert_not manager.can?(:create_requests)
    assert_not manager.can?(:change_status)
  end

  test "email được chuẩn hóa về chữ thường, duy nhất; mật khẩu tối thiểu 8 ký tự" do
    user = User.create!(full_name: "Thái An Quốc", role: :receptionist,
                        email_address: "  Quoc@Mekong.VN ", password: "Matkhau@2026")
    assert_equal "quoc@mekong.vn", user.email_address
    assert_equal "TQ", user.initials
    assert user.api_token.present?

    duplicate = User.new(full_name: "Trùng", role: :manager, email_address: "quoc@mekong.vn", password: "Matkhau@2026")
    assert_not duplicate.valid?

    short = User.new(full_name: "Ngắn", role: :manager, email_address: "ngan@mekong.vn", password: "123")
    assert_not short.valid?
    assert short.errors.key?(:password)
  end

  test "tài khoản chưa có mật khẩu không đăng nhập được" do
    User.create!(full_name: "Cũ", role: :receptionist)
    User.create!(full_name: "Có email", role: :receptionist, email_address: "a@mekong.vn", password: "Matkhau@2026")

    assert_nil User.authenticate_by(email_address: "a@mekong.vn", password: "sai-mat-khau")
    assert User.authenticate_by(email_address: "A@Mekong.vn", password: "Matkhau@2026")
  end
end
