module Taxerase
  module CountryCalculators
    class CzechRepublicDefinition < BaseDefinition
      def country
        {
          code: "CZ",
          name: "Czech Republic",
          currency_code: "CZK"
        }
      end

      def calculation_router
        Taxerase::CzechRepublic::CalculationRouter
      end

      def default_input
        {
          gross_income: 600_000,
          input_currency_code: "CZK",
          salary_period: "YEAR",
          tax_year: 2025,
          deductible_expenses: 0,
          expense_deduction_method: "flat_expense_60",
          age_bracket: "standard",
          children_count: 0,
          children_under_three_count: 0,
          disability_level: "none"
        }
      end

      def input_currency_options
        [
          { code: "CZK", name: "CZK" },
          { code: "EUR", name: "EUR" }
        ]
      end

      def normalize_comparison_age_bracket(_age_bracket)
        default_input.fetch(:age_bracket)
      end

      def comparison_call_overrides(profile_key:, input:)
        return {} unless profile_key.to_s == "self_employed"

        {
          expense_deduction_method: "flat_expense_60"
        }
      end
    end
  end
end
