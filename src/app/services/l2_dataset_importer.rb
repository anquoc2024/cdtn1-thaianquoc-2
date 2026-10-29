require "csv"

# Nạp bộ dữ liệu mẫu luồng L2 của giảng viên (data/mau/*.csv) vào hệ thống – TD-28
#
#   issue_categories.csv → issue_categories   (tìm theo tên, chưa có thì tạo)
#   customers.csv        → customers          (tìm theo SĐT; mới thì mã KH-(100000 + customer_id))
#   products.csv         → dùng để điền hãng / model / loại thiết bị (hệ thống không có bảng sản phẩm)
#   devices.csv          → devices            (tìm theo serial; thiếu ngày mua thì loại – BR02)
#   tickets.csv          → warranty_requests  (Mới tiếp nhận; tạo lúc = bây giờ − hours_ago; hạn = tạo + SLA – BR06)
#   service_centers.csv  → không nạp: hệ thống chỉ phục vụ một trung tâm (ghi chú trong TD-28)
#
# Chạy lại nhiều lần không nhân đôi: khách theo SĐT, thiết bị theo serial,
# yêu cầu theo (thiết bị + mô tả lỗi). Mọi thao tác ghi nằm trong MỘT transaction.
# Dòng bị loại được ghi kèm lý do ra CSV (tep, dong, ly_do) nếu truyền reject_path.
class L2DatasetImporter
  DATA_DIR    = Rails.root.parent.join("data", "mau")
  FILES       = %w[issue_categories.csv customers.csv products.csv devices.csv tickets.csv].freeze
  CODE_OFFSET = 100_000

  PRIORITY_NAMES = { "THAP" => "Thấp", "TRUNG_BINH" => "Trung bình", "CAO" => "Cao", "KHAN_CAP" => "Khẩn cấp" }.freeze
  PRIORITY_SLA   = { "Thấp" => 72, "Trung bình" => 48, "Cao" => 24, "Khẩn cấp" => 8 }.freeze
  BRAND_NAMES    = { "OPPO" => "Oppo", "realme" => "Realme", "vivo" => "Vivo", "TECNO" => "Tecno" }.freeze
  ACCESSORY      = /pin dự phòng|ốp lưng|cáp|sạc|tai nghe/i
  TABLET         = /\btab\b/i

  COUNT_LABELS   = { nhom_su_co: "nhóm sự cố", khach_hang: "khách hàng", thiet_bi: "thiết bị", yeu_cau: "yêu cầu" }.freeze

  Result = Data.define(:counts, :rejected) do
    def summary
      parts = counts.map { |key, (added, existing)| "#{COUNT_LABELS[key]} mới #{added} (đã có #{existing})" }
      "#{parts.join(' · ')} · loại #{rejected.size} dòng"
    end
  end

  def self.call(dir = DATA_DIR, created_by: nil, reject_path: nil, now: Time.current)
    new(dir, created_by: created_by, reject_path: reject_path, now: now).call
  end

  def initialize(dir, created_by:, reject_path:, now:)
    @dir         = Pathname(dir)
    @created_by  = created_by
    @reject_path = reject_path
    @now         = now
    @counts      = Hash.new { |hash, key| hash[key] = [0, 0] }
    @rejected    = []
  end

  def call
    missing = FILES.reject { |name| @dir.join(name).exist? }
    raise ArgumentError, "Thiếu tệp dữ liệu trong #{@dir}: #{missing.join(', ')}" if missing.any?

    @created_by ||= User.receptionist.order(:id).first!

    ActiveRecord::Base.transaction do
      @categories = import_categories
      @customers  = import_customers
      @products   = read("products.csv").to_h { |row| [row["product_id"], row["product_name"].to_s.squish] }
      import_devices
      import_tickets
    end

    write_rejects
    Result.new(counts: @counts.slice(:nhom_su_co, :khach_hang, :thiet_bi, :yeu_cau), rejected: @rejected)
  end

  private

  # ---------- Từng bảng ----------
  def import_categories
    read("issue_categories.csv").to_h do |row|
      category = IssueCategory.find_by(name: row["category_name"].to_s.squish)
      if category
        @counts[:nhom_su_co][1] += 1
      else
        category = IssueCategory.create!(name: row["category_name"].to_s.squish)
        @counts[:nhom_su_co][0] += 1
      end
      [row["category_id"], category]
    end
  end

  def import_customers
    read("customers.csv").each_with_object({}) do |row, map|
      phone = normalize_phone(row["phone"])
      next reject("customers.csv", row["customer_id"], "SĐT không hợp lệ: #{row['phone']}") unless phone

      customer = Customer.find_by(phone: phone)
      if customer
        @counts[:khach_hang][1] += 1
      else
        customer = Customer.new(code: format("KH-%06d", CODE_OFFSET + row["customer_id"].to_i),
                                name: row["full_name"].to_s.squish, phone: phone,
                                email: clean_email(row["email"]), address: row["address"].to_s.squish.presence)
        next reject("customers.csv", row["customer_id"], customer.errors.full_messages.join("; ")) unless customer.save

        @counts[:khach_hang][0] += 1
      end
      map[row["customer_id"]] = customer
    end
  end

  def import_devices
    read("devices.csv").each do |row|
      customer = @customers[row["customer_id"]]
      product  = @products[row["product_id"]]
      date     = parse_date(row["purchase_date"])
      next reject("devices.csv", row["device_id"], "khách hàng #{row['customer_id']} không nạp được") unless customer
      next reject("devices.csv", row["device_id"], "không có sản phẩm #{row['product_id']}") unless product
      next reject("devices.csv", row["device_id"], "thiếu hoặc sai ngày mua (BR02)") unless date

      device = Device.find_by(serial_number: row["serial_no"].to_s.strip)
      if device
        next reject("devices.csv", row["device_id"], "serial đã thuộc khách hàng khác") if device.customer_id != customer.id

        @counts[:thiet_bi][1] += 1
        next
      end

      brand, model = split_product(product)
      device = Device.new(customer: customer, device_type: device_type_for(product), brand: brand, model: model,
                          serial_number: row["serial_no"].to_s.strip, purchase_date: date)
      next reject("devices.csv", row["device_id"], device.errors.full_messages.join("; ")) unless device.save

      @counts[:thiet_bi][0] += 1
    end
  end

  def import_tickets
    read("tickets.csv").each do |row|
      id       = row["source_ticket_id"]
      device   = Device.find_by(serial_number: row["serial_no"].to_s.strip)
      category = @categories[row["category_id"]]
      priority = priority_for(row["priority"])
      text     = clean_description(row["issue_desc"])
      next reject("tickets.csv", id, "không có thiết bị serial #{row['serial_no']}") unless device
      next reject("tickets.csv", id, "thiết bị không thuộc khách #{row['customer_id']}") if @customers[row["customer_id"]]&.id != device.customer_id
      next reject("tickets.csv", id, "không có nhóm sự cố #{row['category_id']}") unless category
      next reject("tickets.csv", id, "mức ưu tiên không hợp lệ: #{row['priority']}") unless priority
      next reject("tickets.csv", id, "thiếu mô tả lỗi (BR04)") if text.blank?

      if WarrantyRequest.exists?(device: device, issue_description: text)
        @counts[:yeu_cau][1] += 1
        next
      end

      created_at = @now - row["hours_ago"].to_i.hours
      request = WarrantyRequest.create!(
        code: RequestCodeGenerator.next_code(year: created_at.year), device: device,
        issue_category: category, priority: priority, created_by: @created_by,
        issue_description: text, status: :received,
        due_at: SlaDeadlineCalculator.call(priority, from: created_at),
        created_at: created_at, updated_at: created_at
      )
      request.status_logs.create!(from_status: nil, to_status: WarrantyRequest.statuses[:received],
                                  note: "Tiếp nhận yêu cầu (nạp từ tickets.csv ##{id})",
                                  changed_by: @created_by, created_at: created_at)
      @counts[:yeu_cau][0] += 1
    end
  end

  # ---------- Làm sạch ----------
  def read(name)
    CSV.read(@dir.join(name), headers: true, encoding: "bom|utf-8").map(&:to_h)
  end

  def normalize_phone(raw)
    digits = raw.to_s.gsub(/\D/, "")
    digits = "0#{digits[2..]}" if digits.start_with?("84") && digits.length == 11
    digits.match?(Customer::PHONE_FORMAT) ? digits : nil
  end

  def clean_email(raw)
    email = raw.to_s.strip.downcase
    email.match?(URI::MailTo::EMAIL_REGEXP) ? email : nil
  end

  def parse_date(raw)
    date = Date.iso8601(raw.to_s.strip)
    date <= @now.to_date ? date : nil
  rescue Date::Error
    nil
  end

  # "  MÁY TỰ KHỞI ĐỘNG LẠI  " → "Máy tự khởi động lại"; giữ nguyên câu viết thường / không dấu
  def clean_description(raw)
    text = raw.to_s.squish
    text = text.downcase if text == text.upcase
    text.empty? ? text : (text[0].upcase + text[1..]).first(1000)
  end

  def split_product(name)
    brand, model = name.split(" ", 2)
    [BRAND_NAMES.fetch(brand, brand), model.presence || brand]
  end

  def device_type_for(name)
    return "Khác" if name.match?(ACCESSORY)
    return "Máy tính bảng" if name.match?(TABLET)

    "Điện thoại"
  end

  def priority_for(raw)
    name = PRIORITY_NAMES[raw.to_s.strip.upcase]
    name && Priority.find_or_create_by!(name: name) { |p| p.sla_hours = PRIORITY_SLA.fetch(name) }
  end

  def reject(file, line_id, reason)
    @rejected << [file, line_id, reason]
    nil
  end

  def write_rejects
    return unless @reject_path

    FileUtils.mkdir_p(File.dirname(@reject_path))
    CSV.open(@reject_path, "w") do |csv|
      csv << %w[tep dong ly_do]
      @rejected.each { |row| csv << row }
    end
  end
end
