module Taxerase
  module Portugal
    class EmployeeCalculator
      include Taxerase::Support::RegimeBackedCalculation

      include CalculatorSupport

      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "portugal_employee_v1".freeze
      COUNTRY_CODE = "PT".freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        children_count:,
        children_under_three_count:,
        disability_level:,
        ascendants_count: 0,
        general_family_expenses: 0,
        health_expenses: 0,
        education_expenses: 0,
        housing_rent: 0,
        alimony_paid: 0,
        care_home_expenses: 0,
        domestic_work_expenses: 0,
        young_dependents_second_later_under_six_count: 0,
        vat_invoice_expenses: 0,
        vat_invoice_validation_state: "not_validated",
        disability_rehabilitation_expenses: 0,
        disability_insurance_premiums: 0,
        ppr_contributions: 0,
        ppr_age_band: "under_35",
        donations: 0,
        filing_status: "individual",
        apply_irs_jovem: false,
        irs_jovem_year: 0,
        union_dues: 0,
        professional_order_dues: 0
      )
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          children_count:,
          children_under_three_count:,
          disability_level:,
          ascendants_count:,
          general_family_expenses:,
          health_expenses:,
          education_expenses:,
          housing_rent:,
          alimony_paid:,
          care_home_expenses:,
          domestic_work_expenses:,
          young_dependents_second_later_under_six_count:,
          vat_invoice_expenses:,
          vat_invoice_validation_state:,
          disability_rehabilitation_expenses:,
          disability_insurance_premiums:,
          ppr_contributions:,
          ppr_age_band:,
          donations:,
          filing_status:,
          apply_irs_jovem:,
          irs_jovem_year:,
          union_dues:,
          professional_order_dues:
        ).call
      end

      def initialize(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        children_count:,
        children_under_three_count:,
        disability_level:,
        ascendants_count:,
        general_family_expenses:,
        health_expenses:,
        education_expenses:,
        housing_rent:,
        alimony_paid:,
        care_home_expenses:,
        domestic_work_expenses:,
        young_dependents_second_later_under_six_count:,
        vat_invoice_expenses:,
        vat_invoice_validation_state:,
        disability_rehabilitation_expenses:,
        disability_insurance_premiums:,
        ppr_contributions:,
        ppr_age_band:,
        donations:,
        filing_status:,
        apply_irs_jovem:,
        irs_jovem_year:,
        union_dues:,
        professional_order_dues:
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @children_count = children_count
        @children_under_three_count = children_under_three_count
        @disability_level = disability_level
        @ascendants_count = ascendants_count
        @general_family_expenses = general_family_expenses
        @health_expenses = health_expenses
        @education_expenses = education_expenses
        @housing_rent = housing_rent
        @alimony_paid = alimony_paid
        @care_home_expenses = care_home_expenses
        @domestic_work_expenses = domestic_work_expenses
        @young_dependents_second_later_under_six_count = young_dependents_second_later_under_six_count
        @vat_invoice_expenses = vat_invoice_expenses
        @vat_invoice_validation_state = vat_invoice_validation_state
        @disability_rehabilitation_expenses = disability_rehabilitation_expenses
        @disability_insurance_premiums = disability_insurance_premiums
        @ppr_contributions = ppr_contributions
        @ppr_age_band = ppr_age_band
        @donations = donations
        @filing_status = filing_status
        @apply_irs_jovem = apply_irs_jovem
        @irs_jovem_year = irs_jovem_year
        @union_dues = union_dues
        @professional_order_dues = professional_order_dues
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        annual_social_security = annual_gross_income * parameter_decimal!("employee_social_security_rate")
        specific_deduction = [
          annual_gross_income,
          TaxDeductions.employee_specific_deduction(
            regime:,
            annual_gross_income:,
            annual_social_security:,
            union_dues:,
            professional_order_dues:
          )
        ].min
        taxable_income_before_irs_jovem = [ annual_gross_income - specific_deduction, 0 ].max
        irs_jovem_exemption = irs_jovem_exempt_income(taxable_income_before_irs_jovem)
        taxable_income = [ taxable_income_before_irs_jovem - irs_jovem_exemption, 0 ].max
        annual_income_tax_before_deductions = household_income_tax(taxable_income)
        personal_deductions = portugal_tax_deductions
        annual_income_tax = [
          annual_income_tax_before_deductions - personal_deductions[:total],
          0
        ].max
        total_tax = annual_social_security + annual_income_tax
        annual_net_income = annual_gross_income - total_tax

        {
          metadata: metadata,
          input: build_input_payload(annual_gross_income:),
          breakdown: build_breakdown_payload(
            annual_social_security:,
            specific_deduction:,
            irs_jovem_exemption:,
            taxable_income_before_irs_jovem:,
            taxable_income:,
            annual_income_tax_before_deductions:,
            annual_income_tax:,
            total_tax:,
            annual_net_income:,
            personal_deductions:
          ),
          detail_cards: build_detail_cards(
            annual_social_security:,
            specific_deduction:,
            irs_jovem_exemption:,
            taxable_income:,
            annual_income_tax_before_deductions:,
            annual_income_tax:,
            total_tax:,
            personal_deductions:
          ),
          assumptions: assumptions,
          sources: regime.source_links
        }
      end

      private

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :children_count,
        :children_under_three_count, :disability_level, :ascendants_count, :general_family_expenses,
        :health_expenses, :education_expenses, :housing_rent, :alimony_paid, :care_home_expenses,
        :domestic_work_expenses, :young_dependents_second_later_under_six_count,
        :vat_invoice_expenses, :vat_invoice_validation_state, :disability_rehabilitation_expenses,
        :disability_insurance_premiums, :ppr_contributions, :ppr_age_band, :donations, :filing_status,
        :apply_irs_jovem, :irs_jovem_year, :union_dues, :professional_order_dues

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Portugal employee regime" if regime.blank?
        validate_employee_due!("union_dues", union_dues, errors)
        validate_employee_due!("professional_order_dues", professional_order_dues, errors)
        errors.concat(common_portugal_validation_errors)

        raise ValidationError.new(errors) if errors.any?
      end

      def regime
        @regime ||= find_regime(category: "employee", tax_year: tax_year, country: country)
      end

      def metadata
        build_regime_metadata(calculator_version: "portugal-employee-v1")
      end

      def build_input_payload(annual_gross_income:)
        build_common_input_payload(annual_gross_income:).merge(
          union_dues: round_currency(TaxDeductions.parse_amount(union_dues)),
          professional_order_dues: round_currency(TaxDeductions.parse_amount(professional_order_dues))
        )
      rescue ArgumentError
        build_common_input_payload(annual_gross_income:)
      end

      def build_breakdown_payload(
        annual_social_security:,
        specific_deduction:,
        irs_jovem_exemption:,
        taxable_income_before_irs_jovem:,
        taxable_income:,
        annual_income_tax_before_deductions:,
        annual_income_tax:,
        total_tax:,
        annual_net_income:,
        personal_deductions:
      )
        {
          annual_social_security: round_currency(annual_social_security),
          specific_deduction: round_currency(specific_deduction),
          irs_jovem_exemption: round_currency(irs_jovem_exemption),
          taxable_income_before_irs_jovem: round_currency(taxable_income_before_irs_jovem),
          taxable_income: round_currency(taxable_income),
          annual_income_tax_before_deductions: round_currency(annual_income_tax_before_deductions),
          dependent_deduction: round_currency(personal_deductions[:dependent_deduction]),
          dependent_under_three_deduction: round_currency(personal_deductions[:dependent_under_three_deduction]),
          young_dependent_second_later_deduction: round_currency(personal_deductions[:young_dependent_second_later_deduction]),
          ascendant_deduction: round_currency(personal_deductions[:ascendant_deduction]),
          disability_deduction: round_currency(personal_deductions[:disability_deduction]),
          general_family_deduction: round_currency(personal_deductions[:general_family_deduction]),
          health_expenses_deduction: round_currency(personal_deductions[:health_expenses_deduction]),
          education_expenses_deduction: round_currency(personal_deductions[:education_expenses_deduction]),
          housing_rent_deduction: round_currency(personal_deductions[:housing_rent_deduction]),
          alimony_deduction: round_currency(personal_deductions[:alimony_deduction]),
          care_home_deduction: round_currency(personal_deductions[:care_home_deduction]),
          domestic_work_deduction: round_currency(personal_deductions[:domestic_work_deduction]),
          vat_invoice_deduction: round_currency(personal_deductions[:vat_invoice_deduction]),
          disability_rehabilitation_deduction: round_currency(personal_deductions[:disability_rehabilitation_deduction]),
          disability_insurance_deduction: round_currency(personal_deductions[:disability_insurance_deduction]),
          ppr_deduction: round_currency(personal_deductions[:ppr_deduction]),
          donations_deduction: round_currency(personal_deductions[:donations_deduction]),
          total_personal_tax_deductions: round_currency(personal_deductions[:total]),
          annual_income_tax: round_currency(annual_income_tax),
          total_tax: round_currency(total_tax),
          annual_net_income: round_currency(annual_net_income),
          monthly_net_income: round_currency(annual_net_income / 12),
          effective_tax_rate: round_percentage(total_tax / normalize_annual_gross_income)
        }
      end

      def build_detail_cards(
        annual_social_security:,
        specific_deduction:,
        irs_jovem_exemption:,
        taxable_income:,
        annual_income_tax_before_deductions:,
        annual_income_tax:,
        total_tax:,
        personal_deductions:
      )
        [
          { label: "Employee social security", value: round_currency(annual_social_security) },
          { label: "Specific deduction", value: round_currency(specific_deduction) },
          { label: "IRS Jovem exempt income", value: round_currency(irs_jovem_exemption) },
          { label: "Taxable income", value: round_currency(taxable_income) },
          { label: "Portuguese IRS before deductions", value: round_currency(annual_income_tax_before_deductions) },
          {
            label: "Dependent and ascendant deductions",
            value: round_currency(
              personal_deductions[:dependent_deduction] +
              personal_deductions[:dependent_under_three_deduction] +
              personal_deductions[:young_dependent_second_later_deduction] +
              personal_deductions[:ascendant_deduction]
            )
          },
          { label: "Disability deduction", value: round_currency(personal_deductions[:disability_deduction]) },
          {
            label: "Expense-based deductions",
            value: round_currency(
              personal_deductions[:general_family_deduction] +
              personal_deductions[:health_expenses_deduction] +
              personal_deductions[:education_expenses_deduction] +
              personal_deductions[:housing_rent_deduction] +
              personal_deductions[:alimony_deduction] +
              personal_deductions[:care_home_deduction] +
              personal_deductions[:domestic_work_deduction] +
              personal_deductions[:vat_invoice_deduction] +
              personal_deductions[:disability_rehabilitation_deduction] +
              personal_deductions[:disability_insurance_deduction] +
              personal_deductions[:ppr_deduction] +
              personal_deductions[:donations_deduction]
            )
          },
          { label: "Portuguese IRS", value: round_currency(annual_income_tax) },
          { label: "Total tax", value: round_currency(total_tax) }
        ]
      end

      def assumptions
        [
          "Portugal, tax year #{tax_year}.",
          "Portugal is locked to mainland IRS brackets and deduction assumptions; Azores and Madeira regional tables are not reused.",
          "Employment income uses the seeded employee social security rate and category A specific deduction, including entered union dues and professional-order dues.",
          "Joint filing uses the household quotient on the entered taxpayer income only; spouse income allocation and full household composition workflows are not modeled.",
          "IRS Jovem is modeled as a simplified exempt-income reduction for categories A/B from 2025 onward, capped by the seeded 55xIAS limit.",
          "Included deductions: dependents, dependents under 3, second-and-later young dependents up to age 6, ascendants, taxpayer disability at 60% or more, general family expenses, health, education, housing rent, alimony, care home costs, domestic work, validated VAT-invoice incentives, disability rehabilitation and insurance, PPR, and donations.",
          "Legacy mortgage-interest deductions, minimum-existence adjustment, and full e-Fatura document verification remain outside the calculator."
        ]
      end

      def validate_employee_due!(key, value, errors)
        TaxDeductions.parse_amount(value)
      rescue ArgumentError
        errors << "#{key} must be 0 or greater"
      end
    end
  end
end
