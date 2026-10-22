module CustomersHelper
  # "0905123456" -> "0905 123 456"
  def format_phone(phone)
    digits = phone.to_s.gsub(/\D/, "")
    return phone unless digits.length == 10

    "#{digits[0, 4]} #{digits[4, 3]} #{digits[7, 3]}"
  end

  # "2 yêu cầu (gần nhất 03/2026)"
  def previous_requests_summary(customer)
    count = customer.warranty_requests.count
    return "Chưa có yêu cầu nào" if count.zero?

    latest = customer.warranty_requests.maximum(:created_at)
    "#{count} yêu cầu (gần nhất #{latest.strftime('%m/%Y')})"
  end

  # Câu thông báo UC08 theo loại từ khóa
  def not_found_message(result)
    case result.mode
    when :phone then "Không tìm thấy khách hàng với số điện thoại #{format_phone(result.query)}"
    when :code  then "Không tìm thấy khách hàng có mã #{result.query.upcase}"
    else             "Không tìm thấy khách hàng có tên “#{result.query}”"
    end
  end
end
