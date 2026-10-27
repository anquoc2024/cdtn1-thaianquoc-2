# GET /api/health – dịch vụ còn sống và còn kết nối được CSDL hay không (không cần token)
# Docker healthcheck và người vận hành gọi endpoint này: 200 = ổn, 503 = app sống nhưng mất CSDL.
module Api
  class HealthController < BaseController
    skip_before_action :authenticate_api_user!

    def show
      ActiveRecord::Base.connection.select_value("SELECT 1")
      render json: { status: "ok", db: "ok" }
    rescue *SystemErrorHandling::DATABASE_UNAVAILABLE_ERRORS => e
      Rails.logger.warn("HEALTH db=down ma_tra_cuu=#{lookup_code} – #{e.class}")
      render json: { status: "degraded", db: "khong ket noi duoc", ma_tra_cuu: lookup_code },
             status: :service_unavailable
    end
  end
end
