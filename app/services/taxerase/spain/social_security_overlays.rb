module Taxerase
  module Spain
    module SocialSecurityOverlays
      RETA_CONTRIBUTION_MODES = %w[
        standard
        reduced_first_year
        reduced_extension
        reduced_special_24_months
        reduced_special_following
      ].freeze

      module_function

      def employee_solidarity(regime:, monthly_gross_income:)
        excess_base = [ monthly_gross_income - regime.parameter_decimal!("monthly_max_contribution_base"), 0 ].max
        return BigDecimal("0") unless excess_base.positive?

        excess_base * 12 * optional_parameter_decimal(regime, "employee_solidarity_rate")
      end

      def reta_contribution(
        regime:,
        standard_contribution:,
        reta_contribution_mode:,
        family_collaborator:,
        corporate_self_employed:
      )
        mode = reta_contribution_mode.to_s.presence || "standard"
        contribution =
          case mode
          when "reduced_first_year", "reduced_extension", "reduced_special_24_months"
            regime.parameter_decimal!("reta_reduced_monthly_quota") * 12
          when "reduced_special_following"
            regime.parameter_decimal!("reta_reduced_special_following_monthly_quota") * 12
          else
            standard_contribution
          end

        contribution *= (BigDecimal("1") - regime.parameter_decimal!("family_collaborator_reta_discount_rate")) if family_collaborator
        contribution *= (BigDecimal("1") + regime.parameter_decimal!("corporate_self_employed_reta_uplift_rate")) if corporate_self_employed
        contribution
      end

      def pluriactivity_refund(regime:, employment_common_contingencies_paid:, annual_reta_contribution:)
        employment_contributions = InputNormalization.decimal(employment_common_contingencies_paid)
        threshold = regime.parameter_decimal!("pluriactivity_refund_threshold")
        excess = [ employment_contributions + annual_reta_contribution - threshold, 0 ].max
        [ excess * regime.parameter_decimal!("pluriactivity_refund_rate"), annual_reta_contribution * regime.parameter_decimal!("pluriactivity_refund_cap_rate") ].min
      end

      def reta_mode_label(mode)
        {
          "standard" => "standard RETA contribution",
          "reduced_first_year" => "80 EUR reduced RETA quota for first 12 months",
          "reduced_extension" => "80 EUR reduced RETA quota extension",
          "reduced_special_24_months" => "80 EUR special reduced RETA quota",
          "reduced_special_following" => "160 EUR special follow-up RETA quota"
        }.fetch(mode.to_s, "standard RETA contribution")
      end

      def validate_reta_mode(mode)
        RETA_CONTRIBUTION_MODES.include?(mode.to_s.presence || "standard")
      end

      def optional_parameter_decimal(regime, key)
        regime.parameter_decimal!(key)
      rescue KeyError
        BigDecimal("0")
      end
    end
  end
end
