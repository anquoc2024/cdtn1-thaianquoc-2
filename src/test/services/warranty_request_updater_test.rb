require "test_helper"

# TD-29 – sửa yêu cầu bảo hành: cập nhật thiết bị + yêu cầu, tính lại hạn, ghi lịch sử; dữ liệu sai thì không đổi gì
class WarrantyRequestUpdaterTest < ActiveSupport::TestCase
  setup do
    @user     = User.create!(full_name: "NV sửa", role: :receptionist)
    customer  = Customer.create!(code: "KH-950001", name: "Khách Sửa", phone: "0950000001")
    device    = Device.create!(customer: customer, device_type: "Laptop", brand: "Dell", model: "Inspiron",
                               serial_number: "SN-SUA-1", purchase_date: Date.current - 30)
    @slow     = Priority.create!(name: "Thấp", sla_hours: 72)
    @fast     = Priority.create!(name: "Khẩn cấp", sla_hours: 8)
    @category = IssueCategory.create!(name: "Màn hình")
    @request  = WarrantyRequest.create!(code: "BH-2099-000950", device: device, created_by: @user,
                                        issue_category: @category, priority: @slow, status: :completed,
                                        issue_description: "Lỗi cũ", due_at: 3.days.from_now, created_at: 2.hours.ago)
  end

  def form(changes = {})
    WarrantyRequestEditForm.from(@request).tap { |f| f.assign_attributes(changes) }
  end

  test "sửa được cả khi đã Hoàn tất; đổi ưu tiên thì hạn = lúc tiếp nhận + SLA mới; ghi lịch sử" do
    result = WarrantyRequestUpdater.call(warranty_request: @request, changed_by: @user,
                                         form: form(model: "Inspiron 15", issue_description: "Sọc màn hình", priority_id: @fast.id))

    assert result.success?
    @request.reload
    assert_equal "Inspiron 15", @request.device.model
    assert_equal "Sọc màn hình", @request.issue_description
    assert_equal @request.created_at + 8.hours, @request.due_at
    log = @request.status_logs.last
    assert_equal log.from_status, log.to_status
    assert_match "model", log.note
    assert_match "mức ưu tiên", log.note
  end

  test "không có thay đổi thì không ghi lịch sử" do
    assert_no_difference "WarrantyRequestStatusLog.count" do
      assert WarrantyRequestUpdater.call(warranty_request: @request, changed_by: @user, form: form).success?
    end
  end

  test "thiếu mô tả hoặc ngày mua trong tương lai thì báo lỗi từng trường, không đổi dữ liệu" do
    result = WarrantyRequestUpdater.call(warranty_request: @request, changed_by: @user,
                                         form: form(issue_description: "", purchase_date: Date.current + 1))

    assert_not result.success?
    assert_equal :invalid, result.error_code
    assert_equal %w[issue_description purchase_date], result.errors.map { |e| e[:truong] }.sort
    assert_equal "Lỗi cũ", @request.reload.issue_description
  end
end
