require "test_helper"
require "timeout"

class RefreshExchangeRatesJobAsyncTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  def setup
    @original_adapter = ActiveJob::Base.queue_adapter
    # use async adapter so scheduled retries are processed by a background thread
    ActiveJob::Base.queue_adapter = :async
    @original_refresh = ExchangeRateCacheService.respond_to?(:refresh_rates) ? ExchangeRateCacheService.method(:refresh_rates) : nil
    Rails.cache.clear
  end

  def teardown
    # restore queue adapter
    ActiveJob::Base.queue_adapter = @original_adapter

    # restore original refresh_rates method
    if @original_refresh
      orig = @original_refresh
      ExchangeRateCacheService.define_singleton_method(:refresh_rates) do |*a, &b|
        orig.call(*a, &b)
      end
    else
      ExchangeRateCacheService.singleton_class.send(:remove_method, :refresh_rates) rescue nil
    end

    Rails.cache.clear
  end

  test "async adapter processes scheduled retries until success" do
    call_count = 0

    # stub refresh_rates to fail twice then succeed
    ExchangeRateCacheService.define_singleton_method(:refresh_rates) do
      call_count += 1
      raise StandardError, "transient" if call_count < 3
      []
    end

    temp_name = "TmpAsyncRefreshJob#{Time.now.to_i}#{rand(1000)}"
    Object.const_set(temp_name, Class.new(RefreshExchangeRatesJob) do
      # short wait so retries are quick in tests
      retry_on StandardError, wait: 0.1.seconds, attempts: 3
    end)

    begin
      job_class = Object.const_get(temp_name)
      job_class.perform_later

      # Wait up to 5 seconds for retries to complete; the async adapter will process scheduled retries
      Timeout.timeout(5) do
        sleep 0.02 until call_count >= 3
      end

      assert_equal 3, call_count
    ensure
      Object.send(:remove_const, temp_name) rescue nil
    end
  end
end
