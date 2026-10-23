# Phân quyền theo vai trò (NFR05, TD-24) – bảng quyền nằm ở User::PERMISSIONS
#
#   class Manager::WarrantyRequestsController < ApplicationController
#     require_permission :view_request_list
#   end
#
# Không có quyền → quay lại trang trước kèm thông báo; view dùng can?(:quyen) để khóa mục trên sidebar.
module Authorization
  extend ActiveSupport::Concern

  DENIED_MESSAGE = "Bạn không có quyền truy cập chức năng này. Chức năng chỉ dành cho Quản lý trung tâm.".freeze

  included do
    helper_method :can?
  end

  class_methods do
    def require_permission(permission, **options)
      before_action(**options) { authorize!(permission) }
    end
  end

  private

  def can?(permission)
    Current.user.present? && Current.user.can?(permission)
  end

  def authorize!(permission)
    return if can?(permission)

    redirect_back_or_to home_path_for(Current.user), alert: DENIED_MESSAGE
  end
end
