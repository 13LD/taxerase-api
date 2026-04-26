module Taxerase
  module CountryCalculators
    class PolandDefinition < BaseDefinition
      def country
        {
          code: "PL",
          name: "Poland",
          currency_code: "PLN"
        }
      end

      def calculation_router
        Taxerase::Poland::CalculationRouter
      end

      def default_input
        {
          gross_income: 180_000,
          input_currency_code: "PLN",
          salary_period: "YEAR",
          tax_year: 2026,
          deductible_expenses: 0,
          age_bracket: "age_26_to_retirement",
          revenue_cost_mode: "normal",
          monthly_tax_relief_mode: "full",
          ppk_employee_rate: 0,
          ppk_employer_rate: 0,
          employer_accident_rate: 1.67,
          include_labor_fund: true,
          include_fgsp: true,
          b2b_tax_form: "tax_scale",
          lump_sum_rate: 12,
          social_insurance_mode: "standard",
          include_sickness_contribution: true,
          business_days_in_month: 30,
          previous_year_average_monthly_income: 12_000,
          lump_sum_activity_type: "it_services",
          cooperating_person: false,
          months_since_business_start: 37,
          apply_return_relief: false,
          return_relief_prior_non_resident: false,
          return_relief_year: 1,
          apply_family_4plus_relief: false,
          apply_working_senior_relief: false,
          working_senior_receives_pension: false,
          birth_year: 2000,
          young_worker_relief_income_type: "employment",
          filing_status: "individual",
          spouse_income: 0,
          child_relief_household_status: "single",
          child_relief_household_income: "",
          child_relief_claim_share: 100,
          children_count: 0,
          children_under_three_count: 0,
          disability_level: "none"
        }
      end

      def input_currency_options
        [
          { code: "PLN", name: "PLN" },
          { code: "EUR", name: "EUR" }
        ]
      end

      def normalize_comparison_age_bracket(_age_bracket)
        default_input.fetch(:age_bracket)
      end

      def comparison_call_overrides(profile_key:, input:)
        return {} unless profile_key.to_s == "self_employed"

        {
          b2b_tax_form: "flat_tax"
        }
      end
    end
  end
end
