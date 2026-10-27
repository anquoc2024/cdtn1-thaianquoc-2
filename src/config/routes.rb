Rails.application.routes.draw do
  # Kiểm tra ứng dụng còn chạy (Rails mặc định)
  get "up" => "rails/health#show", as: :rails_health_check

  # Đăng nhập / đăng xuất (TD-24)
  resource :session, only: %i[new create destroy]

  # Màn hình 1 – Tra cứu khách hàng (UC01, UC08)
  get "customers/search", to: "customers#search", as: :search_customers

  # Màn hình 2 – Tạo yêu cầu bảo hành (UC02–UC06) + phiếu tiếp nhận
  resources :warranty_requests, only: [:new, :create, :show] do
    # Cập nhật trạng thái / hủy (UC09, UC10): PATCH /warranty_requests/:id/update_status
    patch :update_status, on: :member
  end

  # Màn hình 3 – Danh sách yêu cầu cho Quản lý trung tâm (UC07)
  namespace :manager do
    resources :warranty_requests, only: [:index]
  end

  # API JSON (TD-21) – gọi bằng curl / Postman, xác thực bằng token (TD-24)
  namespace :api do
    resource :session, only: %i[create destroy]   # POST / DELETE /api/session – lấy token (TD-24)
    resources :customers,        only: %i[index show create update destroy]   # CRUD Khách hàng (TD-25)
    resources :issue_categories, only: %i[index show create update destroy]   # CRUD Nhóm sự cố (TD-25)
    resource  :stats,      only: :show    # GET /api/stats – thẻ thống kê có mốc so sánh (TD-26)
    resources :priorities, only: :index   # GET /api/priorities – danh mục mức ưu tiên (TD-26)
    get "health", to: "health#show"
    resources :warranty_requests, only: [:index, :show, :create] do
      patch :status, on: :member, action: :update_status   # PATCH /api/warranty_requests/:id/status
    end
  end

  # Trang chủ mở Màn hình 1
  root "customers#search"
end
