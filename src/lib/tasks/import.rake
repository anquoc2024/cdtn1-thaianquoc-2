# Nạp khách hàng từ bộ dữ liệu mẫu của giảng viên (TD-23)
#
#   bin/rails import:customers                                  # bộ mẫu data/mau/customers_mau.csv
#   bin/rails "import:customers[../data/customer.csv]"         # file đầy đủ của giảng viên (không commit)
#   bin/rails "import:customers[../data/customer.csv,1000]"    # 1000 dòng đầu file đầy đủ
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
end
