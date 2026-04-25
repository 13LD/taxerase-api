module Taxerase
  module Andorra
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

      CALCULATION_METHOD = "andorra_self_employed_v1".freeze
      CALCULATOR_VERSION = "andorra-self-employed-v2".freeze
      COUNTRY_CODE = "AD".freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        deductible_expenses: 0,
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none",
        ascendants_count: 0,
        disabled_dependents_count: 0,
        has_spouse_or_partner: false,
        spouse_without_income: false,
        spouse_general_income: 0,
        mortgage_interest: 0,
        home_acquisition_investment: 0,
        affordable_rental_housing_investment: 0,
        higher_education_tuition: 0,
        pension_contributions: 0,
        alimony_paid: 0,
        self_employed_social_security_regime: "standard",
        apply_housing_rent_support: false,
        housing_support_priority_group: false,
        housing_rent: 0,
        **_unused
      )
        new(
          gross_income: gross_income,
          salary_period: salary_period,
          tax_regime_key: tax_regime_key,
          tax_year: tax_year,
          deductible_expenses: deductible_expenses,
          children_count: children_count,
          children_under_three_count: children_under_three_count,
          disability_level: disability_level,
          ascendants_count: ascendants_count,
          disabled_dependents_count: disabled_dependents_count,
          has_spouse_or_partner: has_spouse_or_partner,
          spouse_without_income: spouse_without_income,
          spouse_general_income: spouse_general_income,
          mortgage_interest: mortgage_interest,
          home_acquisition_investment: home_acquisition_investment,
          affordable_rental_housing_investment: affordable_rental_housing_investment,
          higher_education_tuition: higher_education_tuition,
          pension_contributions: pension_contributions,
          alimony_paid: alimony_paid,
          self_employed_social_security_regime: self_employed_social_security_regime,
          apply_housing_rent_support: apply_housing_rent_support,
          housing_support_priority_group: housing_support_priority_group,
          housing_rent: housing_rent
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
        ascendants_count:,
        disabled_dependents_count:,
        has_spouse_or_partner:,
        spouse_without_income:,
        spouse_general_income:,
        mortgage_interest:,
        home_acquisition_investment:,
        affordable_rental_housing_investment:,
        higher_education_tuition:,
        pension_contributions:,
        alimony_paid:,
        self_employed_social_security_regime:,
        apply_housing_rent_support:,
        housing_support_priority_group:,
        housing_rent:,
        **_unused
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @deductible_expenses = deductible_expenses
        @children_count = children_count
        @children_under_three_count = children_under_three_count
        @disability_level = disability_level
        @ascendants_count = ascendants_count
        @disabled_dependents_count = disabled_dependents_count
        @has_spouse_or_partner = has_spouse_or_partner
        @spouse_without_income = spouse_without_income
        @spouse_general_income = spouse_general_income
        @mortgage_interest = mortgage_interest
        @home_acquisition_investment = home_acquisition_investment
        @affordable_rental_housing_investment = affordable_rental_housing_investment
        @higher_education_tuition = higher_education_tuition
        @pension_contributions = pension_contributions
        @alimony_paid = alimony_paid
        @self_employed_social_security_regime = self_employed_social_security_regime
        @apply_housing_rent_support = apply_housing_rent_support
        @housing_support_priority_group = housing_support_priority_group
        @housing_rent = housing_rent
      end

      def call
        run_validation

        annual_gross_income = normalize_annual_gross_income
        annual_deductible_expenses = parsed_deductible_expenses
        contribution_base = SelfEmployedContributionBase.call(
          net_income: [ annual_gross_income - annual_deductible_expenses, BigDecimal("0") ].max,
          regime: regime,
          social_security_regime: self_employed_social_security_regime
        )
        annual_social_security = contribution_base.fetch(:annual_contribution)
        net_general_income = [ annual_gross_income - annual_deductible_expenses - annual_social_security, BigDecimal("0") ].max
        reductions = andorra_tax_relief(net_general_income: net_general_income)
        housing_support = andorra_housing_support
        taxable_income = [ net_general_income - reductions[:total_base_reductions], BigDecimal("0") ].max
        base_income_tax = taxable_income * parameter_decimal("income_tax_rate")
        earned_income_bonus = [
          base_income_tax * parameter_decimal("earned_income_bonus_rate"),
          parameter_decimal("earned_income_bonus_cap")
        ].min
        annual_income_tax = [ base_income_tax - earned_income_bonus, BigDecimal("0") ].max
        total_tax = annual_social_security + annual_income_tax
        annual_net_income = annual_gross_income - annual_deductible_expenses - total_tax

        {
          metadata: metadata,
          input: build_common_input_payload(annual_gross_income: annual_gross_income).merge(
            deductible_expenses: round_currency(annual_deductible_expenses),
            self_employed_social_security_regime: self_employed_social_security_regime.to_s
          ),
          breakdown: {
            annual_deductible_expenses: round_currency(annual_deductible_expenses),
            annual_social_security: round_currency(annual_social_security),
            self_employed_social_security_base_monthly: round_currency(contribution_base[:monthly_base]),
            self_employed_social_security_base_annual: round_currency(contribution_base[:annual_base]),
            self_employed_social_security_rate: round_percentage(contribution_base[:contribution_rate]),
            net_general_income: round_currency(net_general_income),
            taxpayer_reduction: round_currency(reductions[:taxpayer_reduction]),
            spouse_phase_in_increment: round_currency(reductions[:spouse_phase_in_increment]),
            dependent_reduction: round_currency(reductions[:dependent_reduction]),
            dependent_disability_uplift: round_currency(reductions[:dependent_disability_uplift]),
            habitual_home_investment_reduction: round_currency(reductions[:habitual_home_investment_reduction]),
            affordable_rental_housing_investment_reduction: round_currency(reductions[:affordable_rental_housing_investment_reduction]),
            higher_education_tuition_reduction: round_currency(reductions[:higher_education_tuition_reduction]),
            pension_contribution_reduction: round_currency(reductions[:pension_reduction]),
            alimony_reduction: round_currency(reductions[:alimony_reduction]),
            total_base_reductions: round_currency(reductions[:total_base_reductions]),
            taxable_income: round_currency(taxable_income),
            annual_income_tax_before_credits: round_currency(base_income_tax),
            earned_income_bonus: round_currency(earned_income_bonus),
            annual_income_tax: round_currency(annual_income_tax),
            total_tax: round_currency(total_tax),
            annual_net_income: round_currency(annual_net_income),
            monthly_net_income: round_currency(annual_net_income / 12),
            annual_housing_rent_support_estimate: round_currency(housing_support[:annual_support_estimate]),
            effective_tax_rate: round_percentage(total_tax / annual_gross_income)
          },
          detail_cards: prune_zero_value_detail_cards([
            { label: "Documented business expenses", value: round_currency(annual_deductible_expenses) },
            { label: "Self-employed CASS contribution", value: round_currency(annual_social_security) },
            { label: "Monthly CASS contribution base", value: round_currency(contribution_base[:monthly_base]) },
            { label: "Spouse phase-in increment", value: round_currency(reductions[:spouse_phase_in_increment]) },
            { label: "Dependent disability uplift", value: round_currency(reductions[:dependent_disability_uplift]) },
            { label: "Habitual-home investment base reduction", value: round_currency(reductions[:habitual_home_investment_reduction]) },
            { label: "Affordable-rental housing investment base reduction", value: round_currency(reductions[:affordable_rental_housing_investment_reduction]) },
            { label: "Higher-education tuition reduction", value: round_currency(reductions[:higher_education_tuition_reduction]) },
            { label: "Base reductions", value: round_currency(reductions[:total_base_reductions]) },
            { label: "Taxable activity income", value: round_currency(taxable_income) },
            { label: "Andorran IRPF before credits", value: round_currency(base_income_tax) },
            { label: "Earned-income bonus", value: round_currency(earned_income_bonus) },
            { label: "Andorran IRPF", value: round_currency(annual_income_tax) },
            { label: "Total tax", value: round_currency(total_tax) },
            { label: "Housing rent support estimate (non-tax)", value: round_currency(housing_support[:annual_support_estimate]) }
          ]),
          assumptions: assumptions(contribution_base),
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :deductible_expenses,
        :children_count, :children_under_three_count, :disability_level, :ascendants_count, :disabled_dependents_count,
        :has_spouse_or_partner, :spouse_without_income, :spouse_general_income, :mortgage_interest,
        :home_acquisition_investment, :affordable_rental_housing_investment, :higher_education_tuition,
        :pension_contributions, :alimony_paid, :self_employed_social_security_regime,
        :apply_housing_rent_support, :housing_support_priority_group, :housing_rent

      def run_validation
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "deductible_expenses must be 0 or greater" if parsed_deductible_expenses.negative?
        errors << "deductible_expenses is too large for the current calculator" if parsed_deductible_expenses > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Andorra self-employed regime" if regime.nil?
        unless SelfEmployedContributionBase::SOCIAL_SECURITY_REGIMES.include?(self_employed_social_security_regime.to_s)
          errors << "self_employed_social_security_regime must be one of: #{SelfEmployedContributionBase::SOCIAL_SECURITY_REGIMES.join(', ')}"
        end
        errors.concat(common_andorra_validation_errors)
        raise ValidationError.new(errors.uniq) if errors.any?
      end

      def regime
        @regime ||= find_regime(
          category: "self_employed",
          tax_year: tax_year,
          country: country_record,
          scope: :with_source_data
        )
      end

      def metadata
        build_regime_metadata(calculator_version: CALCULATOR_VERSION)
      end

      def assumptions(contribution_base)
        base_assumptions = [
          "Andorra, tax year #{tax_year}.",
          "Self-employed income is treated as economic-activity income under IRPF with a flat 10% rate after supported reductions and credits.",
          "Habitual-home, affordable-rental housing, and higher-education reductions are applied as tax-base reductions with the selected year's seeded caps.",
          supported_reductions_assumption(include_taxpayer_disability: false)
        ]

        if contribution_base[:social_security_regime] == "standard"
          base_assumptions << "Standard CASS own-account contributions use the seeded income-band ratio table over the previous-year average monthly salary."
        elsif contribution_base[:social_security_regime] == "under_35_first_12_months"
          base_assumptions << "The under-35 special CASS regime is applied for the first 12 months: 55% of the official minimum salary with the 10% general-branch contribution only."
        else
          base_assumptions << "The under-35 special CASS regime is applied for months 13 to 24: 55% of the official minimum salary with the full 22% contribution rate."
        end

        append_housing_support_assumption(base_assumptions)
      end
    end
  end
end
