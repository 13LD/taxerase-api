module Taxerase
  module CountryCalculators
    class BaseDefinition
      def page_title
        "Taxerase | #{country.fetch(:name)} Tax Calculator"
      end

      def build_props
        tax_year_options = calculation_router.public_tax_year_options
        default_tax_year = tax_year_options.last || default_input.fetch(:tax_year)
        default_tax_regime_key = calculation_router.default_regime_key(default_tax_year)

        raise ArgumentError, "No public tax regimes are configured for #{country.fetch(:name)}." if default_tax_regime_key.blank?

        resolved_default_input = default_input.merge(tax_year: default_tax_year)

        {
          country: country,
          tax_year_options: tax_year_options,
          default_tax_regime_key: default_tax_regime_key,
          regime_options: calculation_router.public_regime_options,
          default_input: resolved_default_input,
          initial_result: calculation_router.call(**resolved_default_input, tax_regime_key: default_tax_regime_key)
        }
      end
    end
  end
end
