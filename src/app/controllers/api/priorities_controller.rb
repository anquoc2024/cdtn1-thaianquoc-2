# GET /api/priorities – danh mục mức ưu tiên và số giờ SLA, dùng cho form tạo yêu cầu và bộ lọc (TD-26)
module Api
  class PrioritiesController < BaseController
    before_action -> { require_permission!(:view_requests) }

    def index
      data = Priority.ordered.map { |p| { id: p.id, name: p.name, sla_hours: p.sla_hours } }
      render json: { data: data, meta: { tong_so: data.size } }
    end
  end
end
