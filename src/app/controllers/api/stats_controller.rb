# GET /api/stats – số liệu thẻ thống kê Màn hình 3, mỗi số kèm mốc so sánh (UC07 · TD-26)
module Api
  class StatsController < BaseController
    before_action -> { require_permission!(:view_request_list) }

    def show
      render json: { data: DashboardStats.call }
    end
  end
end
