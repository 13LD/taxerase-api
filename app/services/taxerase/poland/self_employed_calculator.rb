module Taxerase
  module Poland
    class SelfEmployedCalculator
      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "poland_b2b_contract_v2".freeze
      COUNTRY_CODE = "PL".freeze
      B2B_TAX_FORMS = %w[tax_scale flat_tax lump_sum].freeze
      SOCIAL_INSURANCE_MODES = %w[start_relief preferential small_zus_plus standard].freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        deductible_expenses:,
        age_bracket:,
        children_count:,
        apply_return_relief: false,
        apply_family_4plus_relief: false,
        apply_working_senior_relief: false,
        b2b_tax_form: "tax_scale",
        lump_sum_rate: 12,
        social_insurance_mode: "standard",
        include_sickness_contribution: true,
        business_days_in_month: 30,
        previous_year_average_monthly_income: 12_000
      )
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          deductible_expenses:,
          age_bracket:,
          children_count:,
          apply_return_relief:,
          apply_family_4plus_relief:,
          apply_working_senior_relief:,
          b2b_tax_form:,
          lump_sum_rate:,
          social_insurance_mode:,
          include_sickness_contribution:,
          business_days_in_month:,
          previous_year_average_monthly_income:
        ).call
      end

      def initialize(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        deductible_expenses:,
        age_bracket:,
        children_count:,
        apply_return_relief:,
        apply_family_4plus_relief:,
        apply_working_senior_relief:,
        b2b_tax_form:,
        lump_sum_rate:,
        social_insurance_mode:,
        include_sickness_contribution:,
        business_days_in_month:,
        previous_year_average_monthly_income:
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @deductible_expenses = deductible_expenses
        @age_bracket = age_bracket
        @children_count = children_count
        @apply_return_relief = apply_return_relief
        @apply_family_4plus_relief = apply_family_4plus_relief
        @apply_working_senior_relief = apply_working_senior_relief
        @b2b_tax_form = b2b_tax_form
        @lump_sum_rate = lump_sum_rate
        @social_insurance_mode = social_insurance_mode
        @include_sickness_contribution = include_sickness_contribution
        @business_days_in_month = business_days_in_month
        @previous_year_average_monthly_income = previous_year_average_monthly_income
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        annual_deductible_expenses = parsed_deductible_expenses
        annual_social_security = annual_social_security_contribution
        annual_business_income_before_tax = [ annual_gross_income - annual_deductible_expenses - annual_social_security, 0 ].max
        special_income_relief = special_income_relief_data
        annual_health_contribution = annual_health_contribution_for(
          annual_business_income_before_tax:,
          annual_gross_income:
        )
        annual_taxable_income = taxable_income_for(
          annual_business_income_before_tax:,
          annual_gross_income:,
          annual_social_security:,
          special_income_relief:
        )
        annual_income_tax_before_reliefs = income_tax_before_reliefs_for(annual_taxable_income)
        annual_child_relief = b2b_tax_form.to_s == "tax_scale" ? ChildRelief.call(regime:, children_count:) : BigDecimal("0")
        annual_income_tax = [ annual_income_tax_before_reliefs - annual_child_relief, 0 ].max
        annual_total_tax = annual_social_security + annual_health_contribution + annual_income_tax
        annual_net_income = annual_gross_income - annual_deductible_expenses - annual_total_tax

        {
          metadata: metadata,
          input: input_payload(annual_gross_income:, annual_deductible_expenses:),
          breakdown: {
            annual_deductible_expenses: round_currency(annual_deductible_expenses),
            annual_social_security: round_currency(annual_social_security),
            annual_health_contribution: round_currency(annual_health_contribution),
            special_relief_exempt_income: round_currency(special_income_relief.fetch(:exempt_income_cap)),
            annual_taxable_income: round_currency(annual_taxable_income),
            annual_income_tax_before_reliefs: round_currency(annual_income_tax_before_reliefs),
            annual_child_relief: round_currency(annual_child_relief),
            annual_income_tax: round_currency(annual_income_tax),
            total_tax: round_currency(annual_total_tax),
            annual_net_income: round_currency(annual_net_income),
            monthly_net_income: round_currency(annual_net_income / 12),
            effective_tax_rate: round_percentage(annual_total_tax / annual_gross_income)
          },
          detail_cards: detail_cards(
            annual_deductible_expenses:,
            annual_health_contribution:,
            annual_income_tax:,
            annual_income_tax_before_reliefs:,
            annual_social_security:,
            annual_taxable_income:,
            annual_total_tax:,
            annual_child_relief:
          ),
          assumptions: assumptions(special_income_relief),
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :deductible_expenses,
        :age_bracket, :children_count, :apply_return_relief, :apply_family_4plus_relief,
        :apply_working_senior_relief, :b2b_tax_form, :lump_sum_rate, :social_insurance_mode,
        :include_sickness_contribution, :business_days_in_month,
        :previous_year_average_monthly_income

      def input_payload(annual_gross_income:, annual_deductible_expenses:)
        {
          gross_income: round_currency(parsed_gross_income),
          deductible_expenses: round_currency(annual_deductible_expenses),
          salary_period: normalized_salary_period,
          tax_year:,
          annual_gross_income: round_currency(annual_gross_income),
          monthly_gross_income: round_currency(annual_gross_income / 12),
          age_bracket:,
          children_count: parsed_children_count,
          children_under_three_count: 0,
          disability_level: "none",
          apply_return_relief: truthy?(apply_return_relief),
          apply_family_4plus_relief: truthy?(apply_family_4plus_relief),
          apply_working_senior_relief: truthy?(apply_working_senior_relief),
          b2b_tax_form:,
          lump_sum_rate: round_percentage(parsed_lump_sum_rate),
          social_insurance_mode:,
          include_sickness_contribution: truthy?(include_sickness_contribution),
          business_days_in_month: parsed_business_days_in_month,
          previous_year_average_monthly_income: round_currency(parsed_previous_year_average_monthly_income)
        }
      end

      def detail_cards(
        annual_deductible_expenses:,
        annual_health_contribution:,
        annual_income_tax:,
        annual_income_tax_before_reliefs:,
        annual_social_security:,
        annual_taxable_income:,
        annual_total_tax:,
        annual_child_relief:
      )
        cards = [
          { label: "Deductible expenses", value: round_currency(annual_deductible_expenses) },
          { label: "ZUS social contributions", value: round_currency(annual_social_security) },
          { label: "Health contribution", value: round_currency(annual_health_contribution) },
          { label: "Taxable income", value: round_currency(annual_taxable_income) },
          { label: "Income tax before reliefs", value: round_currency(annual_income_tax_before_reliefs) },
          { label: "Child relief", value: round_currency(annual_child_relief) },
          { label: "Income tax", value: round_currency(annual_income_tax) },
          { label: "Total tax", value: round_currency(annual_total_tax) }
        ]

        cards.insert(3, { label: "Special PIT exemption income", value: round_currency(special_income_relief_data.fetch(:exempt_income_cap)) }) if special_income_relief_data.fetch(:enabled_reliefs).any?
        cards
      end

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "deductible_expenses must be 0 or greater" if parsed_deductible_expenses.negative?
        errors << "deductible_expenses is too large for the current calculator" if parsed_deductible_expenses > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Poland B2B regime" if regime.blank?
        errors.concat(
          SpecialIncomeRelief.validation_errors_for(
            age_bracket:,
            children_count:,
            apply_family_4plus_relief:,
            apply_working_senior_relief:
          )
        )
        errors << "b2b_tax_form must be one of: #{B2B_TAX_FORMS.join(', ')}" unless B2B_TAX_FORMS.include?(b2b_tax_form.to_s)
        unless SOCIAL_INSURANCE_MODES.include?(social_insurance_mode.to_s)
          errors << "social_insurance_mode must be one of: #{SOCIAL_INSURANCE_MODES.join(', ')}"
        end
        errors << "lump_sum_rate must be between 0 and 0.5" unless parsed_lump_sum_rate.between?(0, 0.5)
        errors << "business_days_in_month must be between 1 and 31" unless parsed_business_days_in_month.between?(1, 31)
        if parsed_previous_year_average_monthly_income.negative?
          errors << "previous_year_average_monthly_income must be 0 or greater"
        end

        parsed_children_count

        raise ValidationError.new(errors) if errors.any?
      rescue ArgumentError
        raise ValidationError.new(errors + [ "children_count must be 0 or greater" ])
      end

      def regime
        @regime ||= TaxRegime
          .with_rule_data
          .for_country_year(country:, tax_year:)
          .find_by(key: tax_regime_key, category: "self_employed")
      end

      def country
        @country ||= CalculationRouter.country
      end

      def metadata
        {
          country_code: regime.country.code,
          country_name: regime.country.name,
          region: regime.region,
          tax_year: regime.tax_year,
          tax_regime_key: regime.key,
          tax_regime_name: regime.name,
          calculator_version: "poland-b2b-contract-v2"
        }
      end

      def assumptions(special_income_relief)
        assumptions = [
          "Poland, tax year #{tax_year}.",
          "Tax form can be tax scale, flat tax, or lump sum. Child relief is currently modeled only for the tax-scale path.",
          "ZUS social contributions use the selected relief path: start relief, preferential, Small ZUS Plus, or standard full ZUS. Small ZUS Plus uses 50% of the prior-year average monthly income, clamped to the official min and max bases.",
          "For monthly estimates, fixed B2B contributions are prorated by business days as a simple approximation."
        ]

        return assumptions if special_income_relief.fetch(:enabled_reliefs).empty?

        assumptions << "Special PIT exemption applied for: #{special_income_relief.fetch(:enabled_reliefs).join(', ')}. The shared annual cap is #{round_currency(special_income_relief.fetch(:exempt_income_cap))}."
      end

      def taxable_income_for(annual_business_income_before_tax:, annual_gross_income:, annual_social_security:, special_income_relief:)
        case b2b_tax_form.to_s
        when "lump_sum"
          [ annual_gross_income - annual_social_security - special_income_relief.fetch(:exempt_income_cap), 0 ].max
        else
          [ annual_business_income_before_tax - special_income_relief.fetch(:exempt_income_cap), 0 ].max
        end
      end

      def income_tax_before_reliefs_for(annual_taxable_income)
        case b2b_tax_form.to_s
        when "tax_scale"
          [ ProgressiveTax.call(amount: annual_taxable_income, brackets: regime.brackets_for("pit_scale")) - parameter_decimal!("annual_tax_reducing_amount"), 0 ].max
        when "flat_tax"
          annual_taxable_income * parameter_decimal!("flat_tax_rate")
        else
          annual_taxable_income * parsed_lump_sum_rate
        end
      end

      def annual_health_contribution_for(annual_business_income_before_tax:, annual_gross_income:)
        if b2b_tax_form.to_s == "lump_sum"
          annual_lump_sum_health_contribution(annual_gross_income)
        else
          rate = b2b_tax_form.to_s == "flat_tax" ? parameter_decimal!("flat_tax_health_rate") : parameter_decimal!("tax_scale_health_rate")
          raw_contribution = annual_business_income_before_tax * rate
          [ raw_contribution, annual_general_health_minimum ].max
        end
      end

      def annual_lump_sum_health_contribution(annual_gross_income)
        monthly_base =
          if annual_gross_income <= parameter_decimal!("lump_sum_health_threshold_low")
            parameter_decimal!("monthly_lump_sum_health_base_low")
          elsif annual_gross_income <= parameter_decimal!("lump_sum_health_threshold_mid")
            parameter_decimal!("monthly_lump_sum_health_base_mid")
          else
            parameter_decimal!("monthly_lump_sum_health_base_high")
          end

        monthly_base * parameter_decimal!("tax_scale_health_rate") * 12 * monthly_business_days_factor
      end

      def annual_general_health_minimum
        parameter_decimal!("monthly_general_health_minimum") * 12
      end

      def annual_social_security_contribution
        return BigDecimal("0") if social_insurance_mode.to_s == "start_relief"

        monthly_rate = parameter_decimal!("zus_pension_rate") +
          parameter_decimal!("zus_disability_rate") +
          parameter_decimal!("zus_accident_rate")
        monthly_rate += parameter_decimal!("zus_sickness_rate") if truthy?(include_sickness_contribution)

        monthly_social = social_contribution_base * monthly_rate
        monthly_social += social_contribution_base * parameter_decimal!("labor_fund_rate") if include_b2b_labor_fund?
        monthly_social * 12 * monthly_business_days_factor
      end

      def social_contribution_base
        case social_insurance_mode.to_s
        when "preferential"
          parameter_decimal!("monthly_preferential_social_base")
        when "small_zus_plus"
          candidate_base = parsed_previous_year_average_monthly_income * BigDecimal("0.5")
          [
            [ candidate_base, parameter_decimal!("monthly_small_zus_plus_max_base") ].min,
            parameter_decimal!("monthly_small_zus_plus_min_base")
          ].max
        else
          parameter_decimal!("monthly_standard_social_base")
        end
      end

      def include_b2b_labor_fund?
        return false if %w[start_relief preferential].include?(social_insurance_mode.to_s)

        social_contribution_base >= parameter_decimal!("monthly_minimum_wage")
      end

      def special_income_relief_data
        @special_income_relief_data ||= SpecialIncomeRelief.call(
          regime:,
          age_bracket:,
          apply_return_relief:,
          apply_family_4plus_relief:,
          apply_working_senior_relief:,
          allow_relief_for_young: false
        )
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
        @parsed_children_count ||= begin
          parsed_value = Integer(children_count.to_s, exception: false)
          raise ArgumentError if parsed_value.nil? || parsed_value.negative?

          parsed_value
        end
      end

      def parsed_lump_sum_rate
        @parsed_lump_sum_rate ||= percentage_to_decimal(lump_sum_rate)
      end

      def parsed_business_days_in_month
        @parsed_business_days_in_month ||= Integer(business_days_in_month.to_s, exception: false) || 0
      end

      def parsed_previous_year_average_monthly_income
        @parsed_previous_year_average_monthly_income ||= BigDecimal(previous_year_average_monthly_income.to_s)
      rescue ArgumentError
        BigDecimal("-1")
      end

      def percentage_to_decimal(value)
        BigDecimal(value.to_s) / 100
      rescue ArgumentError
        BigDecimal("-1")
      end

      def monthly_business_days_factor
        return BigDecimal("1") unless normalized_salary_period == "MONTH"

        BigDecimal(parsed_business_days_in_month.to_s) / BigDecimal("30")
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

      def truthy?(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end

      def round_currency(amount)
        BigDecimal(amount.to_s).round(2).to_f
      end

      def round_percentage(decimal)
        (BigDecimal(decimal.to_s) * 100).round(2).to_f
      end
    end
  end
end
