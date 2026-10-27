require "csv"

# Nạp khách hàng từ customers_raw.csv (bộ dữ liệu mẫu của giảng viên) vào bảng customers – TD-23
#
#   1. Đọc CSV (có thể giới hạn số dòng)
#   2. Làm sạch từng dòng bằng CustomerRowNormalizer; dòng lỗi → danh sách loại kèm lý do
#   3. Gộp các dòng trùng SĐT: giữ dòng có ngay_tao mới nhất, lấy email / địa chỉ còn thiếu từ dòng khác
#   4. Bỏ qua khách đã có SĐT trong hệ thống (chạy lại nhiều lần không bị trùng)
#   5. Lưu trong MỘT transaction; mã khách hàng = KH-(100000 + record_id), ví dụ record 1 → KH-100001,
#      không đụng các mã KH-000245… của dữ liệu mẫu tự tạo
#   6. Ghi danh sách dòng bị loại ra CSV (record_id, ly_do) nếu truyền reject_path
class CustomerCsvImporter
  DATA_PATH  = Rails.root.parent.join("data", "mau", "customers_mau.csv")   # bộ mẫu 300 dòng (data/mau/)
  SEED_LIMIT = 300                                             # db:seed chỉ nạp 300 dòng đầu
  CODE_OFFSET = 100_000

  Result = Data.define(:read, :imported, :merged, :skipped, :rejected) do
    def summary
      "đọc #{read} dòng · nạp mới #{imported} · gộp trùng SĐT #{merged} · " \
        "đã có sẵn #{skipped} · loại #{rejected.size}"
    end
  end

  def self.call(path = DATA_PATH, limit: nil, reject_path: nil)
    new(path, limit: limit, reject_path: reject_path).call
  end

  def initialize(path, limit: nil, reject_path: nil)
    @path        = path
    @limit       = limit
    @reject_path = reject_path
  end

  def call
    rows            = read_rows.map { |raw| CustomerRowNormalizer.call(raw) }
    valid, invalid  = rows.partition(&:valid?)
    rejected        = invalid.map { |row| [row.record_id, row.error] }
    unique          = deduplicate(valid)
    imported        = 0
    skipped         = 0

    Customer.transaction do
      unique.each do |row|
        if Customer.exists?(phone: row.phone)
          skipped += 1
          next
        end

        customer = build(row)
        if customer.save
          imported += 1
        else
          rejected << [row.record_id, customer.errors.full_messages.join("; ")]
        end
      end
    end

    write_rejects(rejected)
    Result.new(read: rows.size, imported: imported, merged: valid.size - unique.size,
               skipped: skipped, rejected: rejected)
  end

  private

  def read_rows
    rows = CSV.foreach(@path, headers: true, encoding: "bom|utf-8")
    (@limit ? rows.first(@limit) : rows.to_a).map(&:to_h)
  end

  def deduplicate(rows)
    rows.group_by(&:phone).map do |_phone, group|
      latest = group.max_by { |row| [row.created_on || Date.new(1900), row.record_id] }
      latest.with(email:   latest.email   || group.filter_map(&:email).first,
                  address: latest.address || group.filter_map(&:address).first)
    end
  end

  def build(row)
    created_at = row.created_on&.in_time_zone || Time.current
    Customer.new(code: format("KH-%06d", CODE_OFFSET + row.record_id), name: row.name,
                 phone: row.phone, email: row.email, address: row.address,
                 created_at: created_at, updated_at: created_at)
  end

  def write_rejects(rejected)
    return if @reject_path.nil?

    FileUtils.mkdir_p(File.dirname(@reject_path))
    CSV.open(@reject_path, "w") do |csv|
      csv << %w[record_id ly_do]
      rejected.each { |row| csv << row }
    end
  end
end
