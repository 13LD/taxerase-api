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
          country_options: Registry.country_options,
          comparison_catalog: Registry.comparison_catalog,
          tax_year_options: tax_year_options,
          default_tax_regime_key: default_tax_regime_key,
          regime_options: calculation_router.public_regime_options,
          default_input: resolved_default_input,
          initial_result: calculation_router.call(**resolved_default_input, tax_regime_key: default_tax_regime_key)
        }
      end

      def public_catalog
        {
          country: country,
          tax_year_options: calculation_router.public_tax_year_options,
          regime_options: calculation_router.public_regime_options.map do |regime|
            regime.slice(:key, :name, :region, :category, :tax_year)
          end
        }
      end

      def normalize_comparison_input(input)
        comparison_defaults = default_input

        {
          age_bracket: normalize_comparison_age_bracket(
            input[:age_bracket].presence || comparison_defaults[:age_bracket]
          ),
          children_count: input[:children_count].presence || comparison_defaults[:children_count] || 0,
          children_under_three_count: input[:children_under_three_count].presence || comparison_defaults[:children_under_three_count] || 0,
          disability_level: input[:disability_level].presence || comparison_defaults[:disability_level] || "none"
        }
      end

      def normalize_comparison_age_bracket(age_bracket)
        age_bracket
      end
    end
  end
end
