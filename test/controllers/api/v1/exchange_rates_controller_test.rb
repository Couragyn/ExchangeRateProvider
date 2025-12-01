require "test_helper"

module Api
  module V1
    class ExchangeRatesControllerTest < ActionDispatch::IntegrationTest
      # use shared with_stub helper from test_helper.rb

      test "returns rate when found" do
        rates = [{"currencyCode" => "CAD", "amount" => "1", "rate" => "17.5", "validFor" => "2025-12-01"}]

        with_stub(ExchangeRateCacheService, :get_rates, rates) do
          get api_v1_exchange_rates_path, params: { currency_code: "CAD" }
          assert_response :success
          body = JSON.parse(response.body)
          assert_equal 1.0, body["amount"]
          assert_equal 17.5, body["rate"]
          assert_includes body["rate_string"], "exchanges to"
        end
      end

      test "returns 400 when invalid currency_code" do
        get api_v1_exchange_rates_path, params: { currency_code: "CA" }
        assert_response :bad_request
        body = JSON.parse(response.body)
        assert_match /currency_code must be 3 letters/, body["error"]
      end

      test "returns 400 when no currency_code" do
        get api_v1_exchange_rates_path, params: { currency_code: "" }
        assert_response :bad_request
        body = JSON.parse(response.body)
        assert_match /currency_code must be 3 letters/, body["error"]
      end

      test "returns 404 when rate not found" do
        with_stub(ExchangeRateCacheService, :get_rates, []) do
          get api_v1_exchange_rates_path, params: { currency_code: "XXX" }
          assert_response :not_found
          body = JSON.parse(response.body)
          assert_match /exchange rate not found/, body["error"]
        end
      end
    end
  end
end
