ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Helper to temporarily replace singleton methods on a class
    def with_stub(klass, method_name, return_value)
      original = klass.respond_to?(method_name) ? klass.method(method_name) : nil
      begin
        klass.define_singleton_method(method_name) { return_value }
        yield
      ensure
        if original
          orig = original
          klass.define_singleton_method(method_name) do |*a, &b|
            orig.call(*a, &b)
          end
        else
          klass.singleton_class.send(:remove_method, method_name) rescue nil
        end
      end
    end
  end
end
