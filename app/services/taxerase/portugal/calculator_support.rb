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
          general_family_expenses:,
          health_expenses:,
          education_expenses:,
          housing_rent:,
          alimony_paid:,
          care_home_expenses:,
          domestic_work_expenses:
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
          general_family_expenses: round_currency(parsed_general_family_expenses),
          health_expenses: round_currency(parsed_health_expenses),
          education_expenses: round_currency(parsed_education_expenses),
          housing_rent: round_currency(parsed_housing_rent),
          alimony_paid: round_currency(parsed_alimony_paid),
          care_home_expenses: round_currency(parsed_care_home_expenses),
          domestic_work_expenses: round_currency(parsed_domestic_work_expenses)
        }
      end

      def portugal_tax_deductions
        @portugal_tax_deductions ||= TaxDeductions.personal_tax_deductions(
          regime:,
          children_count: parsed_children_count,
          children_under_three_count: parsed_children_under_three_count,
          disability_level: disability_level.to_s,
          ascendants_count: parsed_ascendants_count,
          general_family_expenses: parsed_general_family_expenses,
          health_expenses: parsed_health_expenses,
          education_expenses: parsed_education_expenses,
          housing_rent: parsed_housing_rent,
          alimony_paid: parsed_alimony_paid,
          care_home_expenses: parsed_care_home_expenses,
          domestic_work_expenses: parsed_domestic_work_expenses
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

      def normalized_salary_period
        @normalized_salary_period ||= salary_period.to_s.upcase
      end

      def normalize_annual_gross_income
        normalized_salary_period == "MONTH" ? parsed_gross_income * 12 : parsed_gross_income
      end

      def country
        @country ||= Country.find_by!(code: self.class::COUNTRY_CODE)
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
