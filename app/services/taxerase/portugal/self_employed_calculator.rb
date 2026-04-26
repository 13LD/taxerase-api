module Taxerase
  module Portugal
    class SelfEmployedCalculator
      include Taxerase::Support::RegimeBackedCalculation

      include CalculatorSupport

      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      CALCULATION_METHOD = "portugal_self_employed_v1".freeze
      COUNTRY_CODE = "PT".freeze
      ACTIVITY_TYPES = {
        "professional_services" => {
          taxable_income_rate: BigDecimal("0.75"),
          social_security_relevant_income_rate: BigDecimal("0.70"),
          documentation_support_required: true
        },
        "other_services" => {
          taxable_income_rate: BigDecimal("0.35"),
          social_security_relevant_income_rate: BigDecimal("0.70"),
          documentation_support_required: true
        },
        "sales_goods_hospitality" => {
          taxable_income_rate: BigDecimal("0.15"),
          social_security_relevant_income_rate: BigDecimal("0.20"),
          documentation_support_required: false
        }
      }.freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        deductible_expenses:,
        children_count:,
        children_under_three_count:,
        disability_level:,
        business_activity_type: "professional_services",
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
        self_employed_tax_regime: "simplified",
        start_activity_year: "none",
        social_security_exemption: false,
        social_security_adjustment_mode: "standard"
      )
        new(
          gross_income:,
          salary_period:,
          tax_regime_key:,
          tax_year:,
          deductible_expenses:,
          children_count:,
          children_under_three_count:,
          disability_level:,
          business_activity_type:,
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
          self_employed_tax_regime:,
          start_activity_year:,
          social_security_exemption:,
          social_security_adjustment_mode:
        ).call
      end

      def initialize(
        gross_income:,
        salary_period:,
        tax_regime_key:,
        tax_year:,
        deductible_expenses:,
        children_count:,
        children_under_three_count:,
        disability_level:,
        business_activity_type:,
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
        self_employed_tax_regime:,
        start_activity_year:,
        social_security_exemption:,
        social_security_adjustment_mode:
      )
        @gross_income = gross_income
        @salary_period = salary_period
        @tax_regime_key = tax_regime_key
        @tax_year = tax_year
        @deductible_expenses = deductible_expenses
        @children_count = children_count
        @children_under_three_count = children_under_three_count
        @disability_level = disability_level
        @business_activity_type = business_activity_type
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
        @self_employed_tax_regime = self_employed_tax_regime
        @start_activity_year = start_activity_year
        @social_security_exemption = social_security_exemption
        @social_security_adjustment_mode = social_security_adjustment_mode
      end

      def call
        validate!

        annual_gross_income = normalize_annual_gross_income
        annual_deductible_expenses = parsed_deductible_expenses
        activity_profile = ACTIVITY_TYPES.fetch(business_activity_type.to_s)
        annual_social_security = annual_self_employed_social_security(
          annual_gross_income:,
          activity_profile:
        )
        social_security_excess_deduction = if simplified_regime? && activity_profile.fetch(:documentation_support_required)
          [ annual_social_security - (annual_gross_income * BigDecimal("0.10")), BigDecimal("0") ].max
        else
          BigDecimal("0")
        end
        simplified_taxable_base = annual_gross_income *
          activity_profile.fetch(:taxable_income_rate) *
          start_activity_multiplier
        documentation_support_base = TaxDeductions.documentation_support_base(
          regime:,
          annual_social_security:,
          annual_gross_income:
        )
        documentation_shortfall_addition = if simplified_regime? && activity_profile.fetch(:documentation_support_required)
          [
            (annual_gross_income * BigDecimal("0.15")) - documentation_support_base - annual_deductible_expenses,
            BigDecimal("0")
          ].max
        else
          BigDecimal("0")
        end
        taxable_income_before_irs_jovem = [
          category_b_taxable_base(
            annual_gross_income:,
            annual_deductible_expenses:,
            annual_social_security:,
            simplified_taxable_base:,
            social_security_excess_deduction:,
            documentation_shortfall_addition:
          ),
          BigDecimal("0")
        ].max
        irs_jovem_exemption = irs_jovem_exempt_income(taxable_income_before_irs_jovem)
        taxable_income = [ taxable_income_before_irs_jovem - irs_jovem_exemption, BigDecimal("0") ].max
        annual_income_tax_before_deductions = household_income_tax(taxable_income)
        personal_deductions = portugal_tax_deductions
        annual_income_tax = [
          annual_income_tax_before_deductions - personal_deductions[:total],
          0
        ].max
        total_tax = annual_social_security + annual_income_tax
        annual_net_income = annual_gross_income - annual_deductible_expenses - total_tax

        {
          metadata: metadata,
          input: build_input_payload(annual_gross_income:, annual_deductible_expenses:),
          breakdown: build_breakdown_payload(
            annual_social_security:,
            social_security_excess_deduction:,
            simplified_taxable_base:,
            documentation_support_base:,
            documentation_shortfall_addition:,
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
            annual_deductible_expenses:,
            annual_social_security:,
            social_security_excess_deduction:,
            simplified_taxable_base:,
            documentation_shortfall_addition:,
            irs_jovem_exemption:,
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

      attr_reader :gross_income, :salary_period, :tax_regime_key, :tax_year, :deductible_expenses,
        :children_count, :children_under_three_count, :disability_level, :business_activity_type,
        :ascendants_count, :general_family_expenses, :health_expenses, :education_expenses, :housing_rent,
        :alimony_paid, :care_home_expenses, :domestic_work_expenses,
        :young_dependents_second_later_under_six_count, :vat_invoice_expenses, :vat_invoice_validation_state,
        :disability_rehabilitation_expenses, :disability_insurance_premiums, :ppr_contributions, :ppr_age_band,
        :donations, :filing_status, :apply_irs_jovem, :irs_jovem_year, :self_employed_tax_regime,
        :start_activity_year, :social_security_exemption, :social_security_adjustment_mode

      def validate!
        errors = []
        errors << "gross_income must be a number greater than 0" if parsed_gross_income <= 0
        errors << "gross_income is too large for the current calculator" if parsed_gross_income > 50_000_000
        errors << "deductible_expenses must be 0 or greater" if parsed_deductible_expenses.negative?
        errors << "deductible_expenses is too large for the current calculator" if parsed_deductible_expenses > 50_000_000
        errors << "salary_period must be YEAR or MONTH" unless %w[YEAR MONTH].include?(normalized_salary_period)
        errors << "tax_regime_key must point to a supported Portugal self-employed regime" if regime.blank?
        errors << "business_activity_type must be one of: #{ACTIVITY_TYPES.keys.join(', ')}" unless ACTIVITY_TYPES.key?(business_activity_type.to_s)
        errors << "self_employed_tax_regime must be one of: simplified, organized_accounting" unless %w[simplified organized_accounting].include?(self_employed_tax_regime.to_s)
        errors << "start_activity_year must be one of: none, first_year, second_year" unless %w[none first_year second_year].include?(start_activity_year.to_s)
        unless %w[standard reduce_25 increase_25].include?(social_security_adjustment_mode.to_s)
          errors << "social_security_adjustment_mode must be one of: standard, reduce_25, increase_25"
        end
        errors.concat(common_portugal_validation_errors)

        raise ValidationError.new(errors) if errors.any?
      end

      def regime
        @regime ||= find_regime(category: "self_employed", tax_year: tax_year, country: country)
      end

      def metadata
        build_regime_metadata(calculator_version: "portugal-self-employed-v1")
      end

      def build_input_payload(annual_gross_income:, annual_deductible_expenses:)
        build_common_input_payload(annual_gross_income:).merge(
          deductible_expenses: round_currency(annual_deductible_expenses),
          business_activity_type: business_activity_type.to_s,
          self_employed_tax_regime: self_employed_tax_regime.to_s.presence || "simplified",
          start_activity_year: start_activity_year.to_s.presence || "none",
          social_security_exemption: truthy?(social_security_exemption),
          social_security_adjustment_mode: social_security_adjustment_mode.to_s.presence || "standard"
        )
      end

      def build_breakdown_payload(
        annual_social_security:,
        social_security_excess_deduction:,
        simplified_taxable_base:,
        documentation_support_base:,
        documentation_shortfall_addition:,
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
          annual_deductible_expenses: round_currency(parsed_deductible_expenses),
          annual_social_security: round_currency(annual_social_security),
          social_security_excess_deduction: round_currency(social_security_excess_deduction),
          simplified_taxable_base: round_currency(simplified_taxable_base),
          documentation_support_base: round_currency(documentation_support_base),
          documentation_shortfall_addition: round_currency(documentation_shortfall_addition),
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
        annual_deductible_expenses:,
        annual_social_security:,
        social_security_excess_deduction:,
        simplified_taxable_base:,
        documentation_shortfall_addition:,
        irs_jovem_exemption:,
        annual_income_tax_before_deductions:,
        annual_income_tax:,
        total_tax:,
        personal_deductions:
      )
        [
          { label: "Documented business expenses", value: round_currency(annual_deductible_expenses) },
          { label: "Simplified taxable base", value: round_currency(simplified_taxable_base) },
          { label: "Documentation shortfall adjustment", value: round_currency(documentation_shortfall_addition) },
          { label: "IRS Jovem exempt income", value: round_currency(irs_jovem_exemption) },
          { label: "Social security contribution", value: round_currency(annual_social_security) },
          { label: "Social security deduction above 10% of revenue", value: round_currency(social_security_excess_deduction) },
          { label: "Portuguese IRS before deductions", value: round_currency(annual_income_tax_before_deductions) },
          {
            label: "Personal tax deductions",
            value: round_currency(personal_deductions[:total])
          },
          { label: "Portuguese IRS", value: round_currency(annual_income_tax) },
          { label: "Total tax", value: round_currency(total_tax) }
        ]
      end

      def assumptions
        [
          "Portugal, tax year #{tax_year}.",
          "Portugal is locked to mainland IRS brackets and deduction assumptions; Azores and Madeira regional tables are not reused.",
          "The activity type selects the official simplified-regime taxable-income coefficient and the matching social-security relevant-income share used by this calculator.",
          "The self-employed tax-regime selector supports simplified-regime coefficients and an organized-accounting estimate based on entered revenue, expenses, and social security.",
          "Start-of-activity mode reduces simplified coefficients only for first- and second-year estimates.",
          "Self-employed social security is still an annual estimate, but it now supports exemption and the 25% adjustment up/down control.",
          "Joint filing uses the household quotient on the entered taxpayer income only; spouse income allocation and full household composition workflows are not modeled.",
          "IRS Jovem is modeled as a simplified exempt-income reduction for categories A/B from 2025 onward, capped by the seeded 55xIAS limit.",
          "Included deductions: dependents, dependents under 3, second-and-later young dependents up to age 6, ascendants, taxpayer disability at 60% or more, general family expenses, health, education, housing rent, alimony, care home costs, domestic work, validated VAT-invoice incentives, disability rehabilitation and insurance, PPR, and donations.",
          "Quarterly declarations, minimum and maximum incidence-base mechanics, legacy mortgage-interest deductions, minimum-existence adjustment, and full e-Fatura document verification remain outside the calculator."
        ]
      end

      def category_b_taxable_base(
        annual_gross_income:,
        annual_deductible_expenses:,
        annual_social_security:,
        simplified_taxable_base:,
        social_security_excess_deduction:,
        documentation_shortfall_addition:
      )
        if organized_accounting_regime?
          return annual_gross_income - annual_deductible_expenses - annual_social_security
        end

        simplified_taxable_base - social_security_excess_deduction + documentation_shortfall_addition
      end

      def annual_self_employed_social_security(annual_gross_income:, activity_profile:)
        return BigDecimal("0") if truthy?(social_security_exemption)

        annual_gross_income *
          activity_profile.fetch(:social_security_relevant_income_rate) *
          parameter_decimal!("self_employed_social_security_rate") *
          social_security_adjustment_factor
      end

      def social_security_adjustment_factor
        case social_security_adjustment_mode.to_s
        when "reduce_25" then BigDecimal("0.75")
        when "increase_25" then BigDecimal("1.25")
        else BigDecimal("1")
        end
      end

      def start_activity_multiplier
        return BigDecimal("1") unless simplified_regime?

        case start_activity_year.to_s
        when "first_year" then BigDecimal("0.5")
        when "second_year" then BigDecimal("0.75")
        else BigDecimal("1")
        end
      end

      def simplified_regime?
        !organized_accounting_regime?
      end

      def organized_accounting_regime?
        self_employed_tax_regime.to_s == "organized_accounting"
      end

      def parsed_deductible_expenses
        @parsed_deductible_expenses ||= BigDecimal(deductible_expenses.to_s)
      rescue ArgumentError
        BigDecimal("0")
      end
    end
  end
end
