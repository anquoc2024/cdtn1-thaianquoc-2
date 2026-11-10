require "test_helper"

# BUG-08 – Seed chạy ngoài development (container production, test) không được in mật khẩu demo
# hay API token ra màn hình, vì đầu ra đó nằm lại trong log container (checklist bảo mật mục 6).
class SeedsOutputTest < ActiveSupport::TestCase
  test "seed ngoài development: có in tài khoản demo nhưng không in mật khẩu, không in token" do
    output, = capture_io { load Rails.root.join("db/seeds.rb") }

    assert_includes output, "quoc@mekong.vn"
    assert_not_includes output, "Mekong@2026"
    User.where.not(api_token: nil).pluck(:api_token).each do |token|
      assert_not_includes output, token
    end
  end
end
