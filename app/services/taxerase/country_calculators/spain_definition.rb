module Taxerase
  module CountryCalculators
    class SpainDefinition < BaseDefinition
      def country
        {
          code: "ES",
          name: "Spain"
        }
      end

      def calculation_router
        Taxerase::Spain::CalculationRouter
      end

      def default_input
        {
          gross_income: 60_000,
          salary_period: "YEAR",
          tax_year: 2025,
          deductible_expenses: 0,
          age_bracket: "under_65",
          children_count: 0,
          children_under_three_count: 0,
          disability_level: "none"
        }
      end

      def normalize_comparison_age_bracket(age_bracket)
        case age_bracket
        when "under_aow_age"
          "under_65"
        when "aow_age_or_older"
          "from_65_to_74"
        else
          age_bracket
        end
      end
    end
  end
end
