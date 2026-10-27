require "test_helper"

# TD-25 – CRUD Khách hàng ở lớp service (không qua HTTP)
class CustomerServiceTest < ActiveSupport::TestCase
  def valid_attrs(overrides = {})
    { name: "Nguyễn Văn Test", phone: "0901 234 567", email: "test@mekong.vn", address: "12 Lê Lợi" }.merge(overrides)
  end

  # ---------- Luồng đúng ----------
  test "tạo khách hàng: chuẩn hóa SĐT và tự sinh mã kế tiếp, bỏ qua dải mã nạp từ CSV (BR12)" do
    Customer.create!(code: "KH-000245", name: "Có sẵn", phone: "0905123456")
    Customer.create!(code: "KH-100001", name: "Nạp CSV", phone: "0763247885")

    result = CustomerService.create(valid_attrs)

    assert result.success?
    assert_equal "KH-000246", result.record.code
    assert_equal "0901234567", result.record.phone
  end

  test "sửa khách hàng: đổi họ tên và địa chỉ" do
    customer = CustomerService.create(valid_attrs).record
    result = CustomerService.update(customer, { name: "Tên Mới", address: "34 Hai Bà Trưng" })

    assert result.success?
    assert_equal "Tên Mới", customer.reload.name
  end

  test "xóa khách hàng chưa có thiết bị" do
    customer = CustomerService.create(valid_attrs).record

    assert_difference "Customer.count", -1 do
      assert CustomerService.destroy(customer).success?
    end
  end

  # ---------- Giá trị biên ----------
  test "SĐT đúng 10 chữ số thì nhận, 9 chữ số thì từ chối (BR01)" do
    assert CustomerService.create(valid_attrs(phone: "0912345678")).success?

    result = CustomerService.create(valid_attrs(phone: "091234567"))
    assert_equal :invalid, result.error_code
    assert_includes result.errors, { truong: "phone", ly_do: "phải gồm 10 chữ số, bắt đầu bằng 0" }
  end

  test "họ tên 100 ký tự thì nhận, 101 ký tự thì từ chối" do
    assert CustomerService.create(valid_attrs(name: "A" * 100, phone: "0912000001")).success?

    result = CustomerService.create(valid_attrs(name: "A" * 101, phone: "0912000002"))
    assert_equal :invalid, result.error_code
    assert_equal "name", result.errors.first[:truong]
  end

  # ---------- Dữ liệu sai / vi phạm quy tắc ----------
  test "trùng SĐT với khách khác: từ chối với mã duplicate (BR01)" do
    CustomerService.create(valid_attrs)
    result = CustomerService.create(valid_attrs(name: "Người khác"))

    assert_equal :duplicate, result.error_code
    assert_includes result.errors, { truong: "phone", ly_do: "đã tồn tại" }
  end

  test "không xóa khách hàng đã có thiết bị (BR13)" do
    customer = CustomerService.create(valid_attrs).record
    Device.create!(customer: customer, device_type: "Laptop", brand: "Dell", model: "X",
                   serial_number: "SN-CRUD-1", purchase_date: Date.current)

    assert_no_difference "Customer.count" do
      result = CustomerService.destroy(customer)
      assert_equal :in_use, result.error_code
      assert_match "BR13", result.message
    end
  end
end
