# Mục trên thanh bên. Sidebar luôn hiện đủ 3 mục; mục không có quyền thì mờ + icon ổ khóa (TD-24).
# Bấm vào mục bị khóa → controller chặn và báo "không có quyền".
module NavigationHelper
  def sidebar_item(label, path, icon:, active:, permission:)
    allowed = can?(permission)
    classes = ["nav__item"]
    classes << "nav__item--active" if active
    classes << "nav__item--locked" unless allowed

    tag.li(class: classes) do
      link_to(path, title: (allowed ? label : "#{label} – vai trò #{current_user.role_label} không có quyền"),
                    aria: { disabled: !allowed }) do
        safe_join([
          tag.i(class: "ph #{icon} nav__icon", aria: { hidden: true }),
          tag.span(label),
          (tag.i(class: "ph ph-lock-simple nav__lock", aria: { label: "Không có quyền" }) unless allowed)
        ].compact)
      end
    end
  end
end
