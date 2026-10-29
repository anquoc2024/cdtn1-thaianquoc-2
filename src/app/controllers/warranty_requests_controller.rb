# Màn hình 2 – UC02–UC06 Tạo yêu cầu bảo hành; phiếu tiếp nhận; cập nhật trạng thái / hủy (S2);
# sửa / xóa yêu cầu – chỉ Nhân viên tiếp nhận (TD-29)
class WarrantyRequestsController < ApplicationController
  require_permission :create_requests, only: %i[new create]
  require_permission :view_requests,   only: :show
  require_permission :change_status,   only: :update_status
  require_permission :edit_requests,   only: %i[edit update]
  require_permission :delete_requests, only: :destroy
  before_action :set_customer, only: [:new, :create]
  before_action :load_options, only: %i[new create edit update]
  before_action :set_warranty_request, only: %i[edit update destroy]

  def new
    @form = WarrantyRequestForm.new(customer_name: @customer.name)
  end

  def create
    @form  = WarrantyRequestForm.new(form_params)
    result = WarrantyRequestCreator.call(form: @form, customer: @customer, created_by: current_user)

    if result.success?
      redirect_to result.warranty_request, notice: "Tạo yêu cầu bảo hành thành công."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @warranty_request = WarrantyRequest
                          .includes(:issue_category, :priority, device: :customer, status_logs: :changed_by)
                          .find(params[:id])
  end

  # TD-29 – Sửa thông tin yêu cầu: thiết bị, mô tả lỗi, nhóm sự cố, mức ưu tiên (mọi trạng thái)
  def edit
    @form = WarrantyRequestEditForm.from(@warranty_request)
  end

  def update
    @form  = WarrantyRequestEditForm.from(@warranty_request).tap { |form| form.assign_attributes(edit_params) }
    result = WarrantyRequestUpdater.call(warranty_request: @warranty_request, form: @form, changed_by: current_user)

    if result.success?
      redirect_to @warranty_request, notice: "Đã cập nhật yêu cầu #{@warranty_request.code}."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # TD-29 – Xóa yêu cầu (kèm lịch sử trạng thái); thiết bị và khách hàng giữ nguyên
  def destroy
    result = WarrantyRequestDestroyer.call(warranty_request: @warranty_request, deleted_by: current_user)

    if result.success?
      redirect_to manager_warranty_requests_path, notice: "Đã xóa yêu cầu #{@warranty_request.code}.", status: :see_other
    else
      redirect_to @warranty_request, alert: result.message
    end
  end

  # S2 – Cập nhật trạng thái / hủy yêu cầu (phần U, D của CRUD)
  def update_status
    warranty_request = WarrantyRequest.find(params[:id])
    result = WarrantyRequestStatusChanger.call(
      warranty_request: warranty_request,
      to_status:        params[:to_status],
      changed_by:       current_user,
      note:             params[:note]
    )

    if result.success?
      label = WarrantyRequest::STATUS_LABELS[warranty_request.status]
      redirect_to warranty_request, notice: "Đã chuyển yêu cầu #{warranty_request.code} sang “#{label}”."
    else
      redirect_to warranty_request, alert: result.error
    end
  end

  private

  # BR01 – phải xác định khách hàng trước khi tạo yêu cầu
  def set_customer
    @customer = Customer.find_by(id: params[:customer_id])
    return if @customer

    redirect_to search_customers_path,
                alert: "Vui lòng tra cứu và chọn khách hàng trước khi tạo yêu cầu (BR01)."
  end

  def set_warranty_request
    @warranty_request = WarrantyRequest.includes(device: :customer).find(params[:id])
  end

  def edit_params
    params.require(:warranty_request).permit(*WarrantyRequestEditForm.attribute_names)
  end

  def load_options
    @issue_categories = IssueCategory.order(:name)
    @priorities       = Priority.ordered
  end

  def form_params
    params.require(:warranty_request).permit(
      :customer_name, :device_type, :brand, :model, :serial_number, :purchase_date,
      :warranty_card_number, :issue_description, :issue_category_id, :priority_id
    )
  end
end
