module Taxerase
  module Netherlands
    class EmployeeCalculator
      include Taxerase::Support::RegimeBackedCalculation
      include InputSupport

      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "netherlands_employee_v1".freeze
      COUNTRY_CODE = "NL".freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        age_bracket:,
        apply_thirty_percent_ruling: false,
        thirty_percent_ruling_basis: nil,
        **calculation_inputs
      )
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          age_bracket:,
          apply_thirty_percent_ruling:,
          thirty_percent_ruling_basis:,
          calculation_inputs:
        ).call
      end

      def initialize(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        age_bracket:,
        apply_thirty_percent_ruling:,
        thirty_percent_ruling_basis:,
        calculation_inputs: {}
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @age_bracket = age_bracket
        @apply_thirty_percent_ruling = apply_thirty_percent_ruling
        @thirty_percent_ruling_basis = thirty_percent_ruling_basis
        @calculation_inputs = calculation_inputs.symbolize_keys
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        thirty_percent_ruling = ThirtyPercentRuling.call(
          regime:,
          annual_gross_income:,
          apply_thirty_percent_ruling:,
          thirty_percent_ruling_basis:
        )
        taxable_employment_income = thirty_percent_ruling.fetch(:taxable_employment_income)
        profile = profile_data
        personal_deductions = PersonalDeductions.call(
          regime:,
          profile:,
          taxable_income: taxable_employment_income,
          combined_income: combined_income(taxable_employment_income),
          inputs: calculation_inputs
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
          labour_income: taxable_employment_income,
          **credit_inputs
        )
        credit_components = credits.fetch(:components)
        total_tax_credits = credits.fetch(:total)
        annual_income_tax = [
          box_1_tax_before_credits - total_tax_credits,
          0
        ].max
        total_tax = annual_income_tax
        annual_net_income = annual_gross_income - total_tax

        {
          metadata: metadata,
          input: input_payload(
            annual_gross_income:,
            taxable_employment_income:,
            thirty_percent_ruling:
          ),
          breakdown: breakdown_payload(
            annual_gross_income:,
            annual_income_tax:,
            annual_net_income:,
            box_1_tax_before_credits:,
            credit_components:,
            personal_deductions:,
            taxable_employment_income:,
            taxable_income_after_deductions:,
            thirty_percent_ruling:,
            total_tax:,
            total_tax_credits:
          ),
          detail_cards: detail_cards(
            annual_income_tax:,
            box_1_tax_before_credits:,
            credit_components:,
            personal_deductions:,
            taxable_employment_income:,
            taxable_income_after_deductions:,
            thirty_percent_ruling:,
            total_tax:,
            total_tax_credits:
          ),
          assumptions: assumptions(profile, thirty_percent_ruling, personal_deductions, credits),
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :age_bracket,
        :apply_thirty_percent_ruling, :thirty_percent_ruling_basis, :calculation_inputs

      def input_payload(annual_gross_income:, taxable_employment_income:, thirty_percent_ruling:)
        {
          gross_income: round_currency(parsed_gross_income),
          salary_period: normalized_salary_period,
          tax_year:,
          annual_gross_income: round_currency(annual_gross_income),
          monthly_gross_income: round_currency(annual_gross_income / 12),
          taxable_employment_income: round_currency(taxable_employment_income),
          age_bracket:,
          apply_thirty_percent_ruling: thirty_percent_ruling.fetch(:enabled),
          thirty_percent_ruling_basis: thirty_percent_ruling.fetch(:basis),
          **credit_input_payload
        }.merge(personal_deduction_input_payload)
      end

      def breakdown_payload(
        annual_gross_income:,
        annual_income_tax:,
        annual_net_income:,
        box_1_tax_before_credits:,
        credit_components:,
        personal_deductions:,
        taxable_employment_income:,
        taxable_income_after_deductions:,
        thirty_percent_ruling:,
        total_tax:,
        total_tax_credits:
      )
        {
          taxable_employment_income: round_currency(taxable_employment_income),
          personal_deductions: round_currency(personal_deductions.fetch(:applied)),
          remaining_personal_deduction_carryforward: round_currency(personal_deductions.fetch(:carryforward)),
          taxable_income_after_deductions: round_currency(taxable_income_after_deductions),
          thirty_percent_ruling_untaxed_allowance: round_currency(thirty_percent_ruling.fetch(:untaxed_allowance)),
          box_1_tax_before_credits: round_currency(box_1_tax_before_credits),
          **round_breakdown(credit_components),
          total_tax_credits: round_currency(total_tax_credits),
          annual_income_tax: round_currency(annual_income_tax),
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
        personal_deductions:,
        taxable_employment_income:,
        taxable_income_after_deductions:,
        thirty_percent_ruling:,
        total_tax:,
        total_tax_credits:
      )
        cards = []

        if thirty_percent_ruling.fetch(:enabled)
          cards << {
            label: "30% ruling untaxed allowance",
            value: round_currency(thirty_percent_ruling.fetch(:untaxed_allowance))
          }
        end

        additional_credits = total_tax_credits -
          credit_components.fetch(:general_tax_credit) -
          credit_components.fetch(:labour_tax_credit)

        cards + [
          { label: "Taxable employment income", value: round_currency(taxable_employment_income) },
          { label: "Personal deductions applied", value: round_currency(personal_deductions.fetch(:applied)) },
          { label: "Taxable income after deductions", value: round_currency(taxable_income_after_deductions) },
          { label: "Box 1 tax before credits", value: round_currency(box_1_tax_before_credits) },
          { label: "General tax credit", value: round_currency(credit_components.fetch(:general_tax_credit)) },
          { label: "Labour tax credit", value: round_currency(credit_components.fetch(:labour_tax_credit)) },
          { label: "Additional credits", value: round_currency(additional_credits) },
          { label: "Income tax after credits", value: round_currency(annual_income_tax) },
          { label: "Total tax", value: round_currency(total_tax) }
        ]
      end

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Netherlands employee regime" if regime.blank?
        errors.concat(Profile.validation_errors(age_bracket:))
        errors.concat(
          ThirtyPercentRuling.validation_errors(
            apply_thirty_percent_ruling:,
            thirty_percent_ruling_basis:
          )
        )

        raise ValidationError.new(errors) if errors.any?
      end

      def regime
        @regime ||= find_regime(category: "employee", tax_year: tax_year, country: country)
      end

      def country
        @country ||= CalculationRouter.country
      end

      def metadata
        build_regime_metadata(calculator_version: "netherlands-employee-v1")
      end

      def assumptions(profile, thirty_percent_ruling, personal_deductions, credits)
        base_assumptions = [
          "Netherlands, tax year #{tax_year}.",
          "Resident employee in the Netherlands, nationwide calculation with no regional surtax split.",
          "The calculation uses Box 1 resident income tax rates, tax credits, documented personal deductions, and carryforward tracking.",
          "Profile input: #{profile[:summary]}. Mid-year AOW transitions and pre-1946 AOW tables are not included.",
          "Fiscal-partner effects are included for the selected credit and deduction inputs; mortgage interest, commuting reimbursements, and non-entered deductions are not included.",
          "Personal deductions applied: #{round_currency(personal_deductions.fetch(:applied))}; carryforward after this calculation: #{round_currency(personal_deductions.fetch(:carryforward))}.",
          "Additional credit eligibility: #{active_credit_eligibility(credits)}.",
          "Standard employment income assumes the employer pays the Zvw werkgeversheffing, so no employee-paid Zvw contribution is added to the result."
        ]

        return base_assumptions unless thirty_percent_ruling.fetch(:enabled)

        base_assumptions.insert(
          4,
          thirty_percent_ruling_assumption(thirty_percent_ruling)
        )
      end

      def thirty_percent_ruling_assumption(thirty_percent_ruling)
        if thirty_percent_ruling.fetch(:untaxed_allowance).positive?
          "30% ruling applied with the #{thirty_percent_ruling.fetch(:basis_label).downcase}; untaxed allowance is #{round_currency(thirty_percent_ruling.fetch(:untaxed_allowance))}, with a salary cap of #{round_currency(thirty_percent_ruling.fetch(:salary_cap))}."
        else
          "30% ruling selected with the #{thirty_percent_ruling.fetch(:basis_label).downcase}, but no untaxed allowance was applied because the taxable salary threshold of #{round_currency(thirty_percent_ruling.fetch(:threshold))} was not exceeded."
        end
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

      def round_currency(amount)
        amount.round(2).to_f
      end

      def round_percentage(decimal)
        (decimal * 100).round(2).to_f
      end
    end
  end
end
