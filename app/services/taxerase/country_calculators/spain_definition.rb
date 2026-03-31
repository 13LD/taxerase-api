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
    end
  end
end
