ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Chạy test song song theo số nhân CPU
    parallelize(workers: :number_of_processors)

    fixtures :all
  end
end
