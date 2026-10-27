# Đổi lỗi validation của model thành danh sách {truong, ly_do} bằng tiếng Việt (TD-25)
# để API trả về cùng một định dạng chi_tiet.cac_truong như lỗi tạo yêu cầu bảo hành.
module FieldErrors
  MESSAGES = {
    blank:    "không được để trống",
    taken:    "đã tồn tại",
    too_long: "tối đa %{count} ký tự",
    invalid:  "không đúng định dạng"
  }.freeze

  def self.of(record)
    record.errors.map do |error|
      { truong: error.attribute.to_s, ly_do: message_for(error) }
    end
  end

  def self.message_for(error)
    return "phải gồm 10 chữ số, bắt đầu bằng 0" if error.attribute == :phone && error.type == :invalid
    return error.message unless MESSAGES.key?(error.type)

    format(MESSAGES[error.type], count: error.options[:count])
  end
end
