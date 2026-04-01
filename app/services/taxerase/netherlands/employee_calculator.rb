module Taxerase
  module Netherlands
    class EmployeeCalculator
      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "netherlands_employee_v1".freeze
      COUNTRY_CODE = "NL".freeze

      def self.call(gross_income:, salary_period:, tax_regime_key:, tax_year:, age_bracket:)
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          age_bracket:
        ).call
      end

      def initialize(gross_income:, salary_period:, tax_regime_key:, tax_year:, age_bracket:)
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @age_bracket = age_bracket
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        profile = profile_data
        box_1_tax_before_credits = ProgressiveTax.call(
          amount: annual_gross_income,
          brackets: regime.brackets_for(box_1_bracket_group(profile))
        )
        general_tax_credit = FormulaBrackets.call(
          regime:,
          bracket_group: general_tax_credit_group(profile),
          amount: annual_gross_income
        )
        labour_tax_credit = FormulaBrackets.call(
          regime:,
          bracket_group: labour_tax_credit_group(profile),
          amount: annual_gross_income
        )
        annual_income_tax = [
          box_1_tax_before_credits - general_tax_credit - labour_tax_credit,
          0
        ].max
        total_tax = annual_income_tax
        annual_net_income = annual_gross_income - total_tax

        {
          metadata: metadata,
          input: {
            gross_income: round_currency(parsed_gross_income),
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
            taxable_employment_income: round_currency(annual_gross_income),
            box_1_tax_before_credits: round_currency(box_1_tax_before_credits),
            general_tax_credit: round_currency(general_tax_credit),
            labour_tax_credit: round_currency(labour_tax_credit),
            annual_income_tax: round_currency(annual_income_tax),
            total_tax: round_currency(total_tax),
            annual_net_income: round_currency(annual_net_income),
            monthly_net_income: round_currency(annual_net_income / 12),
            effective_tax_rate: round_percentage(total_tax / annual_gross_income)
          },
          detail_cards: [
            { label: "Taxable employment income", value: round_currency(annual_gross_income) },
            { label: "Box 1 tax before credits", value: round_currency(box_1_tax_before_credits) },
            { label: "General tax credit", value: round_currency(general_tax_credit) },
            { label: "Labour tax credit", value: round_currency(labour_tax_credit) },
            { label: "Income tax after credits", value: round_currency(annual_income_tax) },
            { label: "Total tax", value: round_currency(total_tax) }
          ],
          assumptions: assumptions(profile),
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :age_bracket

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 2_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Netherlands employee regime" if regime.blank?
        errors.concat(Profile.validation_errors(age_bracket:))

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
          calculator_version: "netherlands-employee-v1"
        }
      end

      def assumptions(profile)
        [
          "Netherlands only, tax year #{tax_year}.",
          "Resident employee in the Netherlands, nationwide calculation with no regional surtax split.",
          "The calculation uses Box 1 resident income tax rates, the general tax credit, and the labour tax credit.",
          "Profile input: #{profile[:summary]}. Mid-year AOW transitions and pre-1946 AOW tables are not included.",
          "No fiscal partner, mortgage interest, pension deductions, 30% ruling, commuting reimbursements, or other deductions and credits are included.",
          "Standard employment income assumes the employer pays the Zvw werkgeversheffing, so no employee-paid Zvw contribution is added to the result."
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

      def normalized_salary_period
        @normalized_salary_period ||= salary_period.to_s.upcase
      end

      def normalize_annual_gross_income
        normalized_salary_period == "MONTH" ? parsed_gross_income * 12 : parsed_gross_income
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

      def round_currency(amount)
        amount.round(2).to_f
      end

      def round_percentage(decimal)
        (decimal * 100).round(2).to_f
      end
    end
  end
end
