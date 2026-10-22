# Cho phép tìm tên không dấu: "nguyen van" vẫn ra "Nguyễn Văn ..."
class EnableUnaccent < ActiveRecord::Migration[8.1]
  def change
    enable_extension "unaccent"
  end
end
