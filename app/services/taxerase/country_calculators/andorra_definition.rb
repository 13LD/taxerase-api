module Taxerase
  module CountryCalculators
    class AndorraDefinition < BaseDefinition
      def country
        {
          code: "AD",
          name: "Andorra",
          currency_code: "EUR"
        }
      end

      def calculation_router
        Taxerase::Andorra::CalculationRouter
      end

      def default_input
        {
          gross_income: 60_000,
          input_currency_code: "EUR",
          salary_period: "YEAR",
          tax_year: 2026,
          deductible_expenses: 0,
          age_bracket: "standard",
          children_count: 0,
          children_under_three_count: 0,
          disability_level: "none",
          ascendants_count: 0,
          spouse_without_income: false,
          mortgage_interest: 0,
          pension_contributions: 0,
          alimony_paid: 0
        }
      end

      def normalize_comparison_age_bracket(_age_bracket)
        "standard"
      end

      def comparison_call_overrides(profile_key:, input:)
        profile_key
        input
        {
          ascendants_count: 0,
          spouse_without_income: false,
          mortgage_interest: 0,
          pension_contributions: 0,
          alimony_paid: 0
        }
      end
    end
  end
end
