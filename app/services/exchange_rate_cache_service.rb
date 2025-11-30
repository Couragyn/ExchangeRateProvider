class ExchangeRateCacheService
  RATE_CACHE_DURATION = 24.hours
  CEST_ZONE = "Europe/Prague"

  class << self
    def get_daily_rates
      cache_key = "cnb_daily_rates"
      
      Rails.cache.fetch(cache_key, expires_in: RATE_CACHE_DURATION) do
        fetch_fresh_daily_rates
      end
    end

    def get_monthly_rates
      cache_key = "cnb_monthly_rates"
      
      Rails.cache.fetch(cache_key, expires_in: RATE_CACHE_DURATION) do
        fetch_fresh_monthly_rates
      end
    end

    # Refresh methods that actively update cache with fresh data
    def refresh_daily_rates
      cache_key = "cnb_daily_rates"
      rates = fetch_fresh_daily_rates
      Rails.cache.write(cache_key, rates, expires_in: RATE_CACHE_DURATION)
      rates
    end

    def refresh_monthly_rates
      cache_key = "cnb_monthly_rates"
      rates = fetch_fresh_monthly_rates
      Rails.cache.write(cache_key, rates, expires_in: RATE_CACHE_DURATION)
      rates
    end

    def refresh_all_rates
      {
        daily: refresh_daily_rates,
        monthly: refresh_monthly_rates
      }
    end

    private

    def fetch_fresh_daily_rates
      CnbExchangeRateService.get_daily_rates
    rescue => e
      Rails.logger.error "Failed to fetch daily rates: #{e.message}"
      raise
    end

    def fetch_fresh_monthly_rates
      CnbExchangeRateService.get_monthly_rates
    rescue => e
      Rails.logger.error "Failed to fetch monthly rates: #{e.message}"
      raise
    end
  end
end