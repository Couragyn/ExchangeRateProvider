# app/jobs/refresh_exchange_rates_job.rb
class RefreshExchangeRatesJob < ApplicationJob
  queue_as :default
  CEST_ZONE = "Europe/Prague"

  # Retry 3 times if rate update fails
  retry_on StandardError, wait: 5.minutes, attempts: 3

  def perform
    now = Time.current.in_time_zone(CEST_ZONE)
    
    refresh_all_rates
    Rails.logger.info "Successfully refreshed exchange rates at #{now}"
  rescue => e
    Rails.logger.error "Failed to refresh exchange rates at #{e.message}"
  end

  private

  def refresh_all_rates
    ExchangeRateCacheService.refresh_daily_rates
    ExchangeRateCacheService.refresh_monthly_rates
  end
end