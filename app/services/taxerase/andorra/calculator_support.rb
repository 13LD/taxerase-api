module Taxerase
  module Andorra
    module CalculatorSupport
      DISABILITY_LEVELS = %w[none recognized_disability].freeze

      private

      def common_andorra_validation_errors(include_deductible_expenses: false)
        errors = []
        errors << "children_count must be 0 or greater" if parsed_children_count.negative?
        errors << "ascendants_count must be 0 or greater" if parsed_ascendants_count.negative?
        errors << "disabled_dependents_count must be 0 or greater" if parsed_disabled_dependents_count.negative?
        if parsed_disabled_dependents_count > parsed_children_count + parsed_ascendants_count
          errors << "disabled_dependents_count cannot exceed the total number of declared dependents"
        end
        errors << "disability_level must be one of: #{DISABILITY_LEVELS.join(', ')}" unless DISABILITY_LEVELS.include?(disability_level.to_s)
        errors.concat(TaxRelief.validation_errors(
          children_count: parsed_children_count + parsed_ascendants_count,
          disability_level: disability_level,
          spouse_without_income: spouse_without_income,
          mortgage_interest: mortgage_interest,
          pension_contributions: pension_contributions,
          alimony_paid: alimony_paid
        ))

        if include_deductible_expenses
          errors << "deductible_expenses must be 0 or greater" if parsed_deductible_expenses.negative?
          errors << "deductible_expenses is too large for the current calculator" if parsed_deductible_expenses > 50_000_000
        end

        errors
      rescue ArgumentError
        fallback_errors = [
          "children_count must be 0 or greater",
          "ascendants_count must be 0 or greater",
          "disabled_dependents_count must be 0 or greater"
        ]
        include_deductible_expenses ? fallback_errors + [ "deductible_expenses must be 0 or greater" ] : fallback_errors
      end

      def build_common_input_payload(annual_gross_income:)
        {
          gross_income: round_currency(parsed_gross_income),
          salary_period: normalized_salary_period,
          tax_year: tax_year,
          annual_gross_income: round_currency(annual_gross_income),
          monthly_gross_income: round_currency(annual_gross_income / 12),
          age_bracket: "standard",
          children_count: parsed_children_count,
          children_under_three_count: 0,
          disability_level: disability_level.to_s,
          ascendants_count: parsed_ascendants_count,
          disabled_dependents_count: parsed_disabled_dependents_count,
          spouse_without_income: spouse_without_income?,
          mortgage_interest: round_currency(parsed_mortgage_interest),
          pension_contributions: round_currency(parsed_pension_contributions),
          alimony_paid: round_currency(parsed_alimony_paid)
        }
      end

      def andorra_tax_relief(net_general_income:)
        @andorra_tax_relief ||= {}
        cache_key = net_general_income.to_s("F")
        total_dependents = parsed_children_count + parsed_ascendants_count

        @andorra_tax_relief[cache_key] ||= begin
          reductions = TaxRelief.reductions(
            regime: regime,
            children_count: total_dependents,
            disability_level: disability_level,
          spouse_without_income: spouse_without_income,
          mortgage_interest: mortgage_interest,
          pension_contributions: pension_contributions,
          alimony_paid: alimony_paid,
          net_general_income: net_general_income,
          parameter_decimal: method(:parameter_decimal)
        )
          disability_uplift = regime.parameter_decimal!("dependent_reduction") * BigDecimal("0.5") * parsed_disabled_dependents_count

          reductions.merge(
            dependent_reduction: reductions[:dependent_reduction] + disability_uplift,
            total_base_reductions: reductions[:total_base_reductions] + disability_uplift
          )
        end
      end

      def parsed_gross_income
        @parsed_gross_income ||= BigDecimal(gross_income.to_s)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_deductible_expenses
        @parsed_deductible_expenses ||= BigDecimal(deductible_expenses.to_s)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_children_count
        @parsed_children_count ||= TaxRelief.parse_count(children_count)
      end

      def parsed_ascendants_count
        @parsed_ascendants_count ||= TaxRelief.parse_count(ascendants_count)
      end

      def parsed_disabled_dependents_count
        @parsed_disabled_dependents_count ||= TaxRelief.parse_count(disabled_dependents_count)
      end

      def parsed_mortgage_interest
        @parsed_mortgage_interest ||= TaxRelief.parse_amount(mortgage_interest)
      end

      def parsed_pension_contributions
        @parsed_pension_contributions ||= TaxRelief.parse_amount(pension_contributions)
      end

      def parsed_alimony_paid
        @parsed_alimony_paid ||= TaxRelief.parse_amount(alimony_paid)
      end

      def spouse_without_income?
        TaxRelief.boolean_value?(spouse_without_income)
      end

      def normalized_salary_period
        @normalized_salary_period ||= salary_period.to_s.upcase
      end

      def normalize_annual_gross_income
        normalized_salary_period == "MONTH" ? parsed_gross_income * 12 : parsed_gross_income
      end

      def country_record
        @country_record ||= Taxerase::Andorra::CalculationRouter.country
      end

      def parameter_decimal(key)
        value = regime.tax_parameters.find { |parameter| parameter.key == key }&.value_decimal
        raise KeyError, "Missing tax parameter #{key} for #{regime.key}" if value.nil?

        value.to_d
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
