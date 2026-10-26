# Màn hình 2 – UC02–UC06 Tạo yêu cầu bảo hành; phiếu tiếp nhận; cập nhật trạng thái / hủy (S2)
class WarrantyRequestsController < ApplicationController
  require_permission :create_requests, only: %i[new create]
  require_permission :view_requests,   only: :show
  require_permission :change_status,   only: :update_status
  require_permission :create_requests, only: %i[new create]
  require_permission :view_requests,   only: :show
  require_permission :change_status,   only: :update_status
  before_action :set_customer, only: [:new, :create]
  before_action :load_options, only: [:new, :create]

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
