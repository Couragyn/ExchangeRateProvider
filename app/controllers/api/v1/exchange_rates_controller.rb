module Api
  module V1
    class ExchangeRatesController < ApplicationController
      # GET /api/v1/exchange_rates?currency_code=CAD
      def get_rate
        currency_code = params[:currency_code]&.upcase

        # Validate input
        if currency_code.blank? || currency_code.length != 3
          return render json: { error: "currency_code must be 3 letters" }, status: :bad_request
        end

        rate_data = find_rate(currency_code)

        if rate_data
          render json: format_response(rate_data), status: :ok
        else
          render json: { error: "exchange rate not found" }, status: :not_found
        end
      end

      private

      def find_rate(currency_code)
        rates = ExchangeRateCacheService.get_rates
        rates.find { |r| r["currencyCode"] == currency_code }
      end

      def format_response(rate_data)
        amount = rate_data["amount"].to_f
        rate = rate_data["rate"].to_f
        currencyCode = rate_data["currencyCode"]
        valid_for = rate_data["validFor"]

        rate_string = "#{amount} #{currencyCode} exchanges to #{rate} CZK, set on #{valid_for} by CNB"

        {
          amount: amount,
          rate: rate,
          valid_for: valid_for,
          rate_string: rate_string
        }
      end
    end
  end
end
