# Che các tham số nhạy cảm khi ghi log (Buổi 11 – "thứ tuyệt đối không ghi vào log", TD-27).
# So khớp một phần tên: :token che cả api_token, :passw che password và password_confirmation.
# Log chỉ ghi ID (customer_id, user_id), không ghi dữ liệu cá nhân của khách hàng.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :phone, :address, /\Aq\z/   # q = từ khóa tra cứu (thường là SĐT); dùng /\Aq\z/ để không che nhầm warranty_request
]
