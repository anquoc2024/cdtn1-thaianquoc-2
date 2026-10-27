require "test_helper"

# TD-25 – CRUD Nhóm sự cố ở lớp service (không qua HTTP)
class IssueCategoryServiceTest < ActiveSupport::TestCase
  test "tạo, sửa, xóa nhóm sự cố chưa được dùng" do
    category = IssueCategoryService.create({ name: "  Camera  ", description: "Lỗi camera" }).record
    assert_equal "Camera", category.name

    assert IssueCategoryService.update(category, { name: "Camera / Quay phim" }).success?
    assert_equal "Camera / Quay phim", category.reload.name

    assert_difference "IssueCategory.count", -1 do
      assert IssueCategoryService.destroy(category).success?
    end
  end

  test "tên 100 ký tự thì nhận, 101 ký tự thì từ chối" do
    assert IssueCategoryService.create({ name: "B" * 100 }).success?

    result = IssueCategoryService.create({ name: "C" * 101 })
    assert_equal :invalid, result.error_code
    assert_includes result.errors, { truong: "name", ly_do: "tối đa 100 ký tự" }
  end

  test "tên trùng (không phân biệt hoa thường) hoặc để trống bị từ chối (BR03)" do
    IssueCategoryService.create({ name: "Màn hình" })

    assert_equal :duplicate, IssueCategoryService.create({ name: "màn HÌNH" }).error_code
    assert_equal :invalid,   IssueCategoryService.create({ name: "   " }).error_code
  end

  test "không xóa nhóm sự cố đang được yêu cầu bảo hành dùng (BR14)" do
    category = IssueCategoryService.create({ name: "Nguồn test" }).record
    user     = User.create!(full_name: "NV", role: :receptionist)
    customer = Customer.create!(code: "KH-950001", name: "KH", phone: "0950000001")
    device   = Device.create!(customer: customer, device_type: "Laptop", brand: "Dell", model: "X",
                              serial_number: "SN-CAT-1", purchase_date: Date.current)
    WarrantyRequest.create!(code: "BH-2099-000950", device: device, created_by: user, issue_category: category,
                            priority: Priority.create!(name: "Cao test", sla_hours: 24),
                            issue_description: "Lỗi", due_at: 1.day.from_now)

    assert_no_difference "IssueCategory.count" do
      result = IssueCategoryService.destroy(category)
      assert_equal :in_use, result.error_code
      assert_match "1 yêu cầu", result.message
    end
  end
end
