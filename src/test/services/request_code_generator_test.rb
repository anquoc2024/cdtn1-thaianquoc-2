require "test_helper"

# BR05 – mã yêu cầu duy nhất, tăng dần theo năm
class RequestCodeGeneratorTest < ActiveSupport::TestCase
  test "mã đầu tiên trong năm là 000001" do
    assert_equal "BH-2099-000001", RequestCodeGenerator.next_code(year: 2099)
  end

  test "mã tiếp theo = mã lớn nhất trong năm + 1" do
    user     = User.create!(full_name: "NV Test", role: :receptionist)
    customer = Customer.create!(code: "KH-T1", name: "KH Test", phone: "0900000001")
    device   = Device.create!(customer: customer, device_type: "Laptop", brand: "Dell", model: "X",
                              serial_number: "SN-T1", purchase_date: Date.current)
    WarrantyRequest.create!(code: "BH-2099-000041", device: device, created_by: user,
                            issue_category: IssueCategory.create!(name: "Test"),
                            priority: Priority.create!(name: "Test", sla_hours: 24),
                            issue_description: "Lỗi", due_at: 1.day.from_now)

    assert_equal "BH-2099-000042", RequestCodeGenerator.next_code(year: 2099)
  end
end
