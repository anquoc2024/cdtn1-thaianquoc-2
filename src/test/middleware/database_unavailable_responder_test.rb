require "test_helper"

# TD-27 – lỗi mất CSDL xảy ra TRƯỚC controller (ở middleware) vẫn trả 503 có mã tra cứu
class DatabaseUnavailableResponderTest < ActiveSupport::TestCase
  FAILING_APP = ->(_env) { raise ActiveRecord::ConnectionNotEstablished, "connection to socket .s.PGSQL.5432 failed" }

  def call(path)
    env = Rack::MockRequest.env_for(path, "action_dispatch.request_id" => "ma-tra-cuu-123")
    DatabaseUnavailableResponder.new(FAILING_APP).call(env)
  end

  test "đường dẫn /api trả 503 JSON CSDL_KHONG_KHA_DUNG kèm mã tra cứu" do
    status, headers, body = call("/api/customers")
    json = JSON.parse(body.join)

    assert_equal 503, status
    assert_equal "30", headers["retry-after"]
    assert_equal "CSDL_KHONG_KHA_DUNG", json["error"]
    assert_equal "ma-tra-cuu-123", json.dig("chi_tiet", "ma_tra_cuu")
    assert_no_match(/PGSQL|ConnectionNotEstablished/, body.join)
  end

  test "trang web trả 503 HTML có mã tra cứu và nút Thử lại" do
    status, headers, body = call("/customers/search")
    html = body.join

    assert_equal 503, status
    assert_match "text/html", headers["content-type"]
    assert_includes html, "ma-tra-cuu-123"
    assert_includes html, "Thử lại"
    assert_no_match(/PGSQL|ConnectionNotEstablished/, html)
  end
end
