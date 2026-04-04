module Taxerase
  module Comparisons
    class ReferenceRateConverter
      PROVIDER = Taxerase::ExchangeRates::SyncRates::PROVIDER
      PROVIDER_LABEL = Taxerase::ExchangeRates::SyncRates::PROVIDER_LABEL
      BASE_CURRENCY_CODE = Taxerase::ExchangeRates::SyncRates::BASE_CURRENCY_CODE

      def initialize(rate_date: nil)
        @rate_date = rate_date&.to_date
      end

      def convert_from_eur(amount, currency_code)
        convert(amount, from_currency_code: BASE_CURRENCY_CODE, to_currency_code: currency_code)
      end

      def convert_to_eur(amount, currency_code)
        convert(amount, from_currency_code: currency_code, to_currency_code: BASE_CURRENCY_CODE)
      end

      def convert(amount, from_currency_code:, to_currency_code:)
        normalized_amount = BigDecimal(amount.to_s)
        return round_currency(normalized_amount) if from_currency_code.to_s.upcase == to_currency_code.to_s.upcase

        amount_in_eur = normalized_amount / rate_for(from_currency_code)
        converted_amount = amount_in_eur * rate_for(to_currency_code)

        round_currency(converted_amount)
      end

      def reference_metadata
        {
          base_currency_code: BASE_CURRENCY_CODE,
          provider: PROVIDER_LABEL,
          rate_date: effective_rate_date.iso8601,
          source_name: snapshot_rates.first.source_name,
          source_url: snapshot_rates.first.source_url,
          reference_rates: snapshot_rates.index_by(&:quote_currency_code).transform_values do |exchange_rate|
            round_currency(exchange_rate.rate_value)
          end
        }
      end

      private

      attr_reader :rate_date

      def effective_rate_date
        @effective_rate_date ||= begin
          rate_date || ExchangeRate.latest_rate_date_for!(
            provider: PROVIDER,
            base_currency_code: BASE_CURRENCY_CODE
          )
        rescue KeyError
          bootstrap_seed_rates!
          rate_date || ExchangeRate.latest_rate_date_for!(
            provider: PROVIDER,
            base_currency_code: BASE_CURRENCY_CODE
          )
        end
      end

      def snapshot_rates
        @snapshot_rates ||= ExchangeRate.for_provider(PROVIDER)
          .for_base(BASE_CURRENCY_CODE)
          .on_date(effective_rate_date)
          .order(:quote_currency_code)
          .to_a
      end

      def rate_for(currency_code)
        normalized_code = currency_code.to_s.upcase
        return BigDecimal("1") if normalized_code == BASE_CURRENCY_CODE

        ExchangeRate.latest_for!(
          provider: PROVIDER,
          base_currency_code: BASE_CURRENCY_CODE,
          quote_currency_code: normalized_code,
          rate_date: effective_rate_date
        ).rate_value.to_d
      rescue KeyError
        bootstrap_seed_rates!
        ExchangeRate.latest_for!(
          provider: PROVIDER,
          base_currency_code: BASE_CURRENCY_CODE,
          quote_currency_code: normalized_code,
          rate_date: effective_rate_date
        ).rate_value.to_d
      end

      def round_currency(amount)
        amount.round(2).to_f
      end

      def bootstrap_seed_rates!
        return if @bootstrap_seed_attempted

        @bootstrap_seed_attempted = true
        Taxerase::Seeds::ExchangeRates.call
        @effective_rate_date = nil
        @snapshot_rates = nil
      end
    end

    EcbReferenceRateConverter = ReferenceRateConverter
  end
end
