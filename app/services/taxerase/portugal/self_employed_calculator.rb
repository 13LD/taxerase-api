module Taxerase
  module Portugal
    class SelfEmployedCalculator
      include Taxerase::Support::RegimeBackedCalculation

      include CalculatorSupport

      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "portugal_self_employed_v1".freeze
      COUNTRY_CODE = "PT".freeze
      ACTIVITY_TYPES = {
        "professional_services" => {
          taxable_income_rate: BigDecimal("0.75"),
          social_security_relevant_income_rate: BigDecimal("0.70"),
          documentation_support_required: true
        },
        "other_services" => {
          taxable_income_rate: BigDecimal("0.35"),
          social_security_relevant_income_rate: BigDecimal("0.70"),
          documentation_support_required: true
        },
        "sales_goods_hospitality" => {
          taxable_income_rate: BigDecimal("0.15"),
          social_security_relevant_income_rate: BigDecimal("0.20"),
          documentation_support_required: false
        }
      }.freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        deductible_expenses:,
        children_count:,
        children_under_three_count:,
        disability_level:,
        business_activity_type: "professional_services",
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
          deductible_expenses:,
          children_count:,
          children_under_three_count:,
          disability_level:,
          business_activity_type:,
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
        deductible_expenses:,
        children_count:,
        children_under_three_count:,
        disability_level:,
        business_activity_type:,
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
        @deductible_expenses = deductible_expenses
        @children_count = children_count
        @children_under_three_count = children_under_three_count
        @disability_level = disability_level
        @business_activity_type = business_activity_type
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
        annual_deductible_expenses = parsed_deductible_expenses
        activity_profile = ACTIVITY_TYPES.fetch(business_activity_type.to_s)
        annual_social_security = annual_gross_income *
          activity_profile.fetch(:social_security_relevant_income_rate) *
          parameter_decimal!("self_employed_social_security_rate")
        social_security_excess_deduction = if activity_profile.fetch(:documentation_support_required)
          [ annual_social_security - (annual_gross_income * BigDecimal("0.10")), BigDecimal("0") ].max
        else
          BigDecimal("0")
        end
        simplified_taxable_base = annual_gross_income * activity_profile.fetch(:taxable_income_rate)
        documentation_support_base = TaxDeductions.documentation_support_base(
          regime:,
          annual_social_security:,
          annual_gross_income:
        )
        documentation_shortfall_addition = if activity_profile.fetch(:documentation_support_required)
          [
            (annual_gross_income * BigDecimal("0.15")) - documentation_support_base - annual_deductible_expenses,
            BigDecimal("0")
          ].max
        else
          BigDecimal("0")
        end
        taxable_income = [
          simplified_taxable_base - social_security_excess_deduction + documentation_shortfall_addition,
          BigDecimal("0")
        ].max
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
        annual_net_income = annual_gross_income - annual_deductible_expenses - total_tax

        {
          metadata: metadata,
          input: build_input_payload(annual_gross_income:, annual_deductible_expenses:),
          breakdown: build_breakdown_payload(
            annual_social_security:,
            social_security_excess_deduction:,
            simplified_taxable_base:,
            documentation_support_base:,
            documentation_shortfall_addition:,
            taxable_income:,
            annual_income_tax_before_deductions:,
            annual_income_tax:,
            total_tax:,
            annual_net_income:,
            personal_deductions:
          ),
          detail_cards: build_detail_cards(
            annual_deductible_expenses:,
            annual_social_security:,
            social_security_excess_deduction:,
            simplified_taxable_base:,
            documentation_shortfall_addition:,
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

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :deductible_expenses,
        :children_count, :children_under_three_count, :disability_level, :business_activity_type,
        :ascendants_count, :general_family_expenses, :health_expenses, :education_expenses, :housing_rent,
        :alimony_paid, :care_home_expenses, :domestic_work_expenses

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "deductible_expenses must be 0 or greater" if parsed_deductible_expenses.negative?
        errors << "deductible_expenses is too large for the current calculator" if parsed_deductible_expenses > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Portugal self-employed regime" if regime.blank?
        errors << "business_activity_type must be one of: #{ACTIVITY_TYPES.keys.join(', ')}" unless ACTIVITY_TYPES.key?(business_activity_type.to_s)
        errors.concat(common_portugal_validation_errors)

        raise ValidationError.new(errors) if errors.any?
      end

      def regime
        @regime ||= find_regime(category: "self_employed", tax_year: tax_year, country: country)
      end

      def metadata
        build_regime_metadata(calculator_version: "portugal-self-employed-v1")
      end

      def build_input_payload(annual_gross_income:, annual_deductible_expenses:)
        build_common_input_payload(annual_gross_income:).merge(
          deductible_expenses: round_currency(annual_deductible_expenses),
          business_activity_type: business_activity_type.to_s,
        )
      end

      def build_breakdown_payload(
        annual_social_security:,
        social_security_excess_deduction:,
        simplified_taxable_base:,
        documentation_support_base:,
        documentation_shortfall_addition:,
        taxable_income:,
        annual_income_tax_before_deductions:,
        annual_income_tax:,
        total_tax:,
        annual_net_income:,
        personal_deductions:
      )
        {
          annual_deductible_expenses: round_currency(parsed_deductible_expenses),
          annual_social_security: round_currency(annual_social_security),
          social_security_excess_deduction: round_currency(social_security_excess_deduction),
          simplified_taxable_base: round_currency(simplified_taxable_base),
          documentation_support_base: round_currency(documentation_support_base),
          documentation_shortfall_addition: round_currency(documentation_shortfall_addition),
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
        annual_deductible_expenses:,
        annual_social_security:,
        social_security_excess_deduction:,
        simplified_taxable_base:,
        documentation_shortfall_addition:,
        annual_income_tax_before_deductions:,
        annual_income_tax:,
        total_tax:,
        personal_deductions:
      )
        [
          { label: "Documented business expenses", value: round_currency(annual_deductible_expenses) },
          { label: "Simplified taxable base", value: round_currency(simplified_taxable_base) },
          { label: "Documentation shortfall adjustment", value: round_currency(documentation_shortfall_addition) },
          { label: "Social security contribution", value: round_currency(annual_social_security) },
          { label: "Social security deduction above 10% of revenue", value: round_currency(social_security_excess_deduction) },
          { label: "Portuguese IRS before deductions", value: round_currency(annual_income_tax_before_deductions) },
          {
            label: "Personal tax deductions",
            value: round_currency(personal_deductions[:total])
          },
          { label: "Portuguese IRS", value: round_currency(annual_income_tax) },
          { label: "Total tax", value: round_currency(total_tax) }
        ]
      end

      def assumptions
        [
          "Portugal, tax year #{tax_year}.",
          "The activity type selects the official simplified-regime taxable-income coefficient and the matching social-security relevant-income share used by this calculator.",
          "Documented business expenses are treated as supporting expenses for the simplified-regime 15% documentation check and as cash expenses in annual net income.",
          "Mandatory self-employed social security is estimated annually from the seeded rate and relevant-income share. Quarterly declarations, exemptions, adjustment bands, and minimum or maximum incidence-base mechanics are not included.",
          "Included deductions: dependents, dependents under 3, ascendants in the household, taxpayer disability at 60% or more, general family expenses, health, education, housing rent, alimony, care home costs, and declared domestic work remuneration.",
          "Organized accounting, the start-of-activity coefficient reduction, VAT invoice deductions, disability rehabilitation and insurance deductions, young-dependent bonuses for the second child and later up to age 6, joint filing, IRS Jovem, and the minimum-existence adjustment are not included."
        ]
      end

      def parsed_deductible_expenses
        @parsed_deductible_expenses ||= BigDecimal(deductible_expenses.to_s)
      rescue ArgumentError
        BigDecimal("0")
      end
    end
  end
end
