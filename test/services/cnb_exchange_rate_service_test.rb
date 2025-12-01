require "test_helper"

class CnbExchangeRateServiceTest < ActiveSupport::TestCase
  include WebMock::API

  def setup
    WebMock.enable!
  end

  def teardown
    WebMock.reset!
    WebMock.disable!
  end

  test "get_daily_rates returns parsed rates on 200" do
    body = { "rates" => [{ "currencyCode" => "USD", "amount" => "1", "rate" => "22.0", "validFor" => "2025-12-01" }] }
    stub_request(:get, %r{api.cnb.cz/cnbapi/exrates/daily}).to_return(status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json' })

    rates = CnbExchangeRateService.get_daily_rates
    assert_equal 1, rates.size
    assert_equal "USD", rates.first["currencyCode"]
  end

  test "get_daily_rates falls back to yesterday if empty rates" do
    empty_body = { "rates" => [] }
    yesterday_body = { "rates" => [{ "currencyCode" => "EUR", "amount" => "1", "rate" => "24.0", "validFor" => "2025-11-30" }] }

    # First call returns 200 with empty rates
    stub_request(:get, %r{api.cnb.cz/cnbapi/exrates/daily\?lang=EN$}).to_return(status: 200, body: empty_body.to_json, headers: { 'Content-Type' => 'application/json' })
    # Fallback call with date param (order of query params may vary)
    stub_request(:get, %r{api.cnb.cz/cnbapi/exrates/daily.*date=}).to_return(status: 200, body: yesterday_body.to_json, headers: { 'Content-Type' => 'application/json' })

    rates = CnbExchangeRateService.get_daily_rates
    assert_equal 1, rates.size
    assert_equal "EUR", rates.first["currencyCode"]
  end

  test "handle_response raises for 500" do
    stub_request(:get, %r{api.cnb.cz/cnbapi/exrates/daily}).to_return(status: 500, body: "")

    assert_raises RuntimeError do
      CnbExchangeRateService.get_daily_rates
    end
  end

  test "get_monthly_rates returns parsed rates and falls back to last month" do
    body = { "rates" => [{ "currencyCode" => "AUD", "amount" => "1", "rate" => "15.0", "validFor" => "2025-12" }] }
    stub_request(:get, %r{api.cnb.cz/cnbapi/fxrates/daily-month}).to_return(status: 200, body: body.to_json, headers: { 'Content-Type' => 'application/json' })

    rates = CnbExchangeRateService.get_monthly_rates
    assert_equal 1, rates.size
    assert_equal "AUD", rates.first["currencyCode"]

    # Test fallback when empty
    empty = { "rates" => [] }
    last_month_body = { "rates" => [{ "currencyCode" => "NOK", "amount" => "1", "rate" => "2.5", "validFor" => "2025-11" }] }
    stub_request(:get, %r{api.cnb.cz/cnbapi/fxrates/daily-month\?lang=EN$}).to_return(status: 200, body: empty.to_json, headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, %r{api.cnb.cz/cnbapi/fxrates/daily-month.*yearMonth=}).to_return(status: 200, body: last_month_body.to_json, headers: { 'Content-Type' => 'application/json' })

    rates = CnbExchangeRateService.get_monthly_rates
    assert_equal 1, rates.size
    assert_equal "NOK", rates.first["currencyCode"]
  end

  test "fetch_daily_rates and fetch_monthly_rates accept params and return parsed responses" do
    # Without date / month
    daily_body = { "rates" => [{ "currencyCode" => "CHF", "amount" => "1", "rate" => "25.0", "validFor" => "2025-12-01" }] }
    stub_request(:get, "https://api.cnb.cz/cnbapi/exrates/daily?lang=EN").to_return(status: 200, body: daily_body.to_json, headers: { 'Content-Type' => 'application/json' })

    parsed = CnbExchangeRateService.fetch_daily_rates('EN', nil)
    assert_equal "CHF", parsed["rates"].first["currencyCode"]

    # With explicit date
    date = "2025-11-30"
    daily_date_body = { "rates" => [{ "currencyCode" => "SEK", "amount" => "1", "rate" => "2.1", "validFor" => date }] }
    stub_request(:get, "https://api.cnb.cz/cnbapi/exrates/daily?lang=EN&date=#{date}").to_return(status: 200, body: daily_date_body.to_json, headers: { 'Content-Type' => 'application/json' })

    parsed_date = CnbExchangeRateService.fetch_daily_rates('EN', date)
    assert_equal "SEK", parsed_date["rates"].first["currencyCode"]

    # Monthly without month
    monthly_body = { "rates" => [{ "currencyCode" => "HKD", "amount" => "1", "rate" => "2.8", "validFor" => "2025-12" }] }
    stub_request(:get, "https://api.cnb.cz/cnbapi/fxrates/daily-month?lang=EN").to_return(status: 200, body: monthly_body.to_json, headers: { 'Content-Type' => 'application/json' })

    parsed_monthly = CnbExchangeRateService.fetch_monthly_rates('EN', nil)
    assert_equal "HKD", parsed_monthly["rates"].first["currencyCode"]

    # Monthly with yearMonth
    ym = "2025-11"
    monthly_ym_body = { "rates" => [{ "currencyCode" => "SGD", "amount" => "1", "rate" => "16.0", "validFor" => ym }] }
    stub_request(:get, "https://api.cnb.cz/cnbapi/fxrates/daily-month?lang=EN&yearMonth=#{ym}").to_return(status: 200, body: monthly_ym_body.to_json, headers: { 'Content-Type' => 'application/json' })

    parsed_month = CnbExchangeRateService.fetch_monthly_rates('EN', ym)
    assert_equal "SGD", parsed_month["rates"].first["currencyCode"]
  end

  test "fetch_daily_rates raises descriptive errors for 400 and 404" do
    # 400 Bad Request
    stub_request(:get, "https://api.cnb.cz/cnbapi/exrates/daily?lang=EN").to_return(status: 400, body: "")
    err = assert_raises RuntimeError do
      CnbExchangeRateService.fetch_daily_rates('EN', nil)
    end
    assert_match /400 Bad Request/, err.message

    # 404 Not Found
    stub_request(:get, "https://api.cnb.cz/cnbapi/exrates/daily?lang=EN").to_return(status: 404, body: "")
    err2 = assert_raises RuntimeError do
      CnbExchangeRateService.fetch_daily_rates('EN', nil)
    end
    assert_match /404 Not Found/, err2.message
  end

  test "fetch_monthly_rates raises descriptive errors for 400 and 404" do
    # 400 Bad Request
    stub_request(:get, "https://api.cnb.cz/cnbapi/fxrates/daily-month?lang=EN").to_return(status: 400, body: "")
    err = assert_raises RuntimeError do
      CnbExchangeRateService.fetch_monthly_rates('EN', nil)
    end
    assert_match /400 Bad Request/, err.message

    # 404 Not Found
    stub_request(:get, "https://api.cnb.cz/cnbapi/fxrates/daily-month?lang=EN").to_return(status: 404, body: "")
    err2 = assert_raises RuntimeError do
      CnbExchangeRateService.fetch_monthly_rates('EN', nil)
    end
    assert_match /404 Not Found/, err2.message
  end
end
