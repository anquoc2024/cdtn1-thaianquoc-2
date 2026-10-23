# TD-24 – Bổ sung đăng nhập và phân quyền (NFR05 quay lại phạm vi)
#   users.email_address   tên đăng nhập (duy nhất, viết thường)
#   users.password_digest mật khẩu đã băm bằng bcrypt (has_secure_password)
#   users.api_token       token gọi API JSON qua header Authorization: Bearer <token>
#   sessions              mỗi lần đăng nhập một dòng; đăng xuất thì xóa dòng
class AddAuthentication < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_address, :string, limit: 255
    add_column :users, :password_digest, :string
    add_column :users, :api_token, :string, limit: 64
    add_index  :users, :email_address, unique: true
    add_index  :users, :api_token, unique: true

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address, limit: 45
      t.string :user_agent
      t.timestamps
    end
  end
end
