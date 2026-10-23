# Dữ liệu mẫu cho luồng L2 – chạy lại nhiều lần không bị trùng
puts "Đang tạo dữ liệu mẫu..."

# ---------- Người dùng ----------
receptionist = User.find_or_create_by!(full_name: "Thái An Quốc") { |u| u.role = :receptionist }
User.find_or_create_by!(full_name: "Võ Phạm Việt Phú") { |u| u.role = :manager }

# ---------- Mức ưu tiên (BR06) ----------
priorities = {
  "Thấp" => 72, "Trung bình" => 48, "Cao" => 24, "Khẩn cấp" => 8
}.to_h { |name, hours| [name, Priority.find_or_create_by!(name: name) { |p| p.sla_hours = hours }] }

# ---------- Nhóm sự cố ----------
categories = [
  "Nguồn / Pin / Sạc", "Màn hình", "Phần mềm", "Cơ / Linh kiện", "Âm thanh", "Bàn phím"
].to_h { |name| [name, IssueCategory.find_or_create_by!(name: name)] }

# ---------- Khách hàng + thiết bị + yêu cầu (theo Màn hình 3) ----------
# [mã KH, tên, SĐT, loại, hãng, model, serial, nhóm sự cố, ưu tiên, trạng thái, số giờ đến hạn]
rows = [
  ["KH-000245", "Trần Thị Bình",   "0905123456", "Điện thoại", "Samsung", "Galaxy A55",  "R58T20A0001", "Nguồn / Pin / Sạc", "Cao",        :received,    20],
  ["KH-000246", "Phạm Văn Cường",  "0912345678", "Laptop",     "Dell",    "Inspiron",    "DL-INS-0002", "Màn hình",          "Trung bình", :in_progress, 30],
  ["KH-000247", "Lê Thị Dung",     "0987654321", "Điện thoại", "Apple",   "iPhone 14",   "AP-IP14-0003","Phần mềm",          "Thấp",       :received,    60],
  ["KH-000248", "Hoàng Minh Đức",  "0934111222", "Laptop",     "Acer",    "Aspire 7",    "AC-ASP-0004", "Cơ / Linh kiện",    "Khẩn cấp",   :in_progress, -10],
  ["KH-000249", "Vũ Thu Hà",       "0978222333", "Điện thoại", "Apple",   "iPhone 16 Pro Max", "AP-IP16-0005", "Nguồn / Pin / Sạc", "Cao", :in_progress, 8],
  ["KH-000250", "Ngô Gia Huy",     "0903444555", "Tai nghe",   "Sony",    "WH-1000XM5",  "SN-WH-0006",  "Âm thanh",          "Thấp",       :completed,   40],
  ["KH-000251", "Đặng Mai Lan",    "0911666777", "Laptop",     "HP",      "Pavilion",    "HP-PAV-0007", "Bàn phím",          "Trung bình", :received,    -30],
  ["KH-000252", "Bùi Quốc Khánh",  "0966888999", "Điện thoại", "Xiaomi",  "Redmi 13",    "XM-RM13-0008","Màn hình",          "Cao",        :in_progress, 12]
]

rows.each_with_index do |(code, name, phone, type, brand, model, serial, category, priority, status, hours_left), index|
  customer = Customer.find_or_create_by!(phone: phone) do |c|
    c.code  = code
    c.name  = name
    c.email = "#{code.downcase.delete('-')}@example.com"
  end

  device = Device.find_or_create_by!(serial_number: serial) do |d|
    d.customer      = customer
    d.device_type   = type
    d.brand         = brand
    d.model         = model
    d.purchase_date = Date.current - (index + 2).months
  end

  request_code = format("BH-%<year>d-%<seq>06d", year: Date.current.year, seq: 123 - index)
  WarrantyRequest.find_or_create_by!(code: request_code) do |r|
    r.device            = device
    r.issue_category    = categories.fetch(category)
    r.priority          = priorities.fetch(priority)
    r.created_by        = receptionist
    r.issue_description = "Dữ liệu mẫu: thiết bị gặp sự cố nhóm #{category}."
    r.status            = status
    r.due_at            = hours_left.hours.from_now
  end
end

# Thêm địa chỉ cho khách hàng dùng trên Màn hình 1
Customer.find_by!(phone: "0905123456").update!(email: "binh.tran@gmail.com", address: "12 Lê Lợi, Q.1, TP.HCM")

puts "Xong: #{User.count} người dùng, #{Customer.count} khách hàng, #{Device.count} thiết bị, " \
     "#{WarrantyRequest.count} yêu cầu (#{WarrantyRequest.overdue.count} quá hạn)."

# ---------- Khách hàng từ bộ dữ liệu mẫu của giảng viên (300 dòng đầu customers_raw.csv) – TD-23 ----------
result = CustomerCsvImporter.call
puts "customers_raw: #{result.summary}"

# ---------- Tài khoản đăng nhập (TD-24) – chỉ dùng cho môi trường phát triển / chấm bài ----------
{ "Thái An Quốc" => "quoc@mekong.vn", "Võ Phạm Việt Phú" => "phu@mekong.vn" }.each do |name, email|
  user = User.find_by!(full_name: name)
  user.update!(email_address: email, password: "Mekong@2026") if user.password_digest.blank?
  user.regenerate_api_token if user.api_token.blank?
  puts "  #{user.role_label}: #{email} / Mekong@2026 · API token: #{user.api_token}"
end
