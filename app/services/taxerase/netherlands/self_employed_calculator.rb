module Taxerase
  module Netherlands
    class SelfEmployedCalculator
      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "netherlands_self_employed_v1".freeze
      COUNTRY_CODE = "NL".freeze

      def self.call(gross_income:, salary_period:, tax_regime_key:, tax_year:, deductible_expenses:, age_bracket:)
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          deductible_expenses:,
          age_bracket:
        ).call
      end

      def initialize(gross_income:, salary_period:, tax_regime_key:, tax_year:, deductible_expenses:, age_bracket:)
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @deductible_expenses = deductible_expenses
        @age_bracket = age_bracket
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        annual_deductible_expenses = parsed_deductible_expenses
        business_profit_before_reliefs = [ annual_gross_income - annual_deductible_expenses, 0 ].max
        profile = profile_data
        self_employed_deduction = [ business_profit_before_reliefs, self_employed_deduction_amount(profile) ].min
        profit_after_self_employed_deduction = [ business_profit_before_reliefs - self_employed_deduction, 0 ].max
        sme_profit_exemption = profit_after_self_employed_deduction * parameter_decimal!("sme_profit_exemption_rate")
        taxable_profit = [ profit_after_self_employed_deduction - sme_profit_exemption, 0 ].max
        box_1_tax_before_credits = ProgressiveTax.call(
          amount: taxable_profit,
          brackets: regime.brackets_for(box_1_bracket_group(profile))
        )
        general_tax_credit = FormulaBrackets.call(
          regime:,
          bracket_group: general_tax_credit_group(profile),
          amount: taxable_profit
        )
        labour_tax_credit = FormulaBrackets.call(
          regime:,
          bracket_group: labour_tax_credit_group(profile),
          amount: business_profit_before_reliefs
        )
        annual_income_tax = [
          box_1_tax_before_credits - general_tax_credit - labour_tax_credit,
          0
        ].max
        zvw_contribution = [
          taxable_profit,
          parameter_decimal!("zvw_max_contribution_income")
        ].min * parameter_decimal!("zvw_self_assessed_rate")
        total_tax = annual_income_tax + zvw_contribution
        annual_net_income = annual_gross_income - annual_deductible_expenses - total_tax

        {
          metadata: metadata,
          input: {
            gross_income: round_currency(parsed_gross_income),
            deductible_expenses: round_currency(annual_deductible_expenses),
            salary_period: normalized_salary_period,
            tax_year:,
            annual_gross_income: round_currency(annual_gross_income),
            monthly_gross_income: round_currency(annual_gross_income / 12),
            age_bracket:,
            children_count: 0,
            children_under_three_count: 0,
            disability_level: "none"
          },
          breakdown: {
            annual_deductible_expenses: round_currency(annual_deductible_expenses),
            business_profit_before_reliefs: round_currency(business_profit_before_reliefs),
            self_employed_deduction: round_currency(self_employed_deduction),
            profit_after_self_employed_deduction: round_currency(profit_after_self_employed_deduction),
            sme_profit_exemption: round_currency(sme_profit_exemption),
            taxable_profit: round_currency(taxable_profit),
            box_1_tax_before_credits: round_currency(box_1_tax_before_credits),
            general_tax_credit: round_currency(general_tax_credit),
            labour_tax_credit: round_currency(labour_tax_credit),
            annual_income_tax: round_currency(annual_income_tax),
            zvw_contribution: round_currency(zvw_contribution),
            total_tax: round_currency(total_tax),
            annual_net_income: round_currency(annual_net_income),
            monthly_net_income: round_currency(annual_net_income / 12),
            effective_tax_rate: round_percentage(total_tax / annual_gross_income)
          },
          detail_cards: [
            { label: "Deductible expenses", value: round_currency(annual_deductible_expenses) },
            { label: "Profit before entrepreneur reliefs", value: round_currency(business_profit_before_reliefs) },
            { label: "Self-employed deduction", value: round_currency(self_employed_deduction) },
            { label: "SME profit exemption", value: round_currency(sme_profit_exemption) },
            { label: "Taxable profit", value: round_currency(taxable_profit) },
            { label: "Box 1 tax before credits", value: round_currency(box_1_tax_before_credits) },
            { label: "General tax credit", value: round_currency(general_tax_credit) },
            { label: "Labour tax credit", value: round_currency(labour_tax_credit) },
            { label: "Zvw contribution", value: round_currency(zvw_contribution) },
            { label: "Total tax", value: round_currency(total_tax) }
          ],
          assumptions: assumptions(profile),
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :deductible_expenses, :age_bracket

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
        @regime ||= TaxRegime.includes(:country, :tax_brackets, :tax_parameters, tax_source_usages: :official_tax_source).find_by(
          country:,
          key: tax_regime_key,
          tax_year:,
          category: "self_employed"
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
          calculator_version: "netherlands-self-employed-v1"
        }
      end

      def assumptions(profile)
        [
          "Netherlands, tax year #{tax_year}.",
          "Resident self-employed person in the Netherlands, nationwide calculation with no regional surtax split.",
          "Profile input: #{profile[:summary]}. Mid-year AOW transitions and pre-1946 AOW tables are not included.",
          "The calculation assumes you qualify as an entrepreneur for Dutch income tax and satisfy the hours criterion, so the zelfstandigenaftrek is applied.",
          "No startersaftrek, S&O deduction, meewerkaftrek, stakingsaftrek, fiscal partner effects, mortgage interest, or other deductions and credits are included.",
          "The labour tax credit uses the official arbeidsinkomen basis for entrepreneurs: profit before ondernemersaftrek and mkb-winstvrijstelling.",
          "The Zvw contribution is estimated on the taxable entrepreneurial income in Box 1, capped at the official maximum contribution income for the selected year."
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

      def general_tax_credit_group(profile)
        profile[:aow_eligible] ? "general_tax_credit_aow" : "general_tax_credit_under_aow"
      end

      def labour_tax_credit_group(profile)
        profile[:aow_eligible] ? "labour_tax_credit_aow" : "labour_tax_credit_under_aow"
      end

      def self_employed_deduction_amount(profile)
        key = profile[:aow_eligible] ? "self_employed_deduction_aow" : "self_employed_deduction_under_aow"
        parameter_decimal!(key)
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
