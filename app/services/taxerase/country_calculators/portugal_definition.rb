module Taxerase
  module CountryCalculators
    class PortugalDefinition < BaseDefinition
      def country
        {
          code: "PT",
          name: "Portugal",
          currency_code: "EUR"
        }
      end

      def calculation_router
        Taxerase::Portugal::CalculationRouter
      end

      def default_input
        {
          gross_income: 60_000,
          input_currency_code: "EUR",
          salary_period: "YEAR",
          tax_year: 2026,
          deductible_expenses: 0,
          business_activity_type: "professional_services",
          age_bracket: "standard",
          children_count: 0,
          children_under_three_count: 0,
          disability_level: "none",
          ascendants_count: 0,
          general_family_expenses: 0,
          health_expenses: 0,
          education_expenses: 0,
          housing_rent: 0,
          alimony_paid: 0,
          care_home_expenses: 0,
          domestic_work_expenses: 0
        }
      end
    end
  end
end
