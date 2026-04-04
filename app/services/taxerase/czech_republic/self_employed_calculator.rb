module Taxerase
  module CzechRepublic
    class SelfEmployedCalculator
      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "czech_self_employed_v1".freeze
      COUNTRY_CODE = "CZ".freeze
      EXPENSE_DEDUCTION_METHODS = %w[actual_expenses flat_expense_60].freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        deductible_expenses:,
        expense_deduction_method: "actual_expenses",
        children_count:,
        disability_level:
      )
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          deductible_expenses:,
          expense_deduction_method:,
          children_count:,
          disability_level:
        ).call
      end

      def initialize(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        deductible_expenses:,
        expense_deduction_method:,
        children_count:,
        disability_level:
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @deductible_expenses = deductible_expenses
        @expense_deduction_method = expense_deduction_method
        @children_count = children_count
        @disability_level = disability_level
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        annual_deductible_expenses = resolved_annual_deductible_expenses
        business_profit = [ annual_gross_income - annual_deductible_expenses, 0 ].max
        social_assessment_base = [
          business_profit * parameter_decimal!("social_assessment_base_rate"),
          minimum_social_assessment_base
        ].max
        social_assessment_base = [ social_assessment_base, annual_max_social_assessment_base ].min
        annual_social_security = [ social_assessment_base * parameter_decimal!("social_contribution_rate"), parameter_decimal!("annual_min_social_contribution") ].max
        health_assessment_base = [
          business_profit * parameter_decimal!("health_assessment_base_rate"),
          minimum_health_assessment_base
        ].max
        annual_health_contribution = [ health_assessment_base * parameter_decimal!("health_contribution_rate"), parameter_decimal!("annual_min_health_contribution") ].max
        annual_income_tax_before_credits = ProgressiveTax.call(amount: business_profit, brackets: regime.brackets_for("income_tax"))
        taxpayer_credit = parameter_decimal!("taxpayer_credit")
        disability_credit = TaxCredits.disability_credit(regime:, disability_level:)
        tax_after_standard_credits = [
          annual_income_tax_before_credits - taxpayer_credit - disability_credit,
          0
        ].max
        child_credit = TaxCredits.child_credit(regime:, children_count:)
        annual_child_tax_bonus = TaxCredits.child_tax_bonus(
          regime:,
          annual_qualifying_income: annual_gross_income,
          child_credit:,
          tax_after_standard_credits:
        )
        annual_income_tax = [ tax_after_standard_credits - child_credit, 0 ].max
        total_tax = annual_social_security + annual_health_contribution + annual_income_tax - annual_child_tax_bonus
        annual_cash_expenses = annual_cash_expenses_for_net_income(annual_deductible_expenses)
        annual_net_income = annual_gross_income - annual_cash_expenses - total_tax

        {
          metadata: metadata,
          input: {
            gross_income: round_currency(parsed_gross_income),
            deductible_expenses: round_currency(annual_deductible_expenses),
            expense_deduction_method: expense_deduction_method.to_s,
            salary_period: normalized_salary_period,
            tax_year:,
            annual_gross_income: round_currency(annual_gross_income),
            monthly_gross_income: round_currency(annual_gross_income / 12),
            age_bracket: "standard",
            children_count: parsed_children_count,
            children_under_three_count: 0,
            disability_level:
          },
          breakdown: {
            annual_deductible_expenses: round_currency(annual_deductible_expenses),
            business_profit: round_currency(business_profit),
            annual_social_security: round_currency(annual_social_security),
            annual_health_contribution: round_currency(annual_health_contribution),
            annual_income_tax_before_credits: round_currency(annual_income_tax_before_credits),
            taxpayer_credit: round_currency(taxpayer_credit),
            disability_credit: round_currency(disability_credit),
            child_credit: round_currency(child_credit),
            annual_child_tax_bonus: round_currency(annual_child_tax_bonus),
            annual_income_tax: round_currency(annual_income_tax),
            total_tax: round_currency(total_tax),
            annual_net_income: round_currency(annual_net_income),
            monthly_net_income: round_currency(annual_net_income / 12),
            effective_tax_rate: round_percentage(total_tax / annual_gross_income)
          },
          detail_cards: [
            { label: expense_deduction_card_label, value: round_currency(annual_deductible_expenses) },
            { label: "Business profit", value: round_currency(business_profit) },
            { label: "Social security", value: round_currency(annual_social_security) },
            { label: "Health contribution", value: round_currency(annual_health_contribution) },
            { label: "Income tax before credits", value: round_currency(annual_income_tax_before_credits) },
            { label: "Basic taxpayer credit", value: round_currency(taxpayer_credit) },
            { label: "Disability credit", value: round_currency(disability_credit) },
            { label: "Child credit", value: round_currency(child_credit) },
            { label: "Child tax bonus", value: round_currency(annual_child_tax_bonus) },
            { label: "Income tax", value: round_currency(annual_income_tax) },
            { label: "Total tax", value: round_currency(total_tax) }
          ],
          assumptions: assumptions(annual_child_tax_bonus:),
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :deductible_expenses,
        :expense_deduction_method, :children_count, :disability_level

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        if expense_deduction_method.to_s == "actual_expenses"
          errors << "deductible_expenses must be 0 or greater" if parsed_deductible_expenses.negative?
          errors << "deductible_expenses is too large for the current calculator" if parsed_deductible_expenses > 50_000_000
        end
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Czech self-employed regime" if regime.blank?
        unless EXPENSE_DEDUCTION_METHODS.include?(expense_deduction_method.to_s)
          errors << "expense_deduction_method must be one of: #{EXPENSE_DEDUCTION_METHODS.join(', ')}"
        end
        errors.concat(TaxCredits.validation_errors(disability_level:))

        parsed_children_count

        raise ValidationError.new(errors) if errors.any?
      rescue ArgumentError
        raise ValidationError.new(errors + [ "children_count must be 0 or greater" ])
      end

      def regime
        @regime ||= TaxRegime.includes(:country, :tax_brackets, :tax_parameters, tax_source_usages: :official_tax_source).find_by(
          country:,
          key: tax_regime_key,
          tax_year:,
          category: "self_employed"
        )
      end

      def country
        @country ||= Country.find_by!(code: COUNTRY_CODE)
      end

      def metadata
        {
          country_code: regime.country.code,
          country_name: regime.country.name,
          region: regime.region,
          tax_year: regime.tax_year,
          tax_regime_key: regime.key,
          tax_regime_name: regime.name,
          calculator_version: "czech-self-employed-v1"
        }
      end

      def assumptions(annual_child_tax_bonus:)
        assumptions = [
          "Czech Republic, tax year #{tax_year}.",
          deduction_method_assumption,
          "Social and health contributions are estimated from business profit using the official assessment-base ratios and annual minimum contributions stored for the seeded year. Social security is capped at the annual maximum assessment base; health insurance is not capped in this calculator.",
          "The calculator applies the basic taxpayer credit, optional disability credit, and child tax credit. Child tax bonus is only paid when the annual qualifying income reaches the seeded statutory threshold.",
          "Mortgage interest, gifts, pension deductions, spouse credit, and flat-tax regime rules are not included."
        ]

        if expense_deduction_method.to_s == "flat_expense_60"
          assumptions.insert(
            2,
            "The 60% flat-expense amount is a deemed tax deduction. It reduces taxable profit and contribution bases, but it is not treated as cash spent in the annual net-income metric."
          )
        end

        return assumptions unless annual_child_tax_bonus.positive?

        assumptions << "Child credit exceeds the tax after standard credits, so the result includes an estimated child tax bonus."
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

      def resolved_annual_deductible_expenses
        return parsed_deductible_expenses unless expense_deduction_method.to_s == "flat_expense_60"

        [
          normalize_annual_gross_income * parameter_decimal!("flat_expense_rate_60"),
          parameter_decimal!("flat_expense_cap_60")
        ].min
      end

      def parsed_children_count
        @parsed_children_count ||= begin
          parsed_value = Integer(children_count.to_s, exception: false)
          raise ArgumentError if parsed_value.nil? || parsed_value.negative?

          parsed_value
        end
      end

      def normalized_salary_period
        @normalized_salary_period ||= salary_period.to_s.upcase
      end

      def normalize_annual_gross_income
        normalized_salary_period == "MONTH" ? parsed_gross_income * 12 : parsed_gross_income
      end

      def parameter_decimal!(key)
        regime.parameter_decimal!(key)
      end

      def minimum_social_assessment_base
        parameter_decimal!("annual_min_social_contribution") / parameter_decimal!("social_contribution_rate")
      end

      def minimum_health_assessment_base
        parameter_decimal!("annual_min_health_contribution") / parameter_decimal!("health_contribution_rate")
      end

      def annual_max_social_assessment_base
        parameter_decimal!("annual_max_social_assessment_base")
      end

      def expense_deduction_card_label
        expense_deduction_method.to_s == "flat_expense_60" ? "Deemed tax expenses (60%)" : "Deductible expenses"
      end

      def deduction_method_assumption
        if expense_deduction_method.to_s == "flat_expense_60"
          "Resident self-employed person using the 60% flat expense method (paušální výdaje) with the seeded annual cap, not actual expenses or paušální daň."
        else
          "Resident self-employed person using actual deductible expenses, not paušální výdaje or paušální daň."
        end
      end

      def round_currency(amount)
        amount.round(2).to_f
      end

      def round_percentage(decimal)
        (decimal * 100).round(2).to_f
      end

      def annual_cash_expenses_for_net_income(annual_deductible_expenses)
        return annual_deductible_expenses if expense_deduction_method.to_s == "actual_expenses"

        BigDecimal("0")
      end
    end
  end
end
