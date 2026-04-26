module Taxerase
  module Portugal
    module TaxDeductions
      DISABILITY_LEVELS = %w[none disability_60_plus].freeze
      FILING_STATUSES = %w[individual joint].freeze
      IRS_JOVEM_YEARS = (0..10).freeze
      PPR_AGE_BANDS = %w[under_35 from_35_to_50 over_50].freeze
      VAT_INVOICE_VALIDATION_STATES = %w[not_validated pending validated].freeze

      AMOUNT_INPUT_KEYS = %i[
        general_family_expenses
        health_expenses
        education_expenses
        housing_rent
        alimony_paid
        care_home_expenses
        domestic_work_expenses
        vat_invoice_expenses
        disability_rehabilitation_expenses
        disability_insurance_premiums
        ppr_contributions
        donations
      ].freeze

      def self.validation_errors(
        disability_level:,
        ascendants_count:,
        children_count:,
        young_dependents_second_later_under_six_count:,
        general_family_expenses:,
        health_expenses:,
        education_expenses:,
        housing_rent:,
        alimony_paid:,
        care_home_expenses:,
        domestic_work_expenses:,
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
        tax_year:
      )
        errors = []
        errors << "disability_level must be one of: #{DISABILITY_LEVELS.join(', ')}" unless DISABILITY_LEVELS.include?(disability_level.to_s)
        errors << "filing_status must be one of: #{FILING_STATUSES.join(', ')}" unless FILING_STATUSES.include?(filing_status.to_s)
        errors << "ppr_age_band must be one of: #{PPR_AGE_BANDS.join(', ')}" unless PPR_AGE_BANDS.include?(ppr_age_band.to_s)
        unless VAT_INVOICE_VALIDATION_STATES.include?(vat_invoice_validation_state.to_s)
          errors << "vat_invoice_validation_state must be one of: #{VAT_INVOICE_VALIDATION_STATES.join(', ')}"
        end
        validate_count("ascendants_count", ascendants_count, errors)
        validate_count(
          "young_dependents_second_later_under_six_count",
          young_dependents_second_later_under_six_count,
          errors
        )
        validate_young_dependent_second_later_count(
          children_count:,
          young_dependents_second_later_under_six_count:,
          errors:
        )
        validate_irs_jovem!(apply_irs_jovem:, irs_jovem_year:, tax_year:, errors:)

        {
          general_family_expenses:,
          health_expenses:,
          education_expenses:,
          housing_rent:,
          alimony_paid:,
          care_home_expenses:,
          domestic_work_expenses:,
          vat_invoice_expenses:,
          disability_rehabilitation_expenses:,
          disability_insurance_premiums:,
          ppr_contributions:,
          donations:
        }.each do |key, value|
          validate_amount(key, value, errors)
        end

        errors
      end

      def self.employee_specific_deduction(
        regime:,
        annual_gross_income:,
        annual_social_security:,
        union_dues: 0,
        professional_order_dues: 0
      )
        base = [ regime.parameter_decimal!("specific_deduction_floor"), annual_social_security ].max
        union_deduction = [
          parse_amount(union_dues) * regime.parameter_decimal!("union_dues_deduction_multiplier"),
          annual_gross_income * regime.parameter_decimal!("union_dues_deduction_cap_rate")
        ].min

        base + union_deduction + parse_amount(professional_order_dues)
      end

      def self.documentation_support_base(regime:, annual_social_security:, annual_gross_income:)
        social_security_cap = annual_gross_income * BigDecimal("0.10")
        supported_social_security = [ annual_social_security, social_security_cap ].min

        [ regime.parameter_decimal!("specific_deduction_floor"), supported_social_security ].max
      end

      def self.personal_tax_deductions(
        regime:,
        children_count:,
        children_under_three_count:,
        disability_level:,
        ascendants_count:,
        young_dependents_second_later_under_six_count:,
        general_family_expenses:,
        health_expenses:,
        education_expenses:,
        housing_rent:,
        alimony_paid:,
        care_home_expenses:,
        domestic_work_expenses:,
        vat_invoice_expenses:,
        vat_invoice_validation_state:,
        disability_rehabilitation_expenses:,
        disability_insurance_premiums:,
        ppr_contributions:,
        ppr_age_band:,
        donations:
      )
        parsed_children_count = parse_count(children_count)
        parsed_children_under_three_count = parse_count(children_under_three_count)
        parsed_ascendants_count = parse_count(ascendants_count)
        dependent_deduction = regime.parameter_decimal!("dependent_deduction") * parsed_children_count
        dependent_under_three_deduction =
          regime.parameter_decimal!("dependent_under_three_bonus") * parsed_children_under_three_count
        young_dependent_second_later_deduction =
          regime.parameter_decimal!("young_dependent_second_later_bonus") *
          parse_count(young_dependents_second_later_under_six_count)
        ascendant_deduction = regime.parameter_decimal!("ascendant_deduction") * parsed_ascendants_count
        ascendant_deduction += regime.parameter_decimal!("single_ascendant_bonus") if parsed_ascendants_count == 1
        disability_deduction =
          disability_level.to_s == "disability_60_plus" ? regime.parameter_decimal!("taxpayer_disability_deduction") : BigDecimal("0")
        general_family_deduction = capped_deduction(
          amount: general_family_expenses,
          rate: regime.parameter_decimal!("general_family_deduction_rate"),
          cap: regime.parameter_decimal!("general_family_deduction_cap")
        )
        health_expenses_deduction = capped_deduction(
          amount: health_expenses,
          rate: regime.parameter_decimal!("health_expenses_deduction_rate"),
          cap: regime.parameter_decimal!("health_expenses_deduction_cap")
        )
        education_expenses_deduction = capped_deduction(
          amount: education_expenses,
          rate: regime.parameter_decimal!("education_expenses_deduction_rate"),
          cap: regime.parameter_decimal!("education_expenses_deduction_cap")
        )
        housing_rent_deduction = capped_deduction(
          amount: housing_rent,
          rate: regime.parameter_decimal!("housing_rent_deduction_rate"),
          cap: regime.parameter_decimal!("housing_rent_deduction_cap")
        )
        alimony_deduction = percentage_deduction(
          amount: alimony_paid,
          rate: regime.parameter_decimal!("alimony_deduction_rate")
        )
        care_home_deduction = capped_deduction(
          amount: care_home_expenses,
          rate: regime.parameter_decimal!("care_home_deduction_rate"),
          cap: regime.parameter_decimal!("care_home_deduction_cap")
        )
        domestic_work_deduction = capped_deduction(
          amount: domestic_work_expenses,
          rate: regime.parameter_decimal!("domestic_work_deduction_rate"),
          cap: regime.parameter_decimal!("domestic_work_deduction_cap")
        )
        vat_invoice_deduction = vat_invoice_validation_state.to_s == "validated" ? capped_deduction(
          amount: vat_invoice_expenses,
          rate: regime.parameter_decimal!("vat_invoice_deduction_rate"),
          cap: regime.parameter_decimal!("vat_invoice_deduction_cap")
        ) : BigDecimal("0")
        disability_rehabilitation_deduction = percentage_deduction(
          amount: disability_rehabilitation_expenses,
          rate: regime.parameter_decimal!("disability_rehabilitation_deduction_rate")
        )
        disability_insurance_deduction = capped_deduction(
          amount: disability_insurance_premiums,
          rate: regime.parameter_decimal!("disability_insurance_deduction_rate"),
          cap: regime.parameter_decimal!("disability_insurance_deduction_cap")
        )
        ppr_deduction = capped_deduction(
          amount: ppr_contributions,
          rate: regime.parameter_decimal!("ppr_deduction_rate"),
          cap: ppr_cap(regime:, ppr_age_band:)
        )
        donations_deduction = percentage_deduction(
          amount: donations,
          rate: regime.parameter_decimal!("donations_deduction_rate")
        )

        deductions = {
          dependent_deduction:,
          dependent_under_three_deduction:,
          young_dependent_second_later_deduction:,
          ascendant_deduction:,
          disability_deduction:,
          general_family_deduction:,
          health_expenses_deduction:,
          education_expenses_deduction:,
          housing_rent_deduction:,
          alimony_deduction:,
          care_home_deduction:,
          domestic_work_deduction:,
          vat_invoice_deduction:,
          disability_rehabilitation_deduction:,
          disability_insurance_deduction:,
          ppr_deduction:,
          donations_deduction:
        }

        deductions.merge(total: deductions.values.sum)
      end

      def self.irs_jovem_exempt_income(regime:, tax_year:, apply_irs_jovem:, irs_jovem_year:, eligible_income:)
        return BigDecimal("0") unless ActiveModel::Type::Boolean.new.cast(apply_irs_jovem)
        return BigDecimal("0") if tax_year.to_i < 2025

        rate = irs_jovem_exemption_rate(irs_jovem_year)
        [ BigDecimal(eligible_income.to_s) * rate, regime.parameter_decimal!("irs_jovem_exemption_cap") ].min
      end

      def self.household_income_tax(amount:, brackets:, filing_status:)
        taxable_amount = BigDecimal(amount.to_s)
        return ProgressiveTax.call(amount: taxable_amount / 2, brackets:) * 2 if filing_status.to_s == "joint"

        ProgressiveTax.call(amount: taxable_amount, brackets:)
      end

      def self.parse_count(value)
        parsed_value = Integer(value.to_s, exception: false)
        raise ArgumentError if parsed_value.nil? || parsed_value.negative?

        parsed_value
      end

      def self.parse_amount(value)
        parsed_value = BigDecimal(value.to_s)
        raise ArgumentError if parsed_value.negative?

        parsed_value
      rescue ArgumentError
        raise ArgumentError
      end

      def self.capped_deduction(amount:, rate:, cap:)
        [ parse_amount(amount) * rate, cap ].min
      end

      def self.percentage_deduction(amount:, rate:)
        parse_amount(amount) * rate
      end

      def self.irs_jovem_exemption_rate(irs_jovem_year)
        case Integer(irs_jovem_year.to_s, exception: false)
        when 1 then BigDecimal("1")
        when 2..4 then BigDecimal("0.75")
        when 5..7 then BigDecimal("0.50")
        when 8..10 then BigDecimal("0.25")
        else BigDecimal("0")
        end
      end

      def self.ppr_cap(regime:, ppr_age_band:)
        case ppr_age_band.to_s
        when "under_35" then regime.parameter_decimal!("ppr_deduction_cap_under_35")
        when "from_35_to_50" then regime.parameter_decimal!("ppr_deduction_cap_35_to_50")
        else regime.parameter_decimal!("ppr_deduction_cap_over_50")
        end
      end

      def self.validate_count(key, value, errors)
        parse_count(value)
      rescue ArgumentError
        errors << "#{key} must be 0 or greater"
      end
      private_class_method :validate_count

      def self.validate_young_dependent_second_later_count(
        children_count:,
        young_dependents_second_later_under_six_count:,
        errors:
      )
        parsed_children_count = parse_count(children_count)
        parsed_young_count = parse_count(young_dependents_second_later_under_six_count)
        max_second_later_count = [ parsed_children_count - 1, 0 ].max
        return if parsed_young_count <= max_second_later_count

        errors << "young_dependents_second_later_under_six_count must be between 0 and second-and-later children_count"
      rescue ArgumentError
        nil
      end
      private_class_method :validate_young_dependent_second_later_count

      def self.validate_amount(key, value, errors)
        parse_amount(value)
      rescue ArgumentError
        errors << "#{key} must be 0 or greater"
      end
      private_class_method :validate_amount

      def self.validate_irs_jovem!(apply_irs_jovem:, irs_jovem_year:, tax_year:, errors:)
        return unless ActiveModel::Type::Boolean.new.cast(apply_irs_jovem)

        parsed_year = Integer(irs_jovem_year.to_s, exception: false)
        errors << "irs_jovem_year must be between 1 and 10 when IRS Jovem applies" unless IRS_JOVEM_YEARS.include?(parsed_year) && parsed_year.positive?
        errors << "IRS Jovem is supported only from Portugal tax year 2025" if tax_year.to_i < 2025
      end
      private_class_method :validate_irs_jovem!
    end
  end
end
