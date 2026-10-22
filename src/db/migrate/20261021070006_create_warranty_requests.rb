class CreateWarrantyRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :warranty_requests do |t|
      t.string     :code, null: false, limit: 20                       # BR05: BH-2026-000123
      t.references :device, null: false, foreign_key: true
      t.references :issue_category, null: false, foreign_key: true     # BR03
      t.references :priority, null: false, foreign_key: true           # BR03
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.text       :issue_description, null: false
      t.string     :status, null: false, default: "new", limit: 20
      t.datetime   :due_at, null: false                                # BR06
      t.timestamps
    end
    add_index :warranty_requests, :code, unique: true
    add_index :warranty_requests, [:status, :due_at]                   # UC07 – lọc, quá hạn
    add_check_constraint :warranty_requests,
      "status IN ('new', 'in_progress', 'completed')", name: "warranty_requests_status_check"
    add_check_constraint :warranty_requests,
      "char_length(issue_description) BETWEEN 1 AND 1000", name: "warranty_requests_description_length"
  end
end
