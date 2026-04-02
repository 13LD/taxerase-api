module Taxerase
  module Comparisons
    class EcbReferenceRateConverter
      ECB_REFERENCE_DATE = Date.new(2026, 3, 11).freeze
      ECB_SOURCE_URL = "https://data.ecb.europa.eu/data/concepts/bilateral-exchange-rates?tags_array%5B0%5D=Bilateral+exchange+rates".freeze

      ECB_REFERENCE_RATES = {
        "EUR" => BigDecimal("1"),
        "PLN" => BigDecimal("4.2523"),
        "CZK" => BigDecimal("24.377")
      }.freeze

      def convert_from_eur(amount, currency_code)
        convert(amount, from_currency_code: "EUR", to_currency_code: currency_code)
      end

      def convert_to_eur(amount, currency_code)
        convert(amount, from_currency_code: currency_code, to_currency_code: "EUR")
      end

      def convert(amount, from_currency_code:, to_currency_code:)
        normalized_amount = BigDecimal(amount.to_s)
        return round_currency(normalized_amount) if from_currency_code == to_currency_code

        amount_in_eur = normalized_amount / rate_for(from_currency_code)
        converted_amount = amount_in_eur * rate_for(to_currency_code)

        round_currency(converted_amount)
      end

      def reference_metadata
        {
          base_currency_code: "EUR",
          provider: "ECB",
          rate_date: ECB_REFERENCE_DATE.iso8601,
          source_name: "ECB euro foreign exchange reference rates",
          source_url: ECB_SOURCE_URL,
          reference_rates: ECB_REFERENCE_RATES.except("EUR").transform_values { |rate| round_currency(rate) }
        }
      end

      private

      def rate_for(currency_code)
        ECB_REFERENCE_RATES.fetch(currency_code.to_s.upcase)
      rescue KeyError
        raise KeyError, "No ECB reference rate is configured for #{currency_code.inspect}."
      end

      def round_currency(amount)
        amount.round(2).to_f
      end
    end
  end
end
