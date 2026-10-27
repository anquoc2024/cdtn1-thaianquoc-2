# CRUD Nhóm sự cố – entity thứ ba có đủ 4 thao tác (BT2 – S1, TD-25)
#
#   GET    /api/issue_categories       danh sách (kèm số yêu cầu đang dùng)
#   GET    /api/issue_categories/:id   chi tiết
#   POST   /api/issue_categories       tạo
#   PATCH  /api/issue_categories/:id   sửa tên, mô tả
#   DELETE /api/issue_categories/:id   xóa – chỉ khi chưa có yêu cầu nào dùng (BR14)
#
# Xem: cả hai vai trò (cần cho bộ lọc danh sách). Thêm / sửa / xóa: Nhân viên tiếp nhận (manage_catalog).
module Api
  class IssueCategoriesController < BaseController
    include CrudResponses

    before_action -> { require_permission!(:view_requests) },  only: %i[index show]
    before_action -> { require_permission!(:manage_catalog) }, only: %i[create update destroy]
    before_action :set_category, only: %i[show update destroy]

    def index
      usage = WarrantyRequest.group(:issue_category_id).count
      data  = IssueCategory.order(:name).map do |category|
        IssueCategorySerializer.call(category, usage_count: usage.fetch(category.id, 0))
      end
      render json: { data: data, meta: { tong_so: data.size } }
    end

    def show
      usage = WarrantyRequest.where(issue_category_id: @category.id).count
      render json: { data: IssueCategorySerializer.call(@category, usage_count: usage) }
    end

    def create
      result = IssueCategoryService.create(category_params)
      response.headers["Location"] = api_issue_category_path(result.record) if result.success?
      render_service_result(result, IssueCategorySerializer, success_status: :created)
    end

    def update
      render_service_result(IssueCategoryService.update(@category, category_params), IssueCategorySerializer)
    end

    def destroy
      render_service_result(IssueCategoryService.destroy(@category), IssueCategorySerializer, success_status: :no_content)
    end

    private

    def set_category
      @category = IssueCategory.find(params[:id])
    end

    def category_params
      params.permit(:name, :description)
    end
  end
end
