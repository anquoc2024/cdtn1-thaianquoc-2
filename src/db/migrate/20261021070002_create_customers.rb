class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :code, null: false, limit: 20     # KH-000245
      t.string :name, null: false, limit: 100
      t.string :phone, null: false, limit: 10    # FR01
      t.string :email, limit: 255
      t.string :address, limit: 255
      t.timestamps
    end
    add_index :customers, :code, unique: true
    add_index :customers, :phone, unique: true   # NFR01 – tra cứu nhanh theo SĐT
    add_check_constraint :customers, "phone ~ '^0[0-9]{9}$'", name: "customers_phone_format"
  end
end
