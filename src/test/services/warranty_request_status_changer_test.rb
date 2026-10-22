require "test_helper"

# S2 – Cập nhật trạng thái / hủy yêu cầu (máy trạng thái + lịch sử)
class WarrantyRequestStatusChangerTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(full_name: "Nhân viên Test", role: :receptionist)
    customer = Customer.create!(code: "KH-910001", name: "Khách Test", phone: "0910000001")
    device   = Device.create!(customer: customer, device_type: "Laptop", brand: "Dell", model: "X",
                              serial_number: "SN-S2-001", purchase_date: Date.current - 30)
    @request = WarrantyRequest.create!(code: "BH-2099-000001", device: device, created_by: @user,
                                       issue_category: IssueCategory.create!(name: "Màn hình"),
                                       priority: Priority.create!(name: "Cao", sla_hours: 24),
                                       issue_description: "Lỗi", due_at: 1.day.from_now)
  end

  def change(to, note: nil)
    WarrantyRequestStatusChanger.call(warranty_request: @request, to_status: to, changed_by: @user, note: note)
  end

  test "Mới tiếp nhận → Đang xử lý → Hoàn tất, ghi đủ lịch sử, có thời điểm đóng" do
    assert change("in_progress").success?
    assert change("completed").success?

    @request.reload
    assert @request.completed?
    assert_not_nil @request.closed_at
    assert_equal [%w[new in_progress], %w[in_progress completed]],
                 @request.status_logs.map { |log| [log.from_status, log.to_status] }
  end

  test "không được nhảy thẳng từ Mới tiếp nhận sang Hoàn tất" do
    result = change("completed")
    assert_not result.success?
    assert_equal :invalid_transition, result.error_code
    assert @request.reload.received?
    assert_empty @request.status_logs
  end

  test "hủy bắt buộc có lý do" do
    result = change("cancelled")
    assert_equal :note_required, result.error_code
    assert @request.reload.received?
  end

  test "hủy có lý do: chuyển sang Đã hủy, lưu lý do vào lịch sử" do
    assert change("cancelled", note: "Khách không đồng ý chi phí").success?
    @request.reload
    assert @request.cancelled?
    assert_equal "Khách không đồng ý chi phí", @request.status_logs.last.note
  end

  test "yêu cầu đã đóng thì không đổi trạng thái được nữa" do
    change("cancelled", note: "Hủy")
    result = change("in_progress")
    assert_equal :closed, result.error_code
    assert @request.reload.cancelled?
  end

  test "trạng thái không tồn tại bị từ chối" do
    assert_equal :invalid_status, change("abc").error_code
  end

  test "yêu cầu đã hủy không bị tính là quá hạn" do
    @request.update!(due_at: 1.hour.ago)
    assert @request.overdue?
    change("cancelled", note: "Hủy")
    assert_not @request.reload.overdue?
    assert_not_includes WarrantyRequest.overdue, @request
  end
end
