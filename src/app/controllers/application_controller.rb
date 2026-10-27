class ApplicationController < ActionController::Base
  # Chỉ cho phép trình duyệt hiện đại (mặc định của Rails 8)
  allow_browser versions: :modern

  # TD-24: bắt buộc đăng nhập + phân quyền theo vai trò (thay cho DefaultCurrentUser của TD-11)
  include Authentication
  include Authorization

  # TD-27: lỗi hệ thống → trang báo lỗi thân thiện có mã tra cứu và nút Thử lại (xem SystemErrorHandling).
  # rescue_from khai báo SAU được ưu tiên: StandardError đứng đầu, lỗi CSDL đứng sau.
  include SystemErrorHandling
  rescue_from StandardError, with: :render_internal_error
  rescue_from(*SystemErrorHandling::DATABASE_UNAVAILABLE_ERRORS, with: :render_database_unavailable)

  private

  # Mất CSDL: luôn hiện trang 503 thân thiện (mọi môi trường, để demo được bằng cách tắt PostgreSQL)
  def render_database_unavailable(exception)
    log_system_error(exception, "CSDL_KHONG_KHA_DUNG")
    response.set_header("Retry-After", SystemErrorHandling::RETRY_AFTER_SECONDS.to_s)
    render_error_page(:service_unavailable,
                      title: "Hệ thống tạm thời không truy cập được dữ liệu",
                      message: "Máy chủ cơ sở dữ liệu đang không phản hồi. Dữ liệu của bạn không bị mất. " \
                               "Vui lòng đợi ít phút rồi bấm Thử lại.")
  end

  # Lỗi không lường trước. Lỗi có mã riêng (404 không tìm thấy, 422 sai CSRF...) để Rails xử lý như cũ.
  # Môi trường phát triển giữ trang báo lỗi chi tiết của Rails, trừ khi bật FRIENDLY_ERRORS=1.
  def render_internal_error(exception)
    status = ActionDispatch::ExceptionWrapper.status_code_for_exception(exception.class.name)
    raise exception if status != 500 || !Rails.application.config.x.friendly_error_pages

    log_system_error(exception, "LOI_HE_THONG")
    render_error_page(:internal_server_error,
                      title: "Hệ thống đang gặp sự cố",
                      message: "Thao tác chưa được thực hiện. Vui lòng thử lại; nếu vẫn lỗi, " \
                               "báo cho quản trị kèm mã tra cứu bên dưới.")
  end

  def render_error_page(status, title:, message:)
    @error_title   = title
    @error_message = message
    @lookup_code   = lookup_code
    @retry_url     = request.get? ? request.fullpath : (request.referer.presence || "/")
    render "errors/show", layout: "error", status: status, formats: :html
  end
end
