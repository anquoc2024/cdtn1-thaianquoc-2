module PaginationHelper
  # Danh sách trang cần hiện, ví dụ trang 5/16: [1, :gap, 4, 5, 6, :gap, 16]
  def page_window(current, total)
    pages = ([1, total] + ((current - 1)..(current + 1)).to_a).select { |p| p.between?(1, total) }.uniq.sort
    pages.each_with_object([]) do |page, list|
      list << :gap if list.any? && page - list.last > 1
      list << page
    end
  end

  # Giữ nguyên bộ lọc khi chuyển trang
  def page_path(page)
    url_for(request.query_parameters.merge(page: page))
  end
end
