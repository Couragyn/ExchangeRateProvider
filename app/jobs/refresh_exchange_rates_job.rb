# app/jobs/refresh_exchange_rates_job.rb
class RefreshExchangeRatesJob < ApplicationJob
  # Retry 3 times if rate update fails
  retry_on StandardError, wait: 5.minutes, attempts: 3

  def perform   
    ExchangeRateCacheService.refresh_rates
    Rails.logger.info "Successfully refreshed exchange rates at #{Time.current}"
  rescue => e
    Rails.logger.error "Failed to refresh exchange rates - #{e.message}"
  end
end