class CreatePriorities < ActiveRecord::Migration[8.1]
  def change
    create_table :priorities do |t|
      t.string  :name, null: false, limit: 50
      t.integer :sla_hours, null: false         # BR06
      t.timestamps
    end
    add_index :priorities, :name, unique: true
    add_check_constraint :priorities, "sla_hours > 0", name: "priorities_sla_hours_positive"
  end
end
