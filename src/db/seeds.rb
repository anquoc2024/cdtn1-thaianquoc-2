# Dữ liệu mẫu cho luồng L2 – chạy lại nhiều lần không bị trùng
# Toàn bộ khách hàng, thiết bị, yêu cầu lấy từ bộ dữ liệu của giảng viên trong data/mau/ (TD-23, TD-28)
puts "Đang tạo dữ liệu mẫu..."

# ---------- Người dùng ----------
receptionist = User.find_or_create_by!(full_name: "Thái An Quốc") { |u| u.role = :receptionist }
User.find_or_create_by!(full_name: "Võ Phạm Việt Phú") { |u| u.role = :manager }

# ---------- Mức ưu tiên (BR06): Thấp 72h · Trung bình 48h · Cao 24h · Khẩn cấp 8h ----------
L2DatasetImporter::PRIORITY_SLA.each do |name, hours|
  Priority.find_or_create_by!(name: name) { |p| p.sla_hours = hours }
end

# ---------- Khách hàng: 300 dòng đầu data/mau/customers_mau.csv (TD-23) ----------
result = CustomerCsvImporter.call(limit: CustomerCsvImporter::SEED_LIMIT)
puts "customers_mau: #{result.summary}"

# ---------- Bộ dữ liệu L2: nhóm sự cố, khách hàng, thiết bị, phiếu bảo hành (TD-28) ----------
l2 = L2DatasetImporter.call(created_by: receptionist, reject_path: Rails.root.join("tmp/import/l2_reject.csv"))
puts "Bộ dữ liệu L2: #{l2.summary}"

puts "Xong: #{User.count} người dùng, #{Customer.count} khách hàng, #{Device.count} thiết bị, " \
     "#{WarrantyRequest.count} yêu cầu (#{WarrantyRequest.overdue.count} quá hạn)."

# ---------- Tài khoản đăng nhập (TD-24) – chỉ dùng cho môi trường phát triển / chấm bài ----------
{ "Thái An Quốc" => "quoc@mekong.vn", "Võ Phạm Việt Phú" => "phu@mekong.vn" }.each do |name, email|
  user = User.find_by!(full_name: name)
  user.update!(email_address: email, password: "Mekong@2026") if user.password_digest.blank?
  user.regenerate_api_token if user.api_token.blank?
  puts "  #{user.role_label}: #{email} / Mekong@2026 · API token: #{user.api_token}"
end
