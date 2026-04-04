module Taxerase
  module ExchangeRates
    class SyncRates
      PROVIDER = "FRANKFURTER".freeze
      PROVIDER_LABEL = "Frankfurter".freeze
      SOURCE_NAME = "Frankfurter exchange rates API".freeze
      BASE_CURRENCY_CODE = "EUR".freeze
      QUOTE_CURRENCY_CODES = %w[GBP CHF NOK SEK DKK PLN CZK HUF RON ISK].freeze

      def self.call(client: FrankfurterClient.new, fetched_at: Time.current)
        rows = client.fetch_latest(
          base_currency_code: BASE_CURRENCY_CODE,
          quote_currency_codes: QUOTE_CURRENCY_CODES
        )

        ExchangeRate.transaction do
          rows.each do |row|
            ExchangeRate.upsert(
              {
                base_currency_code: row.fetch(:base_currency_code),
                quote_currency_code: row.fetch(:quote_currency_code),
                rate_date: row.fetch(:rate_date),
                rate_value: row.fetch(:rate_value),
                provider: PROVIDER,
                source_name: SOURCE_NAME,
                source_url: row.fetch(:source_url),
                fetched_at: fetched_at,
                updated_at: fetched_at,
                created_at: fetched_at
              },
              unique_by: :idx_exchange_rates_provider_pair_date
            )
          end
        end
      end
    end
  end
end
