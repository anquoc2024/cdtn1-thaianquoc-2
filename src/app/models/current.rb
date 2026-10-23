# Người dùng của request hiện tại – Current.user dùng được trong controller, view, service
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :user, to: :session, allow_nil: true
end
