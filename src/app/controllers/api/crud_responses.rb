# Dịch ServiceResult của các service CRUD sang phản hồi JSON (TD-25) – dùng chung cho các API CRUD.
# Đây là nơi DUY NHẤT ánh xạ mã lỗi nghiệp vụ → mã HTTP cho CRUD.
module Api
  module CrudResponses
    CRUD_ERRORS = {
      invalid:   [:bad_request, "DU_LIEU_KHONG_HOP_LE"],
      duplicate: [:conflict,    "TRUNG_DU_LIEU"],
      in_use:    [:conflict,    "DANG_DUOC_SU_DUNG"]
    }.freeze

    private

    def render_service_result(result, serializer, success_status: :ok)
      if result.success?
        return head :no_content if success_status == :no_content

        render json: { data: serializer.call(result.record) }, status: success_status
      else
        http_status, code = CRUD_ERRORS.fetch(result.error_code)
        chi_tiet = result.errors.any? ? { cac_truong: result.errors } : nil
        render_error(http_status, code, result.message, chi_tiet)
      end
    end

    # Phân trang đơn giản: ?page=1 (mặc định), cố định per_page
    def paginate(scope, per_page:)
      page  = [params[:page].to_i, 1].max
      total = scope.count
      [scope.offset((page - 1) * per_page).limit(per_page),
       { trang: page, so_trang: [(total.to_f / per_page).ceil, 1].max, tong_so: total, moi_trang: per_page }]
    end
  end
end
