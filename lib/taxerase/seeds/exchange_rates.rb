module Taxerase
  module Seeds
    class ExchangeRates
      PROVIDER = "FRANKFURTER".freeze
      SOURCE_NAME = "Frankfurter exchange rates API".freeze
      SOURCE_URL = "https://api.frankfurter.dev/v2/rates?base=EUR&quotes=PLN,CZK".freeze
      RATE_DATE = Date.new(2026, 3, 11).freeze
      BASE_CURRENCY_CODE = "EUR".freeze
      REFERENCE_RATES = {
        "PLN" => BigDecimal("4.2523"),
        "CZK" => BigDecimal("24.377")
      }.freeze

      def self.call
        timestamp = Time.current

        REFERENCE_RATES.each do |quote_currency_code, rate_value|
          ExchangeRate.upsert(
            {
              base_currency_code: BASE_CURRENCY_CODE,
              quote_currency_code: quote_currency_code,
              rate_date: RATE_DATE,
              rate_value: rate_value,
              provider: PROVIDER,
              source_name: SOURCE_NAME,
              source_url: SOURCE_URL,
              fetched_at: timestamp,
              created_at: timestamp,
              updated_at: timestamp
            },
            unique_by: :idx_exchange_rates_provider_pair_date
          )
        end
      end
    end
  end
end
