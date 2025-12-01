class CnbExchangeRateService
  include HTTParty
  base_uri 'https://api.cnb.cz/cnbapi'

  default_timeout 10
  format :json

  # Get current exchange rates of commonly traded currencies (updated daily)
  def self.get_daily_rates(lang = 'EN')
    response = get("/exrates/daily?lang=#{lang}")
    parsed_response = handle_response(response)
    if (response.code == 200 && parsed_response["rates"].empty?)
      # Data from yesterday if today's isn't available yet
      yesterday = (Date.today - 1).strftime("%Y-%m-%d")
      response = get("/exrates/daily?lang=#{lang}&date=#{yesterday}")
      parsed_response = handle_response(response)
    end
    parsed_response["rates"]
  end

  # Get current exchange rates of less-commonly traded currencies (updated monthly)
  def self.get_monthly_rates(lang = 'EN')
    response = get("/fxrates/daily-month?lang=#{lang}")
    parsed_response = handle_response(response)
    if (response.code == 200 && parsed_response["rates"].empty?)
      # Data from last month if this months isn't available yet
      last_month = (Date.today << 1).strftime("%Y-%m")
      response = get("/fxrates/daily-month?lang=#{lang}&yearMonth=#{last_month}")
      parsed_response = handle_response(response)
    end
    parsed_response["rates"]
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