class CnbExchangeRateService
  include HTTParty
  base_uri "https://api.cnb.cz/cnbapi"

  default_timeout 10
  format :json

  # Get current exchange rates of commonly traded currencies (updated daily). If the default NOW time does not return results, try getting data from yesterday. If that doesn't work it will return an empty set. Testing has shown that data is usually available day of and the previous day. If the data is empty for both then it's better not to have an exchange rate than stale data. Possible considerations for production would be to try a different API as a fallback.
  def self.get_daily_rates
    parsed_response = self.fetch_daily_rates("EN", nil)
    if parsed_response["rates"].empty?
      # Data from yesterday if today's isn't available yet
      yesterday = (Date.today - 1).strftime("%Y-%m-%d")
      parsed_response = fetch_daily_rates("EN", yesterday)
    end
    parsed_response["rates"]
  end

  # Get current exchange rates of less-commonly traded currencies (updated monthly). If the default NOW time does not return results, try getting data from last month. If that doesn't work it will return an empty set. Testing has shown that this months data is not usually available until the end of the month, but is for the previous month. If the data is empty for both then it's better not to have an exchange rate than stale data. Possible considerations for production would be to try a different API as a fallback.
  def self.get_daily_rates
  def self.get_monthly_rates(lang = "EN")
    parsed_response = self.fetch_monthly_rates("EN", nil)
    if parsed_response["rates"].empty?
      # Data from last month if this months isn't available yet
      last_month = (Date.today << 1).strftime("%Y-%m")
      parsed_response = fetch_monthly_rates("EN", last_month)
    end
    parsed_response["rates"]
  end

  def self.fetch_daily_rates(lang = "EN", date = nil)
    if date.present?
      response = get("/exrates/daily?lang=#{lang}&date=#{date}")
    else
      response = get("/exrates/daily?lang=#{lang}")
    end
    handle_response(response)
  end

  def self.fetch_monthly_rates(lang = "EN", month = nil)
    if month.present?
      response = get("/fxrates/daily-month?lang=#{lang}&yearMonth=#{month}")
    else
      response = get("/fxrates/daily-month?lang=#{lang}")
    end
    handle_response(response)
  end

  private

  def self.handle_response(response)
    case response.code
    when 200
      response.parsed_response
    when 400
      raise "400 Bad Request: Invalid parameters provided"
    when 404
      raise "404 Not Found: The requested resource was not found"
    when 500
      raise "500 Internal Server Error: API is experiencing issues"
    else
      raise "#{response.code} Error: #{response.message}"
    end
  rescue Net::OpenTimeout, SocketError => e
    raise "Connection failed: #{e.message}"
  end
end
