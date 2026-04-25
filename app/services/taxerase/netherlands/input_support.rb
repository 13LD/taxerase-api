module Taxerase
  module Netherlands
    module InputSupport
      def credit_inputs
        {
          fiscal_partner: calculation_inputs[:fiscal_partner],
          partner_labour_income: calculation_inputs[:partner_labour_income],
          children_under_12_count: calculation_inputs[:children_under_12_count],
          single_aow_household: calculation_inputs[:single_aow_household],
          wajong_status: calculation_inputs[:wajong_status],
          green_investments_value: calculation_inputs[:green_investments_value]
        }
      end

      def credit_input_payload
        {
          children_count: calculation_inputs[:children_count].to_i,
          children_under_three_count: calculation_inputs[:children_under_three_count].to_i,
          children_under_12_count: calculation_inputs[:children_under_12_count].to_i,
          disability_level: calculation_inputs[:disability_level].presence || "none",
          fiscal_partner: boolean_input(:fiscal_partner),
          partner_labour_income: round_currency(decimal_input(:partner_labour_income)),
          single_aow_household: boolean_input(:single_aow_household),
          wajong_status: boolean_input(:wajong_status),
          green_investments_value: round_currency(decimal_input(:green_investments_value))
        }
      end

      def personal_deduction_input_payload(inputs = calculation_inputs)
        PersonalDeductions::HEALTHCARE_KEYS.index_with { |key| round_currency(decimal_value(inputs, key)) }.merge(
          partner_alimony_paid: round_currency(decimal_value(inputs, :partner_alimony_paid)),
          temporary_home_stay_disabled_days: decimal_value(inputs, :temporary_home_stay_disabled_days).to_i,
          temporary_home_stay_disabled_km: round_currency(decimal_value(inputs, :temporary_home_stay_disabled_km)),
          ordinary_anbi_gifts: round_currency(decimal_value(inputs, :ordinary_anbi_gifts)),
          periodic_anbi_gifts: round_currency(decimal_value(inputs, :periodic_anbi_gifts)),
          cultural_anbi_gifts: round_currency(decimal_value(inputs, :cultural_anbi_gifts)),
          deductible_aov_premium: round_currency(decimal_value(inputs, :deductible_aov_premium)),
          deductible_lijfrente_premium: round_currency(decimal_value(inputs, :deductible_lijfrente_premium)),
          remaining_personal_deduction_carryforward: round_currency(
            decimal_value(inputs, :remaining_personal_deduction_carryforward)
          )
        )
      end

      def active_credit_eligibility(credits)
        credits.fetch(:eligibility).select { |_key, value| value }.keys.join(", ").presence || "none"
      end

      def combined_income(taxable_income)
        return taxable_income unless boolean_input(:fiscal_partner)

        taxable_income + decimal_input(:partner_labour_income)
      end

      def boolean_input(key)
        ActiveModel::Type::Boolean.new.cast(calculation_inputs[key])
      end

      def decimal_input(key)
        decimal_value(calculation_inputs, key)
      end

      def decimal_value(inputs, key)
        BigDecimal(inputs[key].to_s.presence || "0")
      rescue ArgumentError
        BigDecimal("0")
      end

      def round_breakdown(values)
        values.transform_values { |value| round_currency(value) }
      end
    end
  end
end
