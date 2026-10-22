Rails.application.routes.draw do
  # Kiểm tra ứng dụng còn chạy (Rails mặc định)
  get "up" => "rails/health#show", as: :rails_health_check

  # Màn hình 1 – Tra cứu khách hàng (UC01, UC08)
  get "customers/search", to: "customers#search", as: :search_customers

  # Màn hình 2 – Tạo yêu cầu bảo hành (UC02–UC06) + phiếu tiếp nhận
  resources :warranty_requests, only: [:new, :create, :show] do
    # S2 – Cập nhật trạng thái / hủy: PATCH /warranty_requests/:id/update_status
    patch :update_status, on: :member
  end

  # Màn hình 3 – Danh sách yêu cầu cho Quản lý trung tâm (UC07)
  namespace :manager do
    resources :warranty_requests, only: [:index]
  end

  # S3 – API JSON (gọi bằng curl / Postman)
  namespace :api do
    namespace :v1 do
      resources :warranty_requests, only: [:show, :index, :create]
    end
  end

  # Trang chủ mở Màn hình 1
  root "customers#search"
end
