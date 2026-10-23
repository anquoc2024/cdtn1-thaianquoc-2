# Một lần đăng nhập của người dùng (cookie trình duyệt lưu session.id đã ký)
class Session < ApplicationRecord
  belongs_to :user
end
