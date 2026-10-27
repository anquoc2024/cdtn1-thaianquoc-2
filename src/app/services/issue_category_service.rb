# CRUD Nhóm sự cố (TD-25) – lớp nghiệp vụ, không chứa params / render / mã HTTP
#
# Quy tắc nghiệp vụ:
#   BR03  Tên nhóm sự cố bắt buộc, tối đa 100 ký tự, DUY NHẤT (không phân biệt hoa thường, bỏ khoảng trắng thừa)
#   BR14  Không xóa nhóm sự cố đang được yêu cầu bảo hành sử dụng
class IssueCategoryService
  FIELDS = %i[name description].freeze

  def self.create(attributes)               = new.create(attributes)
  def self.update(category, attributes)     = new.update(category, attributes)
  def self.destroy(category)                = new.destroy(category)

  def create(attributes)
    save(IssueCategory.new(clean(attributes)))
  end

  def update(category, attributes)
    category.assign_attributes(clean(attributes))
    save(category)
  end

  def destroy(category)
    used = WarrantyRequest.where(issue_category_id: category.id).count
    if used.positive?
      return ServiceResult.failure(:in_use,
                                "Không xóa được nhóm \"#{category.name}\" vì đang được #{used} yêu cầu bảo hành sử dụng (BR14).",
                                record: category)
    end

    category.destroy!
    ServiceResult.ok(category)
  end

  private

  def clean(attributes)
    data = attributes.to_h.symbolize_keys.slice(*FIELDS)
    data[:name] = data[:name].to_s.squish if data.key?(:name)
    data[:description] = data[:description].presence if data.key?(:description)
    data
  end

  def save(category)
    if duplicate_name?(category)
      return ServiceResult.failure(:duplicate, "Tên nhóm sự cố đã tồn tại.",
                                errors: [{ truong: "name", ly_do: "đã tồn tại" }], record: category)
    end
    return ServiceResult.ok(category) if category.save

    ServiceResult.failure(:invalid, "Thông tin nhóm sự cố không hợp lệ.",
                       errors: FieldErrors.of(category),
                       record: category)
  end

  def duplicate_name?(category)
    return false if category.name.blank?

    IssueCategory.where("LOWER(name) = ?", category.name.downcase).where.not(id: category.id).exists?
  end
end
