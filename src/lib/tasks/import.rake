# Nạp khách hàng từ bộ dữ liệu mẫu của giảng viên (TD-23)
#
#   bin/rails import:customers                                  # toàn bộ data/customer.csv
#   bin/rails "import:customers[/duong/dan/customers_raw.csv]"  # file đầy đủ
#   bin/rails "import:customers[,1000]"                        # 1000 dòng đầu của data/customer.csv
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
