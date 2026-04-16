module Taxerase
  module Support
    module RegimeBackedCalculation
      private

      def find_regime(category:, tax_year:, country:, scope: :with_rule_data)
        TaxRegime
          .public_send(scope)
          .for_country_year(country:, tax_year:)
          .find_by(key: tax_regime_key, category:)
      end

      def build_regime_metadata(calculator_version:)
        {
          country_code: regime.country.code,
          country_name: regime.country.name,
          region: regime.region,
          tax_year: regime.tax_year,
          tax_regime_key: regime.key,
          tax_regime_name: regime.name,
          calculator_version:
        }
      end
    end
  end
end
