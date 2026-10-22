class IssueCategory < ApplicationRecord
  has_many :warranty_requests, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
end
