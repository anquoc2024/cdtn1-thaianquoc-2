# Màn hình 3 – UC07 Xem danh sách và trạng thái yêu cầu (Quản lý trung tâm)
# Không phân quyền theo vai trò – NFR05 nằm ngoài phạm vi (TD-11).
module Manager
  class WarrantyRequestsController < ApplicationController
    def index
      @search           = WarrantyRequestSearch.new(filter_params)
      @warranty_requests = @search.results
      @stats            = WarrantyRequestStats.call
      @issue_categories = IssueCategory.order(:name)
      @priorities       = Priority.ordered
    end

    private

    def filter_params
      params.permit(:q, :status, :issue_category_id, :priority_id, :from, :to, :sort, :page)
    end
  end
end
