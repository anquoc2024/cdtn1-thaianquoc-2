# Màn hình 1 – UC01 Tra cứu khách hàng (SĐT / mã KH / tên), UC08 Không tìm thấy khách hàng
class CustomersController < ApplicationController
  require_permission :lookup_customers
  require_permission :lookup_customers
  def search
    # Nhận cả tham số cũ "phone" (nút "Quay lại" ở Màn hình 2) và tham số mới "q"
    @query  = params[:q].presence || params[:phone]
    @result = CustomerLookupService.call(@query)
  end
end
