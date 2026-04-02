module Taxerase
  module CountryCalculators
    class BaseDefinition
      COMPARISON_PROFILES = [
        {
          key: "employee",
          uses_deductible_expenses: false
        },
        {
          key: "self_employed",
          uses_deductible_expenses: true
        }
      ].freeze

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
          input_currency_options: input_currency_options,
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
          input_currency_options: input_currency_options,
          tax_year_options: calculation_router.public_tax_year_options,
          comparison_profiles: public_comparison_profiles,
          regime_options: calculation_router.public_regime_options.map do |regime|
            regime.slice(:key, :name, :region, :category, :tax_year)
          end
        }
      end

      def comparison_profiles
        COMPARISON_PROFILES
      end

      def input_currency_options
        [
          {
            code: country.fetch(:currency_code),
            name: country.fetch(:currency_code)
          }
        ]
      end

      def public_comparison_profiles
        supported_categories = calculation_router.public_regime_options.map { |regime| regime[:category] }.uniq

        comparison_profiles.select do |profile|
          supported_categories.include?(profile.fetch(:key))
        end
      end

      def comparison_profile(profile_key)
        public_comparison_profiles.find { |profile| profile.fetch(:key) == profile_key.to_s }
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

      def comparison_call_overrides(profile_key: nil, input: nil)
        profile_key
        input
        {}
      end

      def normalize_comparison_age_bracket(age_bracket)
        age_bracket
      end
    end
  end
end
