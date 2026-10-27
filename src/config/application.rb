require_relative "boot"

require "rails/all"
require_relative "../lib/middleware/database_unavailable_responder"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Src
  class Application < Rails::Application
    config.time_zone = "Asia/Ho_Chi_Minh"
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks middleware])

    # TD-27 – mọi dòng log gắn request_id (= mã tra cứu người dùng thấy trên trang lỗi / phản hồi API),
    # nên grep "<mã tra cứu>" log/development.log ra đủ các dòng của đúng request đó.
    config.log_tags = [ :request_id ]

    # TD-27 – lưới an toàn: lỗi mất CSDL xảy ra trước controller (vd. middleware kiểm tra migration ở
    # môi trường phát triển) vẫn trả 503 có mã tra cứu thay vì trang lỗi chi tiết của Rails
    config.middleware.insert_after ActionDispatch::DebugExceptions, DatabaseUnavailableResponder

    # TD-27 – trang lỗi 500 thân thiện: bật mặc định ở production; ở máy phát triển giữ trang lỗi chi tiết
    # của Rails, muốn xem trang thân thiện thì chạy: FRIENDLY_ERRORS=1 bin/rails server
    # (trang 503 khi mất CSDL luôn bật ở mọi môi trường)
    config.x.friendly_error_pages = ENV.fetch("FRIENDLY_ERRORS") { Rails.env.production? ? "1" : "0" } == "1"
  end
end
