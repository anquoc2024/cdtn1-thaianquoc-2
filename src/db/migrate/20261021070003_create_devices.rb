class CreateDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :devices do |t|
      t.references :customer, null: false, foreign_key: true
      t.string :device_type, null: false, limit: 50
      t.string :brand, null: false, limit: 50
      t.string :model, null: false, limit: 100
      t.string :serial_number, null: false, limit: 50
      t.date   :purchase_date, null: false
      t.string :warranty_card_number, limit: 50
      t.timestamps
    end
    add_index :devices, :serial_number, unique: true
    add_check_constraint :devices, "purchase_date <= CURRENT_DATE", name: "devices_purchase_date_not_future"
  end
end
