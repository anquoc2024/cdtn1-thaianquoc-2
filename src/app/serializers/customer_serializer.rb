# Chuyển Customer thành Hash để trả JSON (API – TD-25, TD-26)
# history: true → kèm số yêu cầu bảo hành trước đây (Màn hình 1 hiển thị)
class CustomerSerializer
  def self.call(customer, history: false)
    data = {
      id:         customer.id,
      code:       customer.code,
      name:       customer.name,
      phone:      customer.phone,
      email:      customer.email,
      address:    customer.address,
      created_at: customer.created_at&.iso8601,
      updated_at: customer.updated_at&.iso8601
    }
    return data unless history

    requests = customer.warranty_requests
    data.merge(so_yeu_cau: requests.count, yeu_cau_gan_nhat: requests.maximum(:created_at)&.iso8601)
  end
end
