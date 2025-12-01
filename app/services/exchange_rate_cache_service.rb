class ExchangeRateCacheService
  RATE_CACHE_DURATION = 24.hours
  CACHE_KEY = "cnb_exchange_rates"

  class << self
    def get_rates
      Rails.cache.fetch(CACHE_KEY, expires_in: RATE_CACHE_DURATION) do
        refresh_rates
      end
    end

    def refresh_rates
      daily_rates = fetch_fresh_daily_rates
      monthly_rates = fetch_fresh_monthly_rates
      rates = (daily_rates + monthly_rates).uniq { |r| r["currencyCode"] }

      Rails.cache.write(CACHE_KEY, rates, expires_in: RATE_CACHE_DURATION)
      rates
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
