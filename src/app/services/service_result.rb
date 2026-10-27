# Kết quả trả về của các service CRUD (TD-25).
# Service KHÔNG biết HTTP: chỉ trả record hoặc mã lỗi nghiệp vụ; controller tự dịch mã lỗi sang mã HTTP.
#
#   error_code  nil         – thành công
#               :invalid    – dữ liệu vào không hợp lệ (errors liệt kê từng trường)
#               :duplicate  – trùng dữ liệu duy nhất (SĐT, tên nhóm sự cố)
#               :in_use     – còn dữ liệu khác đang dùng nên không xóa được
ServiceResult = Data.define(:record, :error_code, :errors, :message) do
  def self.ok(record)
    new(record: record, error_code: nil, errors: [], message: nil)
  end

  def self.failure(code, message, errors: [], record: nil)
    new(record: record, error_code: code, errors: errors, message: message)
  end

  def success? = error_code.nil?
end
