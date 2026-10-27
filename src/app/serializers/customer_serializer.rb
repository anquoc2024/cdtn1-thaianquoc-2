# Chuyển Customer thành Hash để trả JSON (API – TD-25)
class CustomerSerializer
  def self.call(customer)
    {
      id:         customer.id,
      code:       customer.code,
      name:       customer.name,
      phone:      customer.phone,
      email:      customer.email,
      address:    customer.address,
      created_at: customer.created_at&.iso8601,
      updated_at: customer.updated_at&.iso8601
    }
  end
end
