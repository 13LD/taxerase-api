module Taxerase
  module Poland
    class EmployeeCalculator
      include Taxerase::Support::RegimeBackedCalculation

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
      CHILD_RELIEF_HOUSEHOLD_STATUSES = %w[single married single_parent].freeze
      FILING_STATUSES = %w[individual joint_spouse single_parent].freeze

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
        include_fgsp: true,
        birth_year: nil,
        young_worker_relief_income_type: "employment",
        return_relief_prior_non_resident: false,
        return_relief_year: 0,
        working_senior_receives_pension: false,
        child_relief_household_status: "single",
        child_relief_household_income: nil,
        child_relief_claim_share: 100,
        filing_status: "individual",
        spouse_income: 0
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
          include_fgsp:,
          birth_year:,
          young_worker_relief_income_type:,
          return_relief_prior_non_resident:,
          return_relief_year:,
          working_senior_receives_pension:,
          child_relief_household_status:,
          child_relief_household_income:,
          child_relief_claim_share:,
          filing_status:,
          spouse_income:
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
        include_fgsp:,
        birth_year:,
        young_worker_relief_income_type:,
        return_relief_prior_non_resident:,
        return_relief_year:,
        working_senior_receives_pension:,
        child_relief_household_status:,
        child_relief_household_income:,
        child_relief_claim_share:,
        filing_status:,
        spouse_income:
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
        @birth_year = birth_year
        @young_worker_relief_income_type = young_worker_relief_income_type
        @return_relief_prior_non_resident = return_relief_prior_non_resident
        @return_relief_year = return_relief_year
        @working_senior_receives_pension = working_senior_receives_pension
        @child_relief_household_status = child_relief_household_status
        @child_relief_household_income = child_relief_household_income
        @child_relief_claim_share = child_relief_claim_share
        @filing_status = filing_status
        @spouse_income = spouse_income
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
        annual_income_tax_before_reliefs = annual_tax_before_child_relief(taxable_income)
        annual_child_relief = ChildRelief.call(
          regime:,
          children_count:,
          household_status: child_relief_household_status,
          household_income: resolved_child_relief_household_income(annual_gross_income),
          claim_share: child_relief_claim_share
        )
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
        :employer_accident_rate, :include_labor_fund, :include_fgsp, :birth_year,
        :young_worker_relief_income_type, :return_relief_prior_non_resident, :return_relief_year,
        :working_senior_receives_pension, :child_relief_household_status, :child_relief_household_income,
        :child_relief_claim_share, :filing_status, :spouse_income

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
          birth_year: parsed_birth_year,
          young_worker_relief_income_type: young_worker_relief_income_type.to_s.presence || "employment",
          return_relief_prior_non_resident: truthy?(return_relief_prior_non_resident),
          return_relief_year: parsed_return_relief_year,
          working_senior_receives_pension: truthy?(working_senior_receives_pension),
          child_relief_household_status: child_relief_household_status.to_s.presence || "single",
          child_relief_household_income: round_currency(parsed_child_relief_household_income),
          child_relief_claim_share: round_percentage(parsed_child_relief_claim_share),
          filing_status: filing_status.to_s.presence || "individual",
          spouse_income: round_currency(parsed_spouse_income),
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
            apply_return_relief:,
            apply_family_4plus_relief:,
            apply_working_senior_relief:,
            return_relief_prior_non_resident:,
            return_relief_year:,
            working_senior_receives_pension:,
            young_worker_relief_income_type:
          )
        )
        errors << "revenue_cost_mode must be one of: #{REVENUE_COST_MODES.join(', ')}" unless REVENUE_COST_MODES.include?(revenue_cost_mode.to_s)
        unless MONTHLY_TAX_RELIEF_MODES.include?(monthly_tax_relief_mode.to_s)
          errors << "monthly_tax_relief_mode must be one of: #{MONTHLY_TAX_RELIEF_MODES.join(', ')}"
        end
        errors << "ppk_employee_rate must be between 0 and 0.04" unless parsed_ppk_employee_rate.between?(0, 0.04)
        errors << "ppk_employer_rate must be between 0 and 0.04" unless parsed_ppk_employer_rate.between?(0, 0.04)
        errors << "employer_accident_rate must be between 0 and 0.1" unless parsed_employer_accident_rate.between?(0, 0.1)
        errors << "birth_year must be a valid year when provided" if birth_year.present? && parsed_birth_year.zero?
        unless CHILD_RELIEF_HOUSEHOLD_STATUSES.include?(child_relief_household_status.to_s)
          errors << "child_relief_household_status must be one of: #{CHILD_RELIEF_HOUSEHOLD_STATUSES.join(', ')}"
        end
        errors << "child_relief_claim_share must be between 0 and 100" unless parsed_child_relief_claim_share.between?(0, 1)
        errors << "child_relief_household_income must be 0 or greater" if parsed_child_relief_household_income.negative?
        errors << "filing_status must be one of: #{FILING_STATUSES.join(', ')}" unless FILING_STATUSES.include?(filing_status.to_s)
        errors << "spouse_income must be 0 or greater" if parsed_spouse_income.negative?

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
        build_regime_metadata(calculator_version: "poland-employment-contract-v2")
      end

      def assumptions(special_income_relief)
        assumptions = [
          "Poland, tax year #{tax_year}.",
          "Employee payroll contributions use the standard Polish employee rates for retirement, disability, sickness, and health insurance.",
          "Employer-cost cards use employer pension and disability rates, the selected accident rate, and optional Labor Fund, FGŚP, and employer PPK contributions.",
          "Revenue cost mode, PIT-2 monthly tax relief share, and PPK rates are user-selected. Copyright costs are capped at the annual statutory limit stored for the selected year.",
          "Child relief uses the selected household status, one-child household-income threshold, and claim-share percentage.",
          "Joint spouse and single-parent filing apply a simplified household quotient to the entered taxpayer income and spouse income where relevant."
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
          allow_relief_for_young: true,
          young_worker_eligible: young_worker_eligible?
        )
      end

      def annual_tax_before_child_relief(taxable_income)
        brackets = regime.brackets_for("pit_scale")

        case filing_status.to_s
        when "joint_spouse"
          quotient_tax_before_allowance((taxable_income + parsed_spouse_income) / 2, brackets)
        when "single_parent"
          quotient_tax_before_allowance(taxable_income / 2, brackets)
        else
          [ ProgressiveTax.call(amount: taxable_income, brackets:) - annual_tax_reducing_amount, 0 ].max
        end
      end

      def quotient_tax_before_allowance(quotient_income, brackets)
        [ ProgressiveTax.call(amount: quotient_income, brackets:) - annual_tax_reducing_amount, 0 ].max * 2
      end

      def young_worker_eligible?
        return age_bracket.to_s == "under_26" if parsed_birth_year.zero?

        (tax_year.to_i - parsed_birth_year) < 26 && young_worker_relief_income_type.to_s == "employment"
      end

      def resolved_child_relief_household_income(annual_gross_income)
        unless child_relief_household_income.nil? || child_relief_household_income.to_s.blank? || parsed_child_relief_household_income.zero?
          return parsed_child_relief_household_income
        end

        annual_gross_income + (child_relief_household_status.to_s == "married" ? parsed_spouse_income : BigDecimal("0"))
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

      def parsed_birth_year
        @parsed_birth_year ||= begin
          if birth_year.nil? || birth_year.to_s.blank?
            0
          else
            parsed_value = Integer(birth_year.to_s, exception: false)
            parsed_value.to_i.between?(1900, tax_year.to_i) ? parsed_value : 0
          end
        end
      end

      def parsed_return_relief_year
        @parsed_return_relief_year ||= Integer(return_relief_year.to_s, exception: false) || 0
      end

      def parsed_child_relief_household_income
        @parsed_child_relief_household_income ||= begin
          if child_relief_household_income.nil? || child_relief_household_income.to_s.blank?
            BigDecimal("0")
          else
            BigDecimal(child_relief_household_income.to_s)
          end
        end
      rescue ArgumentError
        BigDecimal("-1")
      end

      def parsed_child_relief_claim_share
        @parsed_child_relief_claim_share ||= percentage_to_decimal(child_relief_claim_share)
      end

      def parsed_spouse_income
        @parsed_spouse_income ||= BigDecimal(spouse_income.to_s)
      rescue ArgumentError
        BigDecimal("-1")
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
