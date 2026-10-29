# API JSON cho yêu cầu bảo hành – CRUD của entity chính (buổi 8)
#
#   GET   /api/warranty_requests             danh sách (lọc, sắp xếp, phân trang) – UC07
#   GET   /api/warranty_requests/:id         chi tiết + lịch sử trạng thái
#   POST  /api/warranty_requests             tạo yêu cầu – UC06
#   PATCH /api/warranty_requests/:id/status  đổi trạng thái / hủy – S2
#   PATCH /api/warranty_requests/:id         sửa thông tin (gửi trường nào sửa trường đó) – TD-29
#   DELETE /api/warranty_requests/:id        xóa yêu cầu kèm lịch sử – TD-29
#
# Controller chỉ dịch HTTP ↔ service; quy tắc nghiệp vụ nằm trong các service dùng chung với giao diện.
# TD-24, TD-29: mọi endpoint cần token. Quản lý xem và tạo được; đổi trạng thái, sửa, xóa là của Nhân viên tiếp nhận.
module Api
  class WarrantyRequestsController < BaseController
    # Mã lỗi nghiệp vụ → mã HTTP
    STATUS_ERRORS = {
      invalid_status:     [:bad_request,          "TRANG_THAI_KHONG_HOP_LE"],
      note_required:      [:bad_request,          "THIEU_LY_DO_HUY"],
      closed:             [:conflict,             "YEU_CAU_DA_DONG"],
      invalid_transition: [422,                   "CHUYEN_TRANG_THAI_KHONG_HOP_LE"]
    }.freeze

    before_action -> { require_permission!(:view_request_list) }, only: :index
    before_action -> { require_permission!(:view_requests) },     only: :show
    before_action -> { require_permission!(:create_requests) },   only: :create
    before_action -> { require_permission!(:change_status) },     only: :update_status
    before_action -> { require_permission!(:edit_requests) },     only: :update
    before_action -> { require_permission!(:delete_requests) },   only: :destroy

    def index
      search = WarrantyRequestSearch.new(
        params.permit(:q, :status, :issue_category_id, :priority_id, :from, :to, :sort, :page)
      )
      render json: {
        data: search.results.map { |item| WarrantyRequestSerializer.summary(item) },
        meta: { trang: search.current_page, so_trang: search.total_pages,
                tong_so: search.total_count, moi_trang: WarrantyRequestSearch::PER_PAGE }
      }
    end

    def show
      item = WarrantyRequest
               .includes(:issue_category, :priority, device: :customer, status_logs: :changed_by)
               .find(params[:id])
      render json: { data: WarrantyRequestSerializer.detail(item) }
    end

    def create
      customer = Customer.find_by(id: params[:customer_id])
      unless customer
        return render_error(:not_found, "KHACH_HANG_KHONG_TON_TAI",
                            "Không tìm thấy khách hàng có mã #{params[:customer_id].inspect} (BR01).")
      end

      form = WarrantyRequestForm.new(create_params.merge(customer_name: params[:customer_name].presence || customer.name))
      result = WarrantyRequestCreator.call(form: form, customer: customer, created_by: current_user)

      if result.success?
        item = result.warranty_request
        response.headers["Location"] = api_warranty_request_path(item)
        render json: { data: WarrantyRequestSerializer.detail(item.reload) }, status: :created
      else
        render_create_error(result, form)
      end
    end

    def update_status
      item = WarrantyRequest.find(params[:id])
      result = WarrantyRequestStatusChanger.call(
        warranty_request: item, to_status: params.require(:status),
        changed_by: current_user, note: params[:note]
      )

      if result.success?
        render json: { data: WarrantyRequestSerializer.detail(item.reload) }
      else
        http_status, code = STATUS_ERRORS.fetch(result.error_code)
        render_error(http_status, code, result.error)
      end
    end

    # TD-29 – PATCH /api/warranty_requests/:id
    def update
      item = WarrantyRequest.includes(device: :customer).find(params[:id])
      form = WarrantyRequestEditForm.from(item).tap { |f| f.assign_attributes(params.permit(*WarrantyRequestEditForm.attribute_names)) }
      result = WarrantyRequestUpdater.call(warranty_request: item, form: form, changed_by: current_user)

      if result.success?
        render json: { data: WarrantyRequestSerializer.detail(item.reload) }
      else
        render_error(:bad_request, "DU_LIEU_KHONG_HOP_LE", result.message, { cac_truong: result.errors })
      end
    end

    # TD-29 – DELETE /api/warranty_requests/:id
    def destroy
      item = WarrantyRequest.find(params[:id])
      result = WarrantyRequestDestroyer.call(warranty_request: item, deleted_by: current_user)
      return head :no_content if result.success?

      render_error(:conflict, "KHONG_XOA_DUOC", result.message)
    end

    private

    def create_params
      params.permit(:device_type, :brand, :model, :serial_number, :purchase_date,
                    :warranty_card_number, :issue_description, :issue_category_id, :priority_id)
    end

    def render_create_error(result, form)
      case result.error_code
      when :serial_taken
        render_error(:conflict, "SERIAL_THUOC_KHACH_KHAC", form.errors[:serial_number].first)
      else
        fields = form.errors.map { |e| { truong: e.attribute.to_s, ly_do: e.message } }
        render_error(:bad_request, "DU_LIEU_KHONG_HOP_LE",
                     "Dữ liệu vào không hợp lệ ở các trường: #{fields.map { |f| f[:truong] }.uniq.join(', ')}",
                     { cac_truong: fields })
      end
    end
  end
end
