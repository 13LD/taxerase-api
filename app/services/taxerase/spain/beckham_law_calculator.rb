module Taxerase
  module Spain
    class BeckhamLawCalculator
      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "spain_beckham_law_v1".freeze
      COUNTRY_CODE = "ES".freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        age_bracket:,
        children_count:,
        children_under_three_count:,
        disability_level:
      )
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          age_bracket:,
          children_count:,
          children_under_three_count:,
          disability_level:
        ).call
      end

      def initialize(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        age_bracket:,
        children_count:,
        children_under_three_count:,
        disability_level:
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @age_bracket = age_bracket
        @children_count = children_count
        @children_under_three_count = children_under_three_count
        @disability_level = disability_level
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        monthly_gross_income = annual_gross_income / 12
        contribution_base_monthly = monthly_contribution_base_for(monthly_gross_income)
        annual_social_security = contribution_base_monthly * 12 * parameter_decimal!("employee_social_security_rate")
        taxable_employment_income = annual_gross_income
        annual_income_tax = ProgressiveTax.call(
          amount: taxable_employment_income,
          brackets: regime.brackets_for("employment_income")
        )
        total_tax = annual_income_tax + annual_social_security
        annual_net_income = annual_gross_income - total_tax

        {
          metadata: metadata,
          input: {
            gross_income: round_currency(parsed_gross_income),
            salary_period: normalized_salary_period,
            tax_year: tax_year,
            annual_gross_income: round_currency(annual_gross_income),
            monthly_gross_income: round_currency(monthly_gross_income),
            age_bracket: age_bracket,
            children_count: children_count.to_i,
            children_under_three_count: children_under_three_count.to_i,
            disability_level: disability_level.presence || "none"
          },
          breakdown: {
            annual_social_security: round_currency(annual_social_security),
            taxable_employment_income: round_currency(taxable_employment_income),
            annual_income_tax: round_currency(annual_income_tax),
            total_tax: round_currency(total_tax),
            annual_net_income: round_currency(annual_net_income),
            monthly_net_income: round_currency(annual_net_income / 12),
            effective_tax_rate: round_percentage(total_tax / annual_gross_income)
          },
          detail_cards: [
            { label: "Beckham Law income tax", value: round_currency(annual_income_tax) },
            { label: "Employee social security", value: round_currency(annual_social_security) },
            { label: "Total tax", value: round_currency(total_tax) },
            { label: "Taxable employment income", value: round_currency(taxable_employment_income) },
            { label: "Monthly Social Security contribution base", value: round_currency(contribution_base_monthly) }
          ],
          assumptions: assumptions,
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :age_bracket,
        :children_count, :children_under_three_count, :disability_level

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Beckham Law regime" if regime.blank?

        raise ValidationError.new(errors) if errors.any?
      end

      def regime
        @regime ||= TaxRegime
          .with_rule_data
          .for_country_year(country:, tax_year: tax_year)
          .find_by(key: tax_regime_key, category: "special_regime")
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
          calculator_version: "spain-beckham-law-v1"
        }
      end

      def assumptions
        [
          "Spain, tax year #{tax_year}.",
          "Beckham Law / Article 93 special regime for eligible inbound workers in #{regime.region}.",
          "This calculator applies the national special-regime employment scale: 24% up to €600,000 and 47% above €600,000.",
          "The region selector is kept for jurisdiction browsing, but the Article 93 employment-income calculation is national and does not use regional IRPF scales or regional personal minimums.",
          "Standard employee Social Security is still applied using the official worker rates and contribution bases stored for the selected year.",
          "Age, children, disability, work-income reductions, and resident personal-and-family minimums do not reduce the Beckham Law tax in this calculator.",
          "This slice models employment income only. Savings/investment income under Modelo 151 and eligibility checks for opting into the regime via Modelo 149 are not calculated."
        ]
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

      def parameter_decimal!(key)
        regime.parameter_decimal!(key)
      end

      def monthly_contribution_base_for(monthly_gross_income)
        return BigDecimal("0") if monthly_gross_income <= 0

        min_base = parameter_decimal!("monthly_min_contribution_base")
        max_base = parameter_decimal!("monthly_max_contribution_base")

        [ [ monthly_gross_income, max_base ].min, min_base ].max
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
