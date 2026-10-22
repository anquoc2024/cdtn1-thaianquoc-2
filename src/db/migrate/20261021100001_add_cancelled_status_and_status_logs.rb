# S2 – Cập nhật trạng thái và hủy yêu cầu (đủ CRUD cho entity chính)
#   1. Thêm trạng thái 'cancelled' (Đã hủy) – hủy là đổi trạng thái, KHÔNG xóa dòng
#   2. Thêm closed_at – thời điểm hoàn tất hoặc hủy
#   3. Thêm bảng lịch sử đổi trạng thái
class AddCancelledStatusAndStatusLogs < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :warranty_requests,
      "status IN ('new', 'in_progress', 'completed')", name: "warranty_requests_status_check"
    add_check_constraint :warranty_requests,
      "status IN ('new', 'in_progress', 'completed', 'cancelled')", name: "warranty_requests_status_check"

    add_column :warranty_requests, :closed_at, :datetime

    create_table :warranty_request_status_logs do |t|
      t.references :warranty_request, null: false, foreign_key: true
      t.string     :from_status, limit: 20                     # null = lúc mới tiếp nhận
      t.string     :to_status, null: false, limit: 20
      t.string     :note, limit: 500
      t.references :changed_by, null: false, foreign_key: { to_table: :users }
      t.datetime   :created_at, null: false
    end
    add_index :warranty_request_status_logs, [:warranty_request_id, :created_at]
  end
end
