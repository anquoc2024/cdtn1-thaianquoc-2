# Chuyển IssueCategory thành Hash để trả JSON (API – TD-25)
class IssueCategorySerializer
  def self.call(category, usage_count: nil)
    {
      id:          category.id,
      name:        category.name,
      description: category.description,
      usage_count: usage_count
    }.compact
  end
end
