require "net/http"
require "uri"
require "json"

module Taxerase
  module ExchangeRates
    class FrankfurterClient
      class Error < StandardError; end

      API_URL = "https://api.frankfurter.dev/v2/rates".freeze

      def fetch_latest(base_currency_code:, quote_currency_codes:, providers: nil)
        uri = URI(API_URL)
        query = {
          base: base_currency_code.to_s.upcase,
          quotes: Array(quote_currency_codes).map(&:upcase).join(",")
        }
        query[:providers] = providers if providers.present?
        uri.query = URI.encode_www_form(query)

        response = Net::HTTP.get_response(uri)
        raise Error, "Frankfurter request failed with HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        parse_payload(JSON.parse(response.body), source_url: uri.to_s)
      rescue JSON::ParserError => error
        raise Error, "Frankfurter response could not be parsed: #{error.message}"
      end

      private

      def parse_payload(payload, source_url:)
        rows = if payload.is_a?(Array)
          payload
        elsif payload.is_a?(Hash) && payload["rates"].is_a?(Hash)
          payload.fetch("rates").map do |quote_currency_code, rate_value|
            {
              "base" => payload.fetch("base"),
              "quote" => quote_currency_code,
              "date" => payload.fetch("date"),
              "rate" => rate_value
            }
          end
        else
          raise Error, "Frankfurter response shape is unsupported."
        end

        rows.map do |row|
          {
            base_currency_code: row.fetch("base").to_s.upcase,
            quote_currency_code: row.fetch("quote").to_s.upcase,
            rate_date: Date.iso8601(row.fetch("date").to_s),
            rate_value: BigDecimal(row.fetch("rate").to_s),
            source_url: source_url
          }
        end
      end
    end
  end
end
