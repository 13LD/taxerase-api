module Taxerase
  module Poland
    class EmployeeCalculator
      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "poland_employment_contract_v2".freeze
      COUNTRY_CODE = "PL".freeze
      REVENUE_COST_MODES = %w[normal elevated copyright none].freeze
      MONTHLY_TAX_RELIEF_MODES = %w[full half third none].freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        age_bracket:,
        children_count:,
        apply_return_relief: false,
        apply_family_4plus_relief: false,
        apply_working_senior_relief: false,
        revenue_cost_mode: "normal",
        monthly_tax_relief_mode: "full",
        ppk_employee_rate: 0,
        ppk_employer_rate: 0,
        employer_accident_rate: 1.67,
        include_labor_fund: true,
        include_fgsp: true
      )
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          age_bracket:,
          children_count:,
          apply_return_relief:,
          apply_family_4plus_relief:,
          apply_working_senior_relief:,
          revenue_cost_mode:,
          monthly_tax_relief_mode:,
          ppk_employee_rate:,
          ppk_employer_rate:,
          employer_accident_rate:,
          include_labor_fund:,
          include_fgsp:
        ).call
      end

      def initialize(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        age_bracket:,
        children_count:,
        apply_return_relief:,
        apply_family_4plus_relief:,
        apply_working_senior_relief:,
        revenue_cost_mode:,
        monthly_tax_relief_mode:,
        ppk_employee_rate:,
        ppk_employer_rate:,
        employer_accident_rate:,
        include_labor_fund:,
        include_fgsp:
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @age_bracket = age_bracket
        @children_count = children_count
        @apply_return_relief = apply_return_relief
        @apply_family_4plus_relief = apply_family_4plus_relief
        @apply_working_senior_relief = apply_working_senior_relief
        @revenue_cost_mode = revenue_cost_mode
        @monthly_tax_relief_mode = monthly_tax_relief_mode
        @ppk_employee_rate = ppk_employee_rate
        @ppk_employer_rate = ppk_employer_rate
        @employer_accident_rate = employer_accident_rate
        @include_labor_fund = include_labor_fund
        @include_fgsp = include_fgsp
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        annual_employee_social_security = annual_gross_income * employee_social_security_rate
        annual_health_contribution_base = [ annual_gross_income - annual_employee_social_security, 0 ].max
        annual_health_contribution = annual_health_contribution_base * parameter_decimal!("employee_health_rate")
        annual_employee_ppk = annual_gross_income * parsed_ppk_employee_rate
        annual_employer_ppk = annual_gross_income * parsed_ppk_employer_rate
        special_income_relief = special_income_relief_data
        annual_revenue_cost_deduction = revenue_cost_deduction_for(
          annual_gross_income: annual_gross_income,
          annual_employee_social_security: annual_employee_social_security,
          annual_employer_ppk: annual_employer_ppk
        )
        taxable_income = [
          annual_gross_income + annual_employer_ppk -
            annual_employee_social_security -
            annual_revenue_cost_deduction -
            special_income_relief.fetch(:exempt_income_cap),
          0
        ].max
        annual_income_tax_before_reliefs = [
          ProgressiveTax.call(amount: taxable_income, brackets: regime.brackets_for("pit_scale")) -
            annual_tax_reducing_amount,
          0
        ].max
        annual_child_relief = ChildRelief.call(regime:, children_count:)
        annual_income_tax = [ annual_income_tax_before_reliefs - annual_child_relief, 0 ].max
        annual_employer_social_security = annual_gross_income * employer_social_security_rate
        annual_accident_contribution = annual_gross_income * parsed_employer_accident_rate
        annual_labor_fund = truthy?(include_labor_fund) ? annual_gross_income * parameter_decimal!("labor_fund_rate") : BigDecimal("0")
        annual_fgsp = truthy?(include_fgsp) ? annual_gross_income * parameter_decimal!("fgsp_rate") : BigDecimal("0")
        annual_total_deductions = annual_employee_social_security + annual_health_contribution + annual_income_tax + annual_employee_ppk
        annual_net_income = annual_gross_income - annual_total_deductions
        annual_total_employer_cost = annual_gross_income + annual_employer_social_security + annual_accident_contribution + annual_labor_fund + annual_fgsp + annual_employer_ppk

        {
          metadata: metadata,
          input: input_payload(annual_gross_income:),
          breakdown: {
            annual_employee_social_security: round_currency(annual_employee_social_security),
            annual_health_contribution: round_currency(annual_health_contribution),
            annual_revenue_cost_deduction: round_currency(annual_revenue_cost_deduction),
            special_relief_exempt_income: round_currency(special_income_relief.fetch(:exempt_income_cap)),
            annual_taxable_income: round_currency(taxable_income),
            annual_income_tax_before_reliefs: round_currency(annual_income_tax_before_reliefs),
            annual_child_relief: round_currency(annual_child_relief),
            annual_income_tax: round_currency(annual_income_tax),
            annual_employee_ppk: round_currency(annual_employee_ppk),
            annual_employer_ppk: round_currency(annual_employer_ppk),
            annual_employer_social_security: round_currency(annual_employer_social_security),
            annual_accident_contribution: round_currency(annual_accident_contribution),
            annual_labor_fund: round_currency(annual_labor_fund),
            annual_fgsp: round_currency(annual_fgsp),
            total_tax: round_currency(annual_total_deductions),
            annual_total_employer_cost: round_currency(annual_total_employer_cost),
            annual_net_income: round_currency(annual_net_income),
            monthly_net_income: round_currency(annual_net_income / 12),
            effective_tax_rate: round_percentage(annual_total_deductions / annual_gross_income)
          },
          detail_cards: detail_cards(
            annual_accident_contribution:,
            annual_child_relief:,
            annual_employee_ppk:,
            annual_employee_social_security:,
            annual_employer_ppk:,
            annual_employer_social_security:,
            annual_fgsp:,
            annual_health_contribution:,
            annual_income_tax:,
            annual_income_tax_before_reliefs:,
            annual_labor_fund:,
            annual_revenue_cost_deduction:,
            annual_special_relief_exempt_income: special_income_relief.fetch(:exempt_income_cap),
            annual_total_deductions:,
            annual_total_employer_cost:,
            taxable_income:
          ),
          assumptions: assumptions(special_income_relief),
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :age_bracket,
        :children_count, :apply_return_relief, :apply_family_4plus_relief, :apply_working_senior_relief,
        :revenue_cost_mode, :monthly_tax_relief_mode, :ppk_employee_rate, :ppk_employer_rate,
        :employer_accident_rate, :include_labor_fund, :include_fgsp

      def input_payload(annual_gross_income:)
        {
          gross_income: round_currency(parsed_gross_income),
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
          revenue_cost_mode:,
          monthly_tax_relief_mode:,
          ppk_employee_rate: round_percentage(parsed_ppk_employee_rate),
          ppk_employer_rate: round_percentage(parsed_ppk_employer_rate),
          employer_accident_rate: round_percentage(parsed_employer_accident_rate),
          include_labor_fund: truthy?(include_labor_fund),
          include_fgsp: truthy?(include_fgsp)
        }
      end

      def detail_cards(
        annual_accident_contribution:,
        annual_child_relief:,
        annual_employee_ppk:,
        annual_employee_social_security:,
        annual_employer_ppk:,
        annual_employer_social_security:,
        annual_fgsp:,
        annual_health_contribution:,
        annual_income_tax:,
        annual_income_tax_before_reliefs:,
        annual_labor_fund:,
        annual_revenue_cost_deduction:,
        annual_special_relief_exempt_income:,
        annual_total_deductions:,
        annual_total_employer_cost:,
        taxable_income:
      )
        cards = [
          { label: "Employee social security", value: round_currency(annual_employee_social_security) },
          { label: "Health contribution", value: round_currency(annual_health_contribution) },
          { label: "Revenue cost deduction", value: round_currency(annual_revenue_cost_deduction) },
          { label: "Taxable income", value: round_currency(taxable_income) },
          { label: "Income tax before child relief", value: round_currency(annual_income_tax_before_reliefs) },
          { label: "Child relief", value: round_currency(annual_child_relief) },
          { label: "Income tax", value: round_currency(annual_income_tax) },
          { label: "Employee PPK", value: round_currency(annual_employee_ppk) },
          { label: "Employer social security", value: round_currency(annual_employer_social_security) },
          { label: "Employer accident contribution", value: round_currency(annual_accident_contribution) },
          { label: "Labor Fund", value: round_currency(annual_labor_fund) },
          { label: "FGŚP", value: round_currency(annual_fgsp) },
          { label: "Employer PPK", value: round_currency(annual_employer_ppk) },
          { label: "Total employee deductions", value: round_currency(annual_total_deductions) },
          { label: "Total employer cost", value: round_currency(annual_total_employer_cost) }
        ]

        if annual_special_relief_exempt_income.positive?
          cards.insert(3, { label: "Special PIT exemption income", value: round_currency(annual_special_relief_exempt_income) })
        end

        cards
      end

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Poland employment regime" if regime.blank?
        errors.concat(
          SpecialIncomeRelief.validation_errors_for(
            age_bracket:,
            children_count:,
            apply_family_4plus_relief:,
            apply_working_senior_relief:
          )
        )
        errors << "revenue_cost_mode must be one of: #{REVENUE_COST_MODES.join(', ')}" unless REVENUE_COST_MODES.include?(revenue_cost_mode.to_s)
        unless MONTHLY_TAX_RELIEF_MODES.include?(monthly_tax_relief_mode.to_s)
          errors << "monthly_tax_relief_mode must be one of: #{MONTHLY_TAX_RELIEF_MODES.join(', ')}"
        end
        errors << "ppk_employee_rate must be between 0 and 0.04" unless parsed_ppk_employee_rate.between?(0, 0.04)
        errors << "ppk_employer_rate must be between 0 and 0.04" unless parsed_ppk_employer_rate.between?(0, 0.04)
        errors << "employer_accident_rate must be between 0 and 0.1" unless parsed_employer_accident_rate.between?(0, 0.1)

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
          category: "employee"
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
          calculator_version: "poland-employment-contract-v2"
        }
      end

      def assumptions(special_income_relief)
        assumptions = [
          "Poland employment contract only, tax year #{tax_year}.",
          "Employee payroll contributions use the standard Polish employee rates for retirement, disability, sickness, and health insurance.",
          "Employer-cost cards use employer pension and disability rates, the selected accident rate, and optional Labor Fund, FGŚP, and employer PPK contributions.",
          "Revenue cost mode, PIT-2 monthly tax relief share, and PPK rates are user-selected. Copyright costs are capped at the annual statutory limit stored for the selected year.",
          "Child relief is applied against annual PIT only. Joint filing, one-child income-threshold tests, and custody-allocation edge cases are still out of scope."
        ]

        return assumptions if special_income_relief.fetch(:enabled_reliefs).empty?

        assumptions << "Special PIT exemption applied for: #{special_income_relief.fetch(:enabled_reliefs).join(', ')}. The shared annual cap is #{round_currency(special_income_relief.fetch(:exempt_income_cap))}."
      end

      def special_income_relief_data
        @special_income_relief_data ||= SpecialIncomeRelief.call(
          regime:,
          age_bracket:,
          apply_return_relief:,
          apply_family_4plus_relief:,
          apply_working_senior_relief:,
          allow_relief_for_young: true
        )
      end

      def employee_social_security_rate
        parameter_decimal!("employee_pension_rate") +
          parameter_decimal!("employee_disability_rate") +
          parameter_decimal!("employee_sickness_rate")
      end

      def employer_social_security_rate
        parameter_decimal!("employer_pension_rate") + parameter_decimal!("employer_disability_rate")
      end

      def revenue_cost_deduction_for(annual_gross_income:, annual_employee_social_security:, annual_employer_ppk:)
        case revenue_cost_mode.to_s
        when "normal"
          parameter_decimal!("annual_employee_cost_normal")
        when "elevated"
          parameter_decimal!("annual_employee_cost_elevated")
        when "copyright"
          deduction_base = [ annual_gross_income + annual_employer_ppk - annual_employee_social_security, 0 ].max
          [ deduction_base * BigDecimal("0.5"), parameter_decimal!("annual_copyright_cost_cap") ].min
        else
          BigDecimal("0")
        end
      end

      def annual_tax_reducing_amount
        case monthly_tax_relief_mode.to_s
        when "full"
          parameter_decimal!("annual_tax_reducing_amount")
        when "half"
          parameter_decimal!("annual_tax_reducing_amount") / 2
        when "third"
          parameter_decimal!("annual_tax_reducing_amount") / 3
        else
          BigDecimal("0")
        end
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

      def parsed_ppk_employee_rate
        @parsed_ppk_employee_rate ||= percentage_to_decimal(ppk_employee_rate)
      end

      def parsed_ppk_employer_rate
        @parsed_ppk_employer_rate ||= percentage_to_decimal(ppk_employer_rate)
      end

      def parsed_employer_accident_rate
        @parsed_employer_accident_rate ||= percentage_to_decimal(employer_accident_rate)
      end

      def percentage_to_decimal(value)
        BigDecimal(value.to_s) / 100
      rescue ArgumentError
        BigDecimal("-1")
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
