module Taxerase
  module CountryCalculators
    class NetherlandsDefinition < BaseDefinition
      def country
        {
          code: "NL",
          name: "Netherlands"
        }
      end

      def calculation_router
        Taxerase::Netherlands::CalculationRouter
      end

      def default_input
        {
          gross_income: 60_000,
          salary_period: "YEAR",
          tax_year: 2025,
          deductible_expenses: 0,
          age_bracket: "under_aow_age",
          apply_thirty_percent_ruling: false,
          thirty_percent_ruling_basis: "standard_threshold",
          children_count: 0,
          children_under_three_count: 0,
          disability_level: "none"
        }
      end

      def normalize_comparison_age_bracket(age_bracket)
        case age_bracket
        when "under_65"
          "under_aow_age"
        when "from_65_to_74", "age_75_plus"
          "aow_age_or_older"
        else
          age_bracket
        end
      end
    end
  end
end
