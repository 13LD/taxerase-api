module Taxerase
  module CzechRepublic
    class SelfEmployedCalculator
      include Taxerase::Support::RegimeBackedCalculation

      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "czech_self_employed_v1".freeze
      COUNTRY_CODE = "CZ".freeze
      EXPENSE_DEDUCTION_METHODS = %w[actual_expenses flat_expense_80 flat_expense_60 flat_expense_40 flat_expense_30].freeze
      SELF_EMPLOYED_TAX_MODES = %w[standard pausal_band_1 pausal_band_2 pausal_band_3].freeze
      OSVC_ACTIVITY_STATUSES = %w[main secondary new_main_activity].freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        deductible_expenses:,
        expense_deduction_method: "actual_expenses",
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
        donations_amount: 0,
        self_employed_tax_mode: "standard",
        osvc_activity_status: "main"
      )
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          deductible_expenses:,
          expense_deduction_method:,
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
          donations_amount:,
          self_employed_tax_mode:,
          osvc_activity_status:
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
        disability_level:,
        child_credit_claim_share:,
        apply_spouse_credit:,
        spouse_income:,
        spouse_ztp_p:,
        spouse_cares_child_under_three:,
        mortgage_interest_paid:,
        pension_contributions:,
        life_insurance_contributions:,
        donations_amount:,
        self_employed_tax_mode:,
        osvc_activity_status:
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @deductible_expenses = deductible_expenses
        @expense_deduction_method = expense_deduction_method
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
        @self_employed_tax_mode = self_employed_tax_mode
        @osvc_activity_status = osvc_activity_status
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        annual_deductible_expenses = resolved_annual_deductible_expenses
        business_profit = [ annual_gross_income - annual_deductible_expenses, 0 ].max
        return pausal_result(annual_gross_income:, annual_deductible_expenses:, business_profit:) if pausal_tax_mode?

        reliefs = personal_reliefs
        non_taxable_deductions = reliefs.non_taxable_deductions_for(business_profit)
        social_assessment_base = [
          business_profit * parameter_decimal!("social_assessment_base_rate"),
          minimum_social_assessment_base
        ].max
        social_assessment_base = [ social_assessment_base, annual_max_social_assessment_base ].min
        annual_social_security = [ social_assessment_base * parameter_decimal!("social_contribution_rate"), annual_min_social_contribution ].max
        health_assessment_base = [
          business_profit * parameter_decimal!("health_assessment_base_rate"),
          minimum_health_assessment_base
        ].max
        annual_health_contribution = [ health_assessment_base * parameter_decimal!("health_contribution_rate"), annual_min_health_contribution ].max
        annual_tax_base_after_deductions = [ business_profit - non_taxable_deductions, 0 ].max
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
        annual_cash_expenses = annual_cash_expenses_for_net_income(annual_deductible_expenses)
        annual_net_income = annual_gross_income - annual_cash_expenses - total_tax

        {
          metadata: metadata,
          input: {
            gross_income: round_currency(parsed_gross_income),
            deductible_expenses: round_currency(annual_deductible_expenses),
            expense_deduction_method: expense_deduction_method.to_s,
            self_employed_tax_mode: self_employed_tax_mode.to_s,
            osvc_activity_status: osvc_activity_status.to_s,
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
            annual_deductible_expenses: round_currency(annual_deductible_expenses),
            business_profit: round_currency(business_profit),
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
            { label: expense_deduction_card_label, value: round_currency(annual_deductible_expenses) },
            { label: "Business profit", value: round_currency(business_profit) },
            { label: "Social security", value: round_currency(annual_social_security) },
            { label: "Health contribution", value: round_currency(annual_health_contribution) },
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

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :deductible_expenses,
        :expense_deduction_method, :children_count, :disability_level, :child_credit_claim_share,
        :apply_spouse_credit, :spouse_income, :spouse_ztp_p, :spouse_cares_child_under_three,
        :mortgage_interest_paid, :pension_contributions, :life_insurance_contributions,
        :donations_amount, :self_employed_tax_mode, :osvc_activity_status

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
        unless SELF_EMPLOYED_TAX_MODES.include?(self_employed_tax_mode.to_s)
          errors << "self_employed_tax_mode must be one of: #{SELF_EMPLOYED_TAX_MODES.join(', ')}"
        end
        unless OSVC_ACTIVITY_STATUSES.include?(osvc_activity_status.to_s)
          errors << "osvc_activity_status must be one of: #{OSVC_ACTIVITY_STATUSES.join(', ')}"
        end
        errors.concat(TaxCredits.validation_errors(disability_level:))
        errors.concat(personal_reliefs.validation_errors)

        parsed_children_count

        raise ValidationError.new(errors) if errors.any?
      rescue ArgumentError
        raise ValidationError.new(errors + [ "children_count must be 0 or greater" ])
      end

      def regime
        @regime ||= find_regime(category: "self_employed", tax_year: tax_year, country: country)
      end

      def country
        @country ||= CalculationRouter.country
      end

      def metadata
        build_regime_metadata(calculator_version: "czech-self-employed-v1")
      end

      def assumptions(annual_child_tax_bonus:)
        assumptions = [
          "Czech Republic, tax year #{tax_year}.",
          deduction_method_assumption,
          "Social and health contributions are estimated from business profit using the official assessment-base ratios and annual minimum contributions stored for the selected OSVC activity status. Social security is capped at the annual maximum assessment base; health insurance is not capped in this calculator.",
          "The calculator applies the basic taxpayer credit, optional disability credit, spouse credit, and child tax credit. Child tax bonus is only paid when the annual qualifying income reaches the seeded statutory threshold.",
          "Mortgage interest, pension/life contributions, and donations reduce the tax base using the seeded caps and eligibility thresholds."
        ]

        if flat_expense_method?
          assumptions.insert(
            2,
            "The selected flat-expense amount is a deemed tax deduction. It reduces taxable profit and contribution bases, but it is not treated as cash spent in the annual net-income metric."
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
        return parsed_deductible_expenses unless flat_expense_method?

        [
          normalize_annual_gross_income * parameter_decimal!("flat_expense_rate_#{flat_expense_rate_key}"),
          parameter_decimal!("flat_expense_cap_#{flat_expense_rate_key}")
        ].min
      end

      def flat_expense_method?
        expense_deduction_method.to_s.start_with?("flat_expense_")
      end

      def flat_expense_rate_key
        expense_deduction_method.to_s.delete_prefix("flat_expense_")
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
        annual_min_social_contribution / parameter_decimal!("social_contribution_rate")
      end

      def minimum_health_assessment_base
        annual_min_health_contribution / parameter_decimal!("health_contribution_rate")
      end

      def annual_max_social_assessment_base
        parameter_decimal!("annual_max_social_assessment_base")
      end

      def expense_deduction_card_label
        flat_expense_method? ? "Deemed tax expenses (#{flat_expense_rate_key}%)" : "Deductible expenses"
      end

      def deduction_method_assumption
        if pausal_tax_mode?
          "Resident self-employed person using paušální daň band #{self_employed_tax_mode.to_s.delete_prefix('pausal_band_')}; standard deductions and credits are not separately applied inside this simplified regime."
        elsif flat_expense_method?
          "Resident self-employed person using the #{flat_expense_rate_key}% flat expense method (paušální výdaje) with the seeded annual cap, not actual expenses or paušální daň."
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

      def pausal_tax_mode?
        self_employed_tax_mode.to_s.start_with?("pausal_band_")
      end

      def pausal_result(annual_gross_income:, annual_deductible_expenses:, business_profit:)
        annual_income_tax = pausal_monthly_amount("income_tax") * 12
        annual_social_security = pausal_monthly_amount("social_security") * 12
        annual_health_contribution = pausal_monthly_amount("health_contribution") * 12
        total_tax = annual_income_tax + annual_social_security + annual_health_contribution
        annual_cash_expenses = annual_cash_expenses_for_net_income(annual_deductible_expenses)
        annual_net_income = annual_gross_income - annual_cash_expenses - total_tax

        {
          metadata: metadata,
          input: {
            gross_income: round_currency(parsed_gross_income),
            deductible_expenses: round_currency(annual_deductible_expenses),
            expense_deduction_method: expense_deduction_method.to_s,
            self_employed_tax_mode: self_employed_tax_mode.to_s,
            osvc_activity_status: osvc_activity_status.to_s,
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
            non_taxable_deductions: 0.0,
            annual_tax_base_after_deductions: round_currency(business_profit),
            annual_social_security: round_currency(annual_social_security),
            annual_health_contribution: round_currency(annual_health_contribution),
            annual_income_tax_before_credits: round_currency(annual_income_tax),
            taxpayer_credit: 0.0,
            disability_credit: 0.0,
            spouse_credit: 0.0,
            child_credit: 0.0,
            annual_child_tax_bonus: 0.0,
            annual_income_tax: round_currency(annual_income_tax),
            total_tax: round_currency(total_tax),
            annual_net_income: round_currency(annual_net_income),
            monthly_net_income: round_currency(annual_net_income / 12),
            effective_tax_rate: round_percentage(total_tax / annual_gross_income)
          },
          detail_cards: [
            { label: expense_deduction_card_label, value: round_currency(annual_deductible_expenses) },
            { label: "Business profit", value: round_currency(business_profit) },
            { label: "Pausal income tax", value: round_currency(annual_income_tax) },
            { label: "Pausal social security", value: round_currency(annual_social_security) },
            { label: "Pausal health contribution", value: round_currency(annual_health_contribution) },
            { label: "Total tax", value: round_currency(total_tax) }
          ],
          assumptions: assumptions(annual_child_tax_bonus: BigDecimal("0")),
          sources: regime.source_links
        }
      end

      def pausal_monthly_amount(component)
        band = self_employed_tax_mode.to_s.delete_prefix("pausal_band_")
        parameter_decimal!("pausal_band_#{band}_monthly_#{component}")
      end

      def annual_min_social_contribution
        parameter_decimal!("annual_min_social_contribution#{activity_status_parameter_suffix}")
      end

      def annual_min_health_contribution
        parameter_decimal!("annual_min_health_contribution#{activity_status_parameter_suffix}")
      end

      def activity_status_parameter_suffix
        case osvc_activity_status.to_s
        when "secondary"
          "_secondary"
        when "new_main_activity"
          "_new_main"
        else
          ""
        end
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
    end
  end
end
