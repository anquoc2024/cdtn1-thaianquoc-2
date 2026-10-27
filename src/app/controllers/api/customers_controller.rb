# CRUD Khách hàng – entity thứ hai có đủ 4 thao tác (BT2 – S1, TD-25)
#
#   GET    /api/customers          danh sách (q = SĐT / mã KH / họ tên, có phân trang)
#   GET    /api/customers/:id      chi tiết
#   POST   /api/customers          tạo – mã KH tự sinh
#   PATCH  /api/customers/:id      sửa họ tên, SĐT, email, địa chỉ
#   DELETE /api/customers/:id      xóa – chỉ khi chưa có thiết bị (BR13)
#
# Chỉ Nhân viên tiếp nhận (quyền lookup_customers / manage_customers). Controller chỉ dịch HTTP ↔ service.
module Api
  class CustomersController < BaseController
    include CrudResponses

    PER_PAGE = 20

    before_action -> { require_permission!(:lookup_customers) }, only: %i[index show]
    before_action -> { require_permission!(:manage_customers) }, only: %i[create update destroy]
    before_action :set_customer, only: %i[show update destroy]

    def index
      if params[:q].present?
        lookup = CustomerLookupService.call(params[:q])
        if lookup.invalid?
          return render_error(:bad_request, "DU_LIEU_KHONG_HOP_LE", lookup.error,
                              { cac_truong: [{ truong: "q", ly_do: lookup.error }] })
        end

        customers = lookup.customers
        meta = { trang: 1, so_trang: 1, tong_so: customers.size, moi_trang: PER_PAGE, tim_theo: lookup.mode }
      else
        customers, meta = paginate(Customer.order(created_at: :desc, id: :desc), per_page: PER_PAGE)
      end

      render json: { data: customers.map { |customer| CustomerSerializer.call(customer, history: true) }, meta: meta }
    end

    def show
      render json: { data: CustomerSerializer.call(@customer, history: true) }
    end

    def create
      result = CustomerService.create(customer_params)
      response.headers["Location"] = api_customer_path(result.record) if result.success?
      render_service_result(result, CustomerSerializer, success_status: :created)
    end

    def update
      render_service_result(CustomerService.update(@customer, customer_params), CustomerSerializer)
    end

    def destroy
      render_service_result(CustomerService.destroy(@customer), CustomerSerializer, success_status: :no_content)
    end

    private

    def set_customer
      @customer = Customer.find(params[:id])
    end

    def customer_params
      params.permit(:name, :phone, :email, :address)
    end
  end
end
