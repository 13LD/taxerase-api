module Taxerase
  module Portugal
    module CalculatorSupport
      private

      def common_portugal_validation_errors
        children_validation_errors + portugal_deduction_validation_errors
      end

      def children_validation_errors
        errors = []
        parsed_children_count
        parsed_children_under_three_count
        if parsed_children_under_three_count > parsed_children_count
          errors << "children_under_three_count must be an integer between 0 and children_count"
        end
        errors
      rescue ArgumentError
        [ "children_count must be 0 or greater", "children_under_three_count must be an integer between 0 and children_count" ]
      end

      def portugal_deduction_validation_errors
        TaxDeductions.validation_errors(
          disability_level:,
          ascendants_count:,
          children_count:,
          young_dependents_second_later_under_six_count:,
          general_family_expenses:,
          health_expenses:,
          education_expenses:,
          housing_rent:,
          alimony_paid:,
          care_home_expenses:,
          domestic_work_expenses:,
          vat_invoice_expenses:,
          vat_invoice_validation_state:,
          disability_rehabilitation_expenses:,
          disability_insurance_premiums:,
          ppr_contributions:,
          ppr_age_band:,
          donations:,
          filing_status:,
          apply_irs_jovem:,
          irs_jovem_year:,
          tax_year:
        )
      end

      def build_common_input_payload(annual_gross_income:)
        {
          gross_income: round_currency(parsed_gross_income),
          salary_period: normalized_salary_period,
          tax_year:,
          annual_gross_income: round_currency(annual_gross_income),
          monthly_gross_income: round_currency(annual_gross_income / 12),
          age_bracket: "standard",
          children_count: parsed_children_count,
          children_under_three_count: parsed_children_under_three_count,
          disability_level: disability_level.to_s,
          ascendants_count: parsed_ascendants_count,
          young_dependents_second_later_under_six_count: parsed_young_dependents_second_later_under_six_count,
          general_family_expenses: round_currency(parsed_general_family_expenses),
          health_expenses: round_currency(parsed_health_expenses),
          education_expenses: round_currency(parsed_education_expenses),
          housing_rent: round_currency(parsed_housing_rent),
          alimony_paid: round_currency(parsed_alimony_paid),
          care_home_expenses: round_currency(parsed_care_home_expenses),
          domestic_work_expenses: round_currency(parsed_domestic_work_expenses),
          vat_invoice_expenses: round_currency(parsed_vat_invoice_expenses),
          vat_invoice_validation_state: vat_invoice_validation_state.to_s.presence || "not_validated",
          disability_rehabilitation_expenses: round_currency(parsed_disability_rehabilitation_expenses),
          disability_insurance_premiums: round_currency(parsed_disability_insurance_premiums),
          ppr_contributions: round_currency(parsed_ppr_contributions),
          ppr_age_band: ppr_age_band.to_s.presence || "under_35",
          donations: round_currency(parsed_donations),
          filing_status: filing_status.to_s.presence || "individual",
          apply_irs_jovem: truthy?(apply_irs_jovem),
          irs_jovem_year: parsed_irs_jovem_year
        }
      end

      def portugal_tax_deductions
        @portugal_tax_deductions ||= TaxDeductions.personal_tax_deductions(
          regime:,
          children_count: parsed_children_count,
          children_under_three_count: parsed_children_under_three_count,
          disability_level: disability_level.to_s,
          ascendants_count: parsed_ascendants_count,
          young_dependents_second_later_under_six_count: parsed_young_dependents_second_later_under_six_count,
          general_family_expenses: parsed_general_family_expenses,
          health_expenses: parsed_health_expenses,
          education_expenses: parsed_education_expenses,
          housing_rent: parsed_housing_rent,
          alimony_paid: parsed_alimony_paid,
          care_home_expenses: parsed_care_home_expenses,
          domestic_work_expenses: parsed_domestic_work_expenses,
          vat_invoice_expenses: parsed_vat_invoice_expenses,
          vat_invoice_validation_state: vat_invoice_validation_state.to_s.presence || "not_validated",
          disability_rehabilitation_expenses: parsed_disability_rehabilitation_expenses,
          disability_insurance_premiums: parsed_disability_insurance_premiums,
          ppr_contributions: parsed_ppr_contributions,
          ppr_age_band: ppr_age_band.to_s.presence || "under_35",
          donations: parsed_donations
        )
      end

      def household_income_tax(amount)
        TaxDeductions.household_income_tax(
          amount:,
          brackets: regime.brackets_for("income_tax"),
          filing_status: filing_status.to_s.presence || "individual"
        )
      end

      def irs_jovem_exempt_income(eligible_income)
        TaxDeductions.irs_jovem_exempt_income(
          regime:,
          tax_year:,
          apply_irs_jovem:,
          irs_jovem_year:,
          eligible_income:
        )
      end

      def parsed_gross_income
        @parsed_gross_income ||= BigDecimal(gross_income.to_s)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_children_count
        @parsed_children_count ||= TaxDeductions.parse_count(children_count)
      end

      def parsed_children_under_three_count
        @parsed_children_under_three_count ||= TaxDeductions.parse_count(children_under_three_count)
      end

      def parsed_ascendants_count
        @parsed_ascendants_count ||= TaxDeductions.parse_count(ascendants_count)
      end

      def parsed_young_dependents_second_later_under_six_count
        @parsed_young_dependents_second_later_under_six_count ||=
          TaxDeductions.parse_count(young_dependents_second_later_under_six_count)
      end

      def parsed_general_family_expenses
        @parsed_general_family_expenses ||= TaxDeductions.parse_amount(general_family_expenses)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_health_expenses
        @parsed_health_expenses ||= TaxDeductions.parse_amount(health_expenses)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_education_expenses
        @parsed_education_expenses ||= TaxDeductions.parse_amount(education_expenses)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_housing_rent
        @parsed_housing_rent ||= TaxDeductions.parse_amount(housing_rent)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_alimony_paid
        @parsed_alimony_paid ||= TaxDeductions.parse_amount(alimony_paid)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_care_home_expenses
        @parsed_care_home_expenses ||= TaxDeductions.parse_amount(care_home_expenses)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_domestic_work_expenses
        @parsed_domestic_work_expenses ||= TaxDeductions.parse_amount(domestic_work_expenses)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_vat_invoice_expenses
        @parsed_vat_invoice_expenses ||= TaxDeductions.parse_amount(vat_invoice_expenses)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_disability_rehabilitation_expenses
        @parsed_disability_rehabilitation_expenses ||= TaxDeductions.parse_amount(disability_rehabilitation_expenses)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_disability_insurance_premiums
        @parsed_disability_insurance_premiums ||= TaxDeductions.parse_amount(disability_insurance_premiums)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_ppr_contributions
        @parsed_ppr_contributions ||= TaxDeductions.parse_amount(ppr_contributions)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_donations
        @parsed_donations ||= TaxDeductions.parse_amount(donations)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_irs_jovem_year
        @parsed_irs_jovem_year ||= Integer(irs_jovem_year.to_s, exception: false) || 0
      end

      def truthy?(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end

      def normalized_salary_period
        @normalized_salary_period ||= salary_period.to_s.upcase
      end

      def normalize_annual_gross_income
        normalized_salary_period == "MONTH" ? parsed_gross_income * 12 : parsed_gross_income
      end

      def country
        @country ||= Taxerase::Portugal::CalculationRouter.country
      end

      def parameter_decimal!(key)
        regime.parameter_decimal!(key)
      end

      def round_currency(amount)
        amount.round(2).to_f
      end

      def round_percentage(decimal)
        (decimal * 100).round(2).to_f
      end
    end
  end
end
