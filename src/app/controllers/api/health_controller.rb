# GET /api/health – dịch vụ còn sống và còn kết nối được CSDL hay không (không cần token)
module Api
  class HealthController < BaseController
    skip_before_action :authenticate_api_user!

    def show
      ActiveRecord::Base.connection.select_value("SELECT 1")
      render json: { status: "ok", db: "ok" }
    rescue StandardError
      render json: { status: "degraded", db: "khong ket noi duoc" }, status: :service_unavailable
    end
  end
end
