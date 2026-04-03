module Taxerase
  module Portugal
    class EmployeeCalculator
      include CalculatorSupport

      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "portugal_employee_v1".freeze
      COUNTRY_CODE = "PT".freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        children_count:,
        children_under_three_count:,
        disability_level:,
        ascendants_count: 0,
        general_family_expenses: 0,
        health_expenses: 0,
        education_expenses: 0,
        housing_rent: 0,
        alimony_paid: 0,
        care_home_expenses: 0,
        domestic_work_expenses: 0
      )
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          children_count:,
          children_under_three_count:,
          disability_level:,
          ascendants_count:,
          general_family_expenses:,
          health_expenses:,
          education_expenses:,
          housing_rent:,
          alimony_paid:,
          care_home_expenses:,
          domestic_work_expenses:
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
        general_family_expenses:,
        health_expenses:,
        education_expenses:,
        housing_rent:,
        alimony_paid:,
        care_home_expenses:,
        domestic_work_expenses:
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @children_count = children_count
        @children_under_three_count = children_under_three_count
        @disability_level = disability_level
        @ascendants_count = ascendants_count
        @general_family_expenses = general_family_expenses
        @health_expenses = health_expenses
        @education_expenses = education_expenses
        @housing_rent = housing_rent
        @alimony_paid = alimony_paid
        @care_home_expenses = care_home_expenses
        @domestic_work_expenses = domestic_work_expenses
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        annual_social_security = annual_gross_income * parameter_decimal!("employee_social_security_rate")
        specific_deduction = [
          annual_gross_income,
          TaxDeductions.employee_specific_deduction(regime:, annual_social_security:)
        ].min
        taxable_income = [ annual_gross_income - specific_deduction, 0 ].max
        annual_income_tax_before_deductions = ProgressiveTax.call(
          amount: taxable_income,
          brackets: regime.brackets_for("income_tax")
        )
        personal_deductions = portugal_tax_deductions
        annual_income_tax = [
          annual_income_tax_before_deductions - personal_deductions[:total],
          0
        ].max
        total_tax = annual_social_security + annual_income_tax
        annual_net_income = annual_gross_income - total_tax

        {
          metadata: metadata,
          input: build_input_payload(annual_gross_income:),
          breakdown: build_breakdown_payload(
            annual_social_security:,
            specific_deduction:,
            taxable_income:,
            annual_income_tax_before_deductions:,
            annual_income_tax:,
            total_tax:,
            annual_net_income:,
            personal_deductions:
          ),
          detail_cards: build_detail_cards(
            annual_social_security:,
            specific_deduction:,
            taxable_income:,
            annual_income_tax_before_deductions:,
            annual_income_tax:,
            total_tax:,
            personal_deductions:
          ),
          assumptions: assumptions,
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :children_count,
        :children_under_three_count, :disability_level, :ascendants_count, :general_family_expenses,
        :health_expenses, :education_expenses, :housing_rent, :alimony_paid, :care_home_expenses,
        :domestic_work_expenses

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Portugal employee regime" if regime.blank?
        errors.concat(common_portugal_validation_errors)

        raise ValidationError.new(errors) if errors.any?
      end

      def regime
        @regime ||= TaxRegime.includes(:country, :tax_brackets, :tax_parameters, tax_source_usages: :official_tax_source).find_by(
          country:,
          key: tax_regime_key,
          tax_year:,
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
          calculator_version: "portugal-employee-v1"
        }
      end

      def build_input_payload(annual_gross_income:)
        build_common_input_payload(annual_gross_income:)
      end

      def build_breakdown_payload(
        annual_social_security:,
        specific_deduction:,
        taxable_income:,
        annual_income_tax_before_deductions:,
        annual_income_tax:,
        total_tax:,
        annual_net_income:,
        personal_deductions:
      )
        {
          annual_social_security: round_currency(annual_social_security),
          specific_deduction: round_currency(specific_deduction),
          taxable_income: round_currency(taxable_income),
          annual_income_tax_before_deductions: round_currency(annual_income_tax_before_deductions),
          dependent_deduction: round_currency(personal_deductions[:dependent_deduction]),
          dependent_under_three_deduction: round_currency(personal_deductions[:dependent_under_three_deduction]),
          ascendant_deduction: round_currency(personal_deductions[:ascendant_deduction]),
          disability_deduction: round_currency(personal_deductions[:disability_deduction]),
          general_family_deduction: round_currency(personal_deductions[:general_family_deduction]),
          health_expenses_deduction: round_currency(personal_deductions[:health_expenses_deduction]),
          education_expenses_deduction: round_currency(personal_deductions[:education_expenses_deduction]),
          housing_rent_deduction: round_currency(personal_deductions[:housing_rent_deduction]),
          alimony_deduction: round_currency(personal_deductions[:alimony_deduction]),
          care_home_deduction: round_currency(personal_deductions[:care_home_deduction]),
          domestic_work_deduction: round_currency(personal_deductions[:domestic_work_deduction]),
          total_personal_tax_deductions: round_currency(personal_deductions[:total]),
          annual_income_tax: round_currency(annual_income_tax),
          total_tax: round_currency(total_tax),
          annual_net_income: round_currency(annual_net_income),
          monthly_net_income: round_currency(annual_net_income / 12),
          effective_tax_rate: round_percentage(total_tax / normalize_annual_gross_income)
        }
      end

      def build_detail_cards(
        annual_social_security:,
        specific_deduction:,
        taxable_income:,
        annual_income_tax_before_deductions:,
        annual_income_tax:,
        total_tax:,
        personal_deductions:
      )
        [
          { label: "Employee social security", value: round_currency(annual_social_security) },
          { label: "Specific deduction", value: round_currency(specific_deduction) },
          { label: "Taxable income", value: round_currency(taxable_income) },
          { label: "Portuguese IRS before deductions", value: round_currency(annual_income_tax_before_deductions) },
          {
            label: "Dependent and ascendant deductions",
            value: round_currency(
              personal_deductions[:dependent_deduction] +
              personal_deductions[:dependent_under_three_deduction] +
              personal_deductions[:ascendant_deduction]
            )
          },
          { label: "Disability deduction", value: round_currency(personal_deductions[:disability_deduction]) },
          {
            label: "Expense-based deductions",
            value: round_currency(
              personal_deductions[:general_family_deduction] +
              personal_deductions[:health_expenses_deduction] +
              personal_deductions[:education_expenses_deduction] +
              personal_deductions[:housing_rent_deduction] +
              personal_deductions[:alimony_deduction] +
              personal_deductions[:care_home_deduction] +
              personal_deductions[:domestic_work_deduction]
            )
          },
          { label: "Portuguese IRS", value: round_currency(annual_income_tax) },
          { label: "Total tax", value: round_currency(total_tax) }
        ]
      end

      def assumptions
        [
          "Portugal only, mainland-resident individual, tax year #{tax_year}.",
          "Employment income uses the seeded employee social security rate and the higher of the standard category A specific deduction or mandatory employee contributions.",
          "Included deductions: dependents, dependents under 3, ascendants in the household, taxpayer disability at 60% or more, general family expenses, health, education, housing rent, alimony, care home costs, and declared domestic work remuneration.",
          "Joint filing, IRS Jovem, union dues, professional order dues, invoice/VAT deductions, disability rehabilitation and insurance deductions, young-dependent bonuses for the second child and later up to age 6, legacy mortgage-interest deductions, and the minimum-existence adjustment are not included."
        ]
      end
    end
  end
end
