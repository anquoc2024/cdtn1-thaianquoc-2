class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :full_name, null: false, limit: 100
      t.string :role, null: false, default: "receptionist", limit: 20
      t.timestamps
    end
    # NFR05 – chỉ có 2 vai trò
    add_check_constraint :users, "role IN ('receptionist', 'manager')", name: "users_role_check"
  end
end
