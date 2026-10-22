# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_21_100001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "unaccent"

  create_table "customers", force: :cascade do |t|
    t.string "code", limit: 20, null: false
    t.string "name", limit: 100, null: false
    t.string "phone", limit: 10, null: false
    t.string "email", limit: 255
    t.string "address", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_customers_on_code", unique: true
    t.index ["phone"], name: "index_customers_on_phone", unique: true
    t.check_constraint "phone::text ~ '^0[0-9]{9}$'::text", name: "customers_phone_format"
  end

  create_table "devices", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "device_type", limit: 50, null: false
    t.string "brand", limit: 50, null: false
    t.string "model", limit: 100, null: false
    t.string "serial_number", limit: 50, null: false
    t.date "purchase_date", null: false
    t.string "warranty_card_number", limit: 50
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_devices_on_customer_id"
    t.index ["serial_number"], name: "index_devices_on_serial_number", unique: true
    t.check_constraint "purchase_date <= CURRENT_DATE", name: "devices_purchase_date_not_future"
  end

  create_table "issue_categories", force: :cascade do |t|
    t.string "name", limit: 100, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_issue_categories_on_name", unique: true
  end

  create_table "priorities", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.integer "sla_hours", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_priorities_on_name", unique: true
    t.check_constraint "sla_hours > 0", name: "priorities_sla_hours_positive"
  end

  create_table "users", force: :cascade do |t|
    t.string "full_name", limit: 100, null: false
    t.string "role", limit: 20, default: "receptionist", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "role::text = ANY (ARRAY['receptionist'::character varying, 'manager'::character varying]::text[])", name: "users_role_check"
  end

  create_table "warranty_request_status_logs", force: :cascade do |t|
    t.bigint "warranty_request_id", null: false
    t.string "from_status", limit: 20
    t.string "to_status", limit: 20, null: false
    t.string "note", limit: 500
    t.bigint "changed_by_id", null: false
    t.datetime "created_at", null: false
    t.index ["changed_by_id"], name: "index_warranty_request_status_logs_on_changed_by_id"
    t.index ["warranty_request_id", "created_at"], name: "idx_on_warranty_request_id_created_at_43477ba8ee"
    t.index ["warranty_request_id"], name: "index_warranty_request_status_logs_on_warranty_request_id"
  end

  create_table "warranty_requests", force: :cascade do |t|
    t.string "code", limit: 20, null: false
    t.bigint "device_id", null: false
    t.bigint "issue_category_id", null: false
    t.bigint "priority_id", null: false
    t.bigint "created_by_id", null: false
    t.text "issue_description", null: false
    t.string "status", limit: 20, default: "new", null: false
    t.datetime "due_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "closed_at"
    t.index ["code"], name: "index_warranty_requests_on_code", unique: true
    t.index ["created_by_id"], name: "index_warranty_requests_on_created_by_id"
    t.index ["device_id"], name: "index_warranty_requests_on_device_id"
    t.index ["issue_category_id"], name: "index_warranty_requests_on_issue_category_id"
    t.index ["priority_id"], name: "index_warranty_requests_on_priority_id"
    t.index ["status", "due_at"], name: "index_warranty_requests_on_status_and_due_at"
    t.check_constraint "char_length(issue_description) >= 1 AND char_length(issue_description) <= 1000", name: "warranty_requests_description_length"
    t.check_constraint "status::text = ANY (ARRAY['new'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'cancelled'::character varying]::text[])", name: "warranty_requests_status_check"
  end

  add_foreign_key "devices", "customers"
  add_foreign_key "warranty_request_status_logs", "users", column: "changed_by_id"
  add_foreign_key "warranty_request_status_logs", "warranty_requests"
  add_foreign_key "warranty_requests", "devices"
  add_foreign_key "warranty_requests", "issue_categories"
  add_foreign_key "warranty_requests", "priorities"
  add_foreign_key "warranty_requests", "users", column: "created_by_id"
end
