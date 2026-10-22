class CreateIssueCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :issue_categories do |t|
      t.string :name, null: false, limit: 100
      t.text   :description
      t.timestamps
    end
    add_index :issue_categories, :name, unique: true
  end
end
