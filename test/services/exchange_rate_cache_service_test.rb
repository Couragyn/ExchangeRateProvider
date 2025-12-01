require "test_helper"

class ExchangeRateCacheServiceTest < ActiveSupport::TestCase
  def setup
    Rails.cache.clear
  end

  include ActiveSupport::Testing::TimeHelpers
  

  test "get_rates fetches and caches rates" do
    daily = [{"currencyCode" => "CAD", "amount" => "1", "rate" => "17.5", "validFor" => "2025-12-01"}]
    monthly = [{"currencyCode" => "BGN", "amount" => "1", "rate" => "12.0", "validFor" => "2025-11"}]

    # Stub the private fetch methods to return predictable data
    with_stub(ExchangeRateCacheService, :fetch_fresh_daily_rates, daily) do
      with_stub(ExchangeRateCacheService, :fetch_fresh_monthly_rates, monthly) do
        rates = ExchangeRateCacheService.get_rates
        assert_equal 2, rates.size
        assert rates.any? { |r| r["currencyCode"] == "CAD" }
        assert rates.any? { |r| r["currencyCode"] == "BGN" }

        # Assert returned merged rates
        assert_equal 2, rates.size

        # Now assert that the cache store contains the written value
        cached = Rails.cache.read(ExchangeRateCacheService::CACHE_KEY)
        assert_not_nil cached, "Expected cache to contain rates"
        assert_equal 2, cached.size
      end
    end
  end

  test "refresh_rates merges and deduplicates by currencyCode" do
    daily = [
      {"currencyCode" => "CAD", "amount" => "1", "rate" => "17.5"},
      {"currencyCode" => "BGN", "amount" => "1", "rate" => "12.0"}
    ]
    monthly = [
      {"currencyCode" => "CAD", "amount" => "1", "rate" => "17.6"}
    ]

    with_stub(ExchangeRateCacheService, :fetch_fresh_daily_rates, daily) do
      with_stub(ExchangeRateCacheService, :fetch_fresh_monthly_rates, monthly) do
        rates = ExchangeRateCacheService.refresh_rates
        # Should contain two unique currency codes
        assert_equal 2, rates.size
        codes = rates.map { |r| r["currencyCode"] }.sort
        assert_equal ["BGN", "CAD"], codes
      end
    end
  end

  test "cache expires after RATE_CACHE_DURATION and get_rates refreshes" do
    first_daily = [{"currencyCode" => "CAD", "amount" => "1", "rate" => "17.5", "validFor" => "2025-12-01"}]
    first_monthly = []

    second_daily = [
      {"currencyCode" => "CAD", "amount" => "1", "rate" => "18.0", "validFor" => "2025-12-02"},
      {"currencyCode" => "EUR", "amount" => "1", "rate" => "24.0", "validFor" => "2025-12-02"}
    ]
    second_monthly = []

    # Initial population
    with_stub(ExchangeRateCacheService, :fetch_fresh_daily_rates, first_daily) do
      with_stub(ExchangeRateCacheService, :fetch_fresh_monthly_rates, first_monthly) do
        initial = ExchangeRateCacheService.get_rates
        assert_equal 1, initial.size
        assert_equal "17.5", initial.first["rate"]
      end
    end

    # Advance time past the cache TTL and provide new stubbed responses
    travel_to(Time.now + ExchangeRateCacheService::RATE_CACHE_DURATION + 1.second) do
      # Cache should have expired by now
      cached_before = Rails.cache.read(ExchangeRateCacheService::CACHE_KEY)
      assert_nil cached_before, "Expected cache to be empty after TTL expires"

      with_stub(ExchangeRateCacheService, :fetch_fresh_daily_rates, second_daily) do
        with_stub(ExchangeRateCacheService, :fetch_fresh_monthly_rates, second_monthly) do
          refreshed = ExchangeRateCacheService.get_rates
          # Now we expect the refreshed result to have two entries (different size)
          assert_equal 2, refreshed.size
          codes = refreshed.map { |r| r["currencyCode"] }.sort
          assert_equal ["CAD", "EUR"], codes

          # And cache should now contain the refreshed set
          cached_after = Rails.cache.read(ExchangeRateCacheService::CACHE_KEY)
          assert_not_nil cached_after
          assert_equal 2, cached_after.size
        end
      end
    end
  end
end
