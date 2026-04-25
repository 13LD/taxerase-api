module Taxerase
  module Netherlands
    class SelfEmployedCalculator
      include Taxerase::Support::RegimeBackedCalculation
      include InputSupport

      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "netherlands_self_employed_v1".freeze
      COUNTRY_CODE = "NL".freeze

      def self.call(gross_income:, salary_period:, tax_regime_key:, tax_year:, deductible_expenses:, age_bracket:, **calculation_inputs)
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          deductible_expenses:,
          age_bracket:,
          calculation_inputs:
        ).call
      end

      def initialize(gross_income:, salary_period:, tax_regime_key:, tax_year:, deductible_expenses:, age_bracket:, calculation_inputs: {})
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @deductible_expenses = deductible_expenses
        @age_bracket = age_bracket
        @calculation_inputs = calculation_inputs.symbolize_keys
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        profile = profile_data
        entrepreneur = EntrepreneurReliefs.call(
          regime:,
          profile:,
          gross_income: annual_gross_income,
          deductible_expenses: parsed_deductible_expenses,
          inputs: calculation_inputs
        )
        sme_profit_exemption = entrepreneur.fetch(:profit_after_investment_reliefs) *
          parameter_decimal!("sme_profit_exemption_rate")
        taxable_profit = [ entrepreneur.fetch(:profit_after_investment_reliefs) - sme_profit_exemption, 0 ].max
        personal_deductions = PersonalDeductions.call(
          regime:,
          profile:,
          taxable_income: taxable_profit,
          combined_income: combined_income(taxable_profit),
          inputs: personal_deduction_inputs
        )
        taxable_income_after_deductions = personal_deductions.fetch(:taxable_income_after_deductions)
        box_1_tax_before_credits = ProgressiveTax.call(
          amount: taxable_income_after_deductions,
          brackets: regime.brackets_for(box_1_bracket_group(profile))
        )
        credits = TaxCredits.call(
          regime:,
          profile:,
          taxable_income: taxable_income_after_deductions,
          labour_income: entrepreneur.fetch(:business_profit_before_reliefs),
          **credit_inputs
        )
        credit_components = credits.fetch(:components)
        total_tax_credits = credits.fetch(:total)
        annual_income_tax = [
          box_1_tax_before_credits - total_tax_credits,
          0
        ].max
        zvw_contribution = [
          taxable_profit,
          parameter_decimal!("zvw_max_contribution_income")
        ].min * parameter_decimal!("zvw_self_assessed_rate")
        total_tax = annual_income_tax + zvw_contribution
        annual_net_income = annual_gross_income - entrepreneur.dig(:expenses, :total) - total_tax

        {
          metadata: metadata,
          input: input_payload(annual_gross_income:, entrepreneur:),
          breakdown: breakdown_payload(
            annual_gross_income:,
            annual_income_tax:,
            annual_net_income:,
            box_1_tax_before_credits:,
            credit_components:,
            entrepreneur:,
            personal_deductions:,
            sme_profit_exemption:,
            taxable_income_after_deductions:,
            taxable_profit:,
            total_tax:,
            total_tax_credits:,
            zvw_contribution:
          ),
          detail_cards: detail_cards(
            annual_income_tax:,
            box_1_tax_before_credits:,
            credit_components:,
            entrepreneur:,
            personal_deductions:,
            sme_profit_exemption:,
            taxable_income_after_deductions:,
            taxable_profit:,
            total_tax:,
            total_tax_credits:,
            zvw_contribution:
          ),
          assumptions: assumptions(profile, entrepreneur, personal_deductions, credits),
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :deductible_expenses,
        :age_bracket, :calculation_inputs

      def input_payload(annual_gross_income:, entrepreneur:)
        {
          gross_income: round_currency(parsed_gross_income),
          deductible_expenses: round_currency(parsed_deductible_expenses),
          salary_period: normalized_salary_period,
          tax_year:,
          annual_gross_income: round_currency(annual_gross_income),
          monthly_gross_income: round_currency(annual_gross_income / 12),
          age_bracket:,
          **credit_input_payload,
          qualifies_as_entrepreneur: entrepreneur.dig(:eligibility, :entrepreneur),
          hours_worked_in_business: round_currency(entrepreneur.dig(:eligibility, :hours_worked)),
          hours_criterion_met: entrepreneur.dig(:eligibility, :hours_criterion_met)
        }.merge(entrepreneur_input_payload).merge(personal_deduction_input_payload)
      end

      def entrepreneur_input_payload
        {
          has_other_work_hours_higher_than_business: boolean_input(:has_other_work_hours_higher_than_business),
          startup_uses_in_last_5_years: startup_uses_in_last_5_years,
          disabled_starter_scheme: boolean_input(:disabled_starter_scheme),
          disabled_starter_deduction_uses: decimal_input(:disabled_starter_deduction_uses).to_i,
          has_s_and_o_declaration: boolean_input(:has_s_and_o_declaration),
          s_and_o_hours: round_currency(decimal_input(:s_and_o_hours)),
          s_and_o_starter: boolean_input(:s_and_o_starter),
          partner_unpaid_hours: round_currency(decimal_input(:partner_unpaid_hours)),
          partner_fee_paid: round_currency(decimal_input(:partner_fee_paid)),
          business_ceased: boolean_input(:business_ceased),
          cessation_profit: round_currency(decimal_input(:cessation_profit)),
          stakingsaftrek_used_before: boolean_input(:stakingsaftrek_used_before),
          private_vehicle_business_km: round_currency(decimal_input(:private_vehicle_business_km)),
          limited_deductible_costs_amount: round_currency(decimal_input(:limited_deductible_costs_amount)),
          choose_80_percent_method: boolean_input(:choose_80_percent_method),
          kia_basis: round_currency(decimal_input(:kia_basis)),
          home_workspace_independent: boolean_input(:home_workspace_independent),
          home_workspace_costs: round_currency(decimal_input(:home_workspace_costs)),
          cessation_annuity_premium: round_currency(capped_cessation_annuity_premium)
        }
      end

      def breakdown_payload(
        annual_gross_income:,
        annual_income_tax:,
        annual_net_income:,
        box_1_tax_before_credits:,
        credit_components:,
        entrepreneur:,
        personal_deductions:,
        sme_profit_exemption:,
        taxable_income_after_deductions:,
        taxable_profit:,
        total_tax:,
        total_tax_credits:,
        zvw_contribution:
      )
        {
          annual_deductible_expenses: round_currency(entrepreneur.dig(:expenses, :total)),
          expense_components: round_breakdown(entrepreneur.dig(:expenses, :components)),
          business_profit_before_reliefs: round_currency(entrepreneur.fetch(:business_profit_before_reliefs)),
          entrepreneur_eligibility: entrepreneur.fetch(:eligibility),
          entrepreneur_relief_components: round_breakdown(entrepreneur.dig(:reliefs, :components)),
          self_employed_deduction: round_currency(entrepreneur.dig(:reliefs, :components, :self_employed_deduction)),
          entrepreneur_deduction: round_currency(entrepreneur.dig(:reliefs, :entrepreneur_deduction)),
          entrepreneur_reliefs_total: round_currency(entrepreneur.dig(:reliefs, :total)),
          profit_after_self_employed_deduction: round_currency(entrepreneur.fetch(:profit_after_entrepreneur_deduction)),
          profit_after_entrepreneur_deduction: round_currency(entrepreneur.fetch(:profit_after_entrepreneur_deduction)),
          profit_after_investment_reliefs: round_currency(entrepreneur.fetch(:profit_after_investment_reliefs)),
          sme_profit_exemption: round_currency(sme_profit_exemption),
          taxable_profit: round_currency(taxable_profit),
          personal_deductions: round_currency(personal_deductions.fetch(:applied)),
          remaining_personal_deduction_carryforward: round_currency(personal_deductions.fetch(:carryforward)),
          taxable_income_after_deductions: round_currency(taxable_income_after_deductions),
          box_1_tax_before_credits: round_currency(box_1_tax_before_credits),
          **round_breakdown(credit_components),
          total_tax_credits: round_currency(total_tax_credits),
          annual_income_tax: round_currency(annual_income_tax),
          zvw_contribution: round_currency(zvw_contribution),
          total_tax: round_currency(total_tax),
          annual_net_income: round_currency(annual_net_income),
          monthly_net_income: round_currency(annual_net_income / 12),
          effective_tax_rate: round_percentage(total_tax / annual_gross_income),
          personal_deduction_components: round_breakdown(personal_deductions.fetch(:components)),
          personal_deduction_prior_carryforward: round_currency(personal_deductions.fetch(:prior_carryforward))
        }
      end

      def detail_cards(
        annual_income_tax:,
        box_1_tax_before_credits:,
        credit_components:,
        entrepreneur:,
        personal_deductions:,
        sme_profit_exemption:,
        taxable_income_after_deductions:,
        taxable_profit:,
        total_tax:,
        total_tax_credits:,
        zvw_contribution:
      )
        additional_credits = total_tax_credits -
          credit_components.fetch(:general_tax_credit) -
          credit_components.fetch(:labour_tax_credit)

        [
          { label: "Deductible expenses", value: round_currency(entrepreneur.dig(:expenses, :total)) },
          { label: "Profit before entrepreneur reliefs", value: round_currency(entrepreneur.fetch(:business_profit_before_reliefs)) },
          {
            label: "Self-employed deduction",
            value: round_currency(entrepreneur.dig(:reliefs, :components, :self_employed_deduction))
          },
          { label: "Entrepreneur reliefs", value: round_currency(entrepreneur.dig(:reliefs, :total)) },
          { label: "SME profit exemption", value: round_currency(sme_profit_exemption) },
          { label: "Taxable profit", value: round_currency(taxable_profit) },
          { label: "Personal deductions applied", value: round_currency(personal_deductions.fetch(:applied)) },
          { label: "Taxable income after deductions", value: round_currency(taxable_income_after_deductions) },
          { label: "Box 1 tax before credits", value: round_currency(box_1_tax_before_credits) },
          { label: "General tax credit", value: round_currency(credit_components.fetch(:general_tax_credit)) },
          { label: "Labour tax credit", value: round_currency(credit_components.fetch(:labour_tax_credit)) },
          { label: "Additional credits", value: round_currency(additional_credits) },
          { label: "Zvw contribution", value: round_currency(zvw_contribution) },
          { label: "Income tax after credits", value: round_currency(annual_income_tax) },
          { label: "Total tax", value: round_currency(total_tax) }
        ]
      end

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "deductible_expenses must be 0 or greater" if parsed_deductible_expenses.negative?
        errors << "deductible_expenses is too large for the current calculator" if parsed_deductible_expenses > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Netherlands self-employed regime" if regime.blank?
        errors.concat(Profile.validation_errors(age_bracket:))

        raise ValidationError.new(errors) if errors.any?
      end

      def regime
        @regime ||= find_regime(category: "self_employed", tax_year: tax_year, country: country)
      end

      def country
        @country ||= CalculationRouter.country
      end

      def metadata
        build_regime_metadata(calculator_version: "netherlands-self-employed-v1")
      end

      def assumptions(profile, entrepreneur, personal_deductions, credits)
        [
          "Netherlands, tax year #{tax_year}.",
          "Resident self-employed person in the Netherlands, nationwide calculation with no regional surtax split.",
          "Profile input: #{profile[:summary]}. Mid-year AOW transitions and pre-1946 AOW tables are not included.",
          "Entrepreneur status and hours-criterion inputs are explicit; hours criterion met: #{entrepreneur.dig(:eligibility, :hours_criterion_met)}.",
          "The calculation includes selected startersaftrek, S&O deduction, meewerkaftrek, stakingsaftrek, disability-starter deduction, KIA, mixed costs, home workspace, private-vehicle kilometres, personal deductions, fiscal-partner credit effects, and carryforward tracking.",
          "Personal deductions applied: #{round_currency(personal_deductions.fetch(:applied))}; carryforward after this calculation: #{round_currency(personal_deductions.fetch(:carryforward))}.",
          "Additional credit eligibility: #{active_credit_eligibility(credits)}.",
          "The labour tax credit uses the official arbeidsinkomen basis for entrepreneurs: profit before ondernemersaftrek and mkb-winstvrijstelling.",
          "The Zvw contribution is estimated on taxable entrepreneurial income before personal deductions, capped at the official maximum contribution income for the selected year."
        ]
      end

      def profile_data
        @profile_data ||= Profile.call(age_bracket:)
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

      def normalized_salary_period
        @normalized_salary_period ||= salary_period.to_s.upcase
      end

      def normalize_annual_gross_income
        normalized_salary_period == "MONTH" ? parsed_gross_income * 12 : parsed_gross_income
      end

      def parameter_decimal!(key)
        regime.parameter_decimal!(key)
      end

      def box_1_bracket_group(profile)
        profile[:aow_eligible] ? "box_1_aow" : "box_1_under_aow"
      end

      def personal_deduction_inputs
        calculation_inputs.merge(cessation_annuity_premium: capped_cessation_annuity_premium)
      end

      def capped_cessation_annuity_premium
        return BigDecimal("0") unless boolean_input(:business_ceased)

        [ decimal_input(:cessation_annuity_premium), ParameterReader.decimal(regime, "cessation_annuity_cap") ].min
      end

      def startup_uses_in_last_5_years
        calculation_inputs.key?(:startup_uses_in_last_5_years) ? decimal_input(:startup_uses_in_last_5_years).to_i : 3
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
