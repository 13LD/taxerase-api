module Taxerase
  module Andorra
    class EmployeeCalculator
      include CalculatorSupport

      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "andorra_employee_v1".freeze
      COUNTRY_CODE = "AD".freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none",
        ascendants_count: 0,
        disabled_dependents_count: 0,
        spouse_without_income: false,
        mortgage_interest: 0,
        pension_contributions: 0,
        alimony_paid: 0,
        deductible_expenses: 0,
        **_unused
      )
        deductible_expenses
        new(
          gross_income: gross_income,
          salary_period: salary_period,
          tax_regime_key: tax_regime_key,
          tax_year: tax_year,
          children_count: children_count,
          children_under_three_count: children_under_three_count,
          disability_level: disability_level,
          ascendants_count: ascendants_count,
          disabled_dependents_count: disabled_dependents_count,
          spouse_without_income: spouse_without_income,
          mortgage_interest: mortgage_interest,
          pension_contributions: pension_contributions,
          alimony_paid: alimony_paid
        ).call
      end

      def initialize(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        children_count:,
        children_under_three_count:,
        disability_level:,
        ascendants_count:,
        disabled_dependents_count:,
        spouse_without_income:,
        mortgage_interest:,
        pension_contributions:,
        alimony_paid:,
        **_unused
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @children_count = children_count
        @children_under_three_count = children_under_three_count
        @disability_level = disability_level
        @ascendants_count = ascendants_count
        @disabled_dependents_count = disabled_dependents_count
        @spouse_without_income = spouse_without_income
        @mortgage_interest = mortgage_interest
        @pension_contributions = pension_contributions
        @alimony_paid = alimony_paid
      end

      def call
        run_validation

        annual_gross_income = normalize_annual_gross_income
        annual_social_security = annual_gross_income * parameter_decimal("employee_social_security_rate")
        work_expense_deduction = [
          annual_gross_income * parameter_decimal("work_expense_rate"),
          parameter_decimal("work_expense_cap")
        ].min
        net_general_income = [ annual_gross_income - annual_social_security - work_expense_deduction, BigDecimal("0") ].max
        reductions = andorra_tax_relief(net_general_income: net_general_income)
        taxable_income = [ net_general_income - reductions[:total_base_reductions], BigDecimal("0") ].max
        base_income_tax = taxable_income * parameter_decimal("income_tax_rate")
        earned_income_bonus = [
          base_income_tax * parameter_decimal("earned_income_bonus_rate"),
          parameter_decimal("earned_income_bonus_cap")
        ].min
        annual_income_tax = [ base_income_tax - reductions[:mortgage_interest_credit] - earned_income_bonus, BigDecimal("0") ].max
        total_tax = annual_social_security + annual_income_tax
        annual_net_income = annual_gross_income - total_tax

        {
          metadata: metadata,
          input: build_common_input_payload(annual_gross_income: annual_gross_income),
          breakdown: {
            annual_social_security: round_currency(annual_social_security),
            work_expense_deduction: round_currency(work_expense_deduction),
            net_general_income: round_currency(net_general_income),
            taxpayer_reduction: round_currency(reductions[:taxpayer_reduction]),
            dependent_reduction: round_currency(reductions[:dependent_reduction]),
            pension_contribution_reduction: round_currency(reductions[:pension_reduction]),
            alimony_reduction: round_currency(reductions[:alimony_reduction]),
            total_base_reductions: round_currency(reductions[:total_base_reductions]),
            taxable_income: round_currency(taxable_income),
            annual_income_tax_before_credits: round_currency(base_income_tax),
            earned_income_bonus: round_currency(earned_income_bonus),
            mortgage_interest_credit: round_currency(reductions[:mortgage_interest_credit]),
            annual_income_tax: round_currency(annual_income_tax),
            total_tax: round_currency(total_tax),
            annual_net_income: round_currency(annual_net_income),
            monthly_net_income: round_currency(annual_net_income / 12),
            effective_tax_rate: round_percentage(total_tax / annual_gross_income)
          },
          detail_cards: [
            { label: "Employee CASS contribution", value: round_currency(annual_social_security) },
            { label: "Work-income deduction", value: round_currency(work_expense_deduction) },
            { label: "Base reductions", value: round_currency(reductions[:total_base_reductions]) },
            { label: "Taxable income", value: round_currency(taxable_income) },
            { label: "Andorran IRPF before credits", value: round_currency(base_income_tax) },
            { label: "Earned-income bonus", value: round_currency(earned_income_bonus) },
            { label: "Mortgage-interest credit", value: round_currency(reductions[:mortgage_interest_credit]) },
            { label: "Andorran IRPF", value: round_currency(annual_income_tax) },
            { label: "Total tax", value: round_currency(total_tax) }
          ],
          assumptions: assumptions,
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :children_count,
        :children_under_three_count, :disability_level, :ascendants_count, :disabled_dependents_count,
        :spouse_without_income, :mortgage_interest, :pension_contributions, :alimony_paid

      def run_validation
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Andorra employee regime" if regime.nil?
        errors.concat(common_andorra_validation_errors)
        raise ValidationError.new(errors.uniq) if errors.any?
      end

      def regime
        @regime ||= TaxRegime.includes(:country, :tax_brackets, :tax_parameters, tax_source_usages: :official_tax_source).find_by(
          country: country_record,
          key: tax_regime_key,
          tax_year: tax_year,
          category: "employee"
        )
      end

      def metadata
        {
          country_code: regime.country.code,
          country_name: regime.country.name,
          region: regime.region,
          tax_year: regime.tax_year,
          tax_regime_key: regime.key,
          tax_regime_name: regime.name,
          calculator_version: "andorra-employee-v1"
        }
      end

      def assumptions
        [
          "Andorra, tax year #{tax_year}.",
          "The calculator applies the flat 10% IRPF rate after employee CASS, the official 3% work-income deduction capped at EUR 2,500, and the supported personal and family reductions.",
          "Supported reductions in this calculator: taxpayer disability uplift, spouse or partner with no income, dependents, pension contributions, alimony paid, and mortgage-interest credit.",
          "The spouse-income phase-in below the 40,000 EUR household threshold, disabled-dependent uplift, housing-rent deductions, and other edge-case relief interactions are not included."
        ]
      end
    end
  end
end
