# Nạp dữ liệu mẫu của giảng viên
#
#   bin/rails import:customers                                  # khách hàng – bộ mẫu data/mau/customers_mau.csv (TD-23)
#   bin/rails "import:customers[../data/customer.csv]"         # file đầy đủ của giảng viên (không commit)
#   bin/rails "import:customers[../data/customer.csv,1000]"    # 1000 dòng đầu file đầy đủ
#   bin/rails import:l2                                         # bộ dữ liệu L2 data/mau/*.csv: khách, thiết bị, yêu cầu (TD-28)
namespace :import do
  desc "Nạp khách hàng từ customers_raw.csv (làm sạch, gộp trùng SĐT, ghi danh sách dòng bị loại)"
  task :customers, [:path, :limit] => :environment do |_task, args|
    path        = args[:path].presence || CustomerCsvImporter::DATA_PATH
    limit       = args[:limit].presence&.to_i
    reject_path = Rails.root.join("tmp/import/customers_reject.csv")

    result = CustomerCsvImporter.call(path, limit: limit, reject_path: reject_path)
    puts "customers_raw: #{result.summary}"
    puts "Dòng bị loại kèm lý do: #{reject_path.relative_path_from(Rails.root)}" if result.rejected.any?
  end

  desc "Nạp bộ dữ liệu L2 (nhóm sự cố, khách hàng, thiết bị, phiếu bảo hành) từ data/mau/*.csv"
  task :l2, [:dir] => :environment do |_task, args|
    dir         = args[:dir].presence || L2DatasetImporter::DATA_DIR
    reject_path = Rails.root.join("tmp/import/l2_reject.csv")

    result = L2DatasetImporter.call(dir, reject_path: reject_path)
    puts "Bộ dữ liệu L2: #{result.summary}"
    puts "Dòng bị loại kèm lý do: #{reject_path.relative_path_from(Rails.root)}" if result.rejected.any?
  end
end
