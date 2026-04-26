module Taxerase
  module CzechRepublic
    class EmployeeCalculator
      include Taxerase::Support::RegimeBackedCalculation

      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "czech_employee_v1".freeze
      COUNTRY_CODE = "CZ".freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        children_count:,
        disability_level:,
        child_credit_claim_share: 100,
        apply_spouse_credit: false,
        spouse_income: 0,
        spouse_ztp_p: false,
        spouse_cares_child_under_three: false,
        mortgage_interest_paid: 0,
        pension_contributions: 0,
        life_insurance_contributions: 0,
        donations_amount: 0
      )
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          children_count:,
          disability_level:,
          child_credit_claim_share:,
          apply_spouse_credit:,
          spouse_income:,
          spouse_ztp_p:,
          spouse_cares_child_under_three:,
          mortgage_interest_paid:,
          pension_contributions:,
          life_insurance_contributions:,
          donations_amount:
        ).call
      end

      def initialize(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        children_count:,
        disability_level:,
        child_credit_claim_share:,
        apply_spouse_credit:,
        spouse_income:,
        spouse_ztp_p:,
        spouse_cares_child_under_three:,
        mortgage_interest_paid:,
        pension_contributions:,
        life_insurance_contributions:,
        donations_amount:
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @children_count = children_count
        @disability_level = disability_level
        @child_credit_claim_share = child_credit_claim_share
        @apply_spouse_credit = apply_spouse_credit
        @spouse_income = spouse_income
        @spouse_ztp_p = spouse_ztp_p
        @spouse_cares_child_under_three = spouse_cares_child_under_three
        @mortgage_interest_paid = mortgage_interest_paid
        @pension_contributions = pension_contributions
        @life_insurance_contributions = life_insurance_contributions
        @donations_amount = donations_amount
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        reliefs = personal_reliefs
        non_taxable_deductions = reliefs.non_taxable_deductions_for(annual_gross_income)
        annual_social_security = employee_social_security_base * parameter_decimal!("employee_social_security_rate")
        annual_health_contribution = annual_gross_income * parameter_decimal!("employee_health_contribution_rate")
        annual_tax_base_after_deductions = [ annual_gross_income - non_taxable_deductions, 0 ].max
        annual_income_tax_before_credits = ProgressiveTax.call(amount: annual_tax_base_after_deductions, brackets: regime.brackets_for("income_tax"))
        taxpayer_credit = parameter_decimal!("taxpayer_credit")
        disability_credit = TaxCredits.disability_credit(regime:, disability_level:)
        spouse_credit = reliefs.spouse_credit
        tax_after_standard_credits = [
          annual_income_tax_before_credits - taxpayer_credit - disability_credit - spouse_credit,
          0
        ].max
        child_credit = TaxCredits.child_credit(regime:, children_count:) * reliefs.child_credit_multiplier
        annual_child_tax_bonus = TaxCredits.child_tax_bonus(
          regime:,
          annual_qualifying_income: annual_gross_income,
          child_credit:,
          tax_after_standard_credits:
        )
        annual_income_tax = [ tax_after_standard_credits - child_credit, 0 ].max
        total_tax = annual_social_security + annual_health_contribution + annual_income_tax - annual_child_tax_bonus
        annual_net_income = annual_gross_income - total_tax

        {
          metadata: metadata,
          input: {
            gross_income: round_currency(parsed_gross_income),
            salary_period: normalized_salary_period,
            tax_year:,
            annual_gross_income: round_currency(annual_gross_income),
            monthly_gross_income: round_currency(annual_gross_income / 12),
            **reliefs.input_payload,
            age_bracket: "standard",
            children_count: parsed_children_count,
            children_under_three_count: 0,
            disability_level:
          },
          breakdown: {
            non_taxable_deductions: round_currency(non_taxable_deductions),
            annual_tax_base_after_deductions: round_currency(annual_tax_base_after_deductions),
            annual_social_security: round_currency(annual_social_security),
            annual_health_contribution: round_currency(annual_health_contribution),
            annual_income_tax_before_credits: round_currency(annual_income_tax_before_credits),
            taxpayer_credit: round_currency(taxpayer_credit),
            disability_credit: round_currency(disability_credit),
            spouse_credit: round_currency(spouse_credit),
            child_credit: round_currency(child_credit),
            annual_child_tax_bonus: round_currency(annual_child_tax_bonus),
            annual_income_tax: round_currency(annual_income_tax),
            total_tax: round_currency(total_tax),
            annual_net_income: round_currency(annual_net_income),
            monthly_net_income: round_currency(annual_net_income / 12),
            effective_tax_rate: round_percentage(total_tax / annual_gross_income)
          },
          detail_cards: [
            { label: "Employee social security", value: round_currency(annual_social_security) },
            { label: "Employee health contribution", value: round_currency(annual_health_contribution) },
            { label: "Income tax before credits", value: round_currency(annual_income_tax_before_credits) },
            { label: "Basic taxpayer credit", value: round_currency(taxpayer_credit) },
            { label: "Disability credit", value: round_currency(disability_credit) },
            { label: "Spouse credit", value: round_currency(spouse_credit) },
            { label: "Non-taxable deductions", value: round_currency(non_taxable_deductions) },
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

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :children_count,
        :disability_level, :child_credit_claim_share, :apply_spouse_credit, :spouse_income,
        :spouse_ztp_p, :spouse_cares_child_under_three, :mortgage_interest_paid,
        :pension_contributions, :life_insurance_contributions, :donations_amount

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Czech employee regime" if regime.blank?
        errors.concat(TaxCredits.validation_errors(disability_level:))
        errors.concat(personal_reliefs.validation_errors)

        parsed_children_count

        raise ValidationError.new(errors) if errors.any?
      rescue ArgumentError
        raise ValidationError.new(errors + [ "children_count must be 0 or greater" ])
      end

      def regime
        @regime ||= find_regime(category: "employee", tax_year: tax_year, country: country)
      end

      def country
        @country ||= CalculationRouter.country
      end

      def metadata
        build_regime_metadata(calculator_version: "czech-employee-v1")
      end

      def assumptions(annual_child_tax_bonus:)
        assumptions = [
          "Czech Republic, tax year #{tax_year}.",
          "Resident employee with standard employee-paid social security and health insurance contributions.",
          "Employee social security is capped at the annual maximum assessment base stored for the seeded year. Health insurance has no cap in this calculator.",
          "The calculator applies the basic taxpayer credit, optional disability credit, spouse credit, and child tax credit. Child tax bonus is only paid when the annual qualifying income reaches the seeded statutory threshold.",
          "Mortgage interest, pension/life contributions, and donations reduce the tax base using the seeded caps and eligibility thresholds. School fee credit remains excluded."
        ]

        return assumptions unless annual_child_tax_bonus.positive?

        assumptions << "Child credit exceeds the tax after standard credits, so the result includes an estimated child tax bonus."
      end

      def parsed_gross_income
        @parsed_gross_income ||= BigDecimal(gross_income.to_s)
      rescue ArgumentError
        BigDecimal("0")
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

      def personal_reliefs
        @personal_reliefs ||= PersonalReliefs.new(
          regime:,
          child_credit_claim_share:,
          apply_spouse_credit:,
          spouse_income:,
          spouse_ztp_p:,
          spouse_cares_child_under_three:,
          mortgage_interest_paid:,
          pension_contributions:,
          life_insurance_contributions:,
          donations_amount:
        )
      end

      def employee_social_security_base
        [ annual_max_social_assessment_base, normalize_annual_gross_income ].min
      end

      def annual_max_social_assessment_base
        parameter_decimal!("annual_max_social_assessment_base")
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
