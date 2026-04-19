module Taxerase
  module Andorra
    module SelfEmployedContributionBase
      SOCIAL_SECURITY_REGIMES = %w[standard under_35_first_12_months under_35_month_13_to_24].freeze

      def self.call(net_income:, regime:, social_security_regime: "standard")
        if social_security_regime.to_s == "standard"
          standard_contribution_base(net_income:, regime:)
        else
          under_35_contribution_base(regime:, social_security_regime:)
        end
      end

      def self.standard_contribution_base(net_income:, regime:)
        ratio = contribution_ratio(net_income, regime)
        monthly_average_salary = regime.parameter_decimal!("monthly_average_salary")
        monthly_base = monthly_average_salary * ratio
        annual_base = monthly_base * 12

        {
          social_security_regime: "standard",
          label: "#{(ratio * 100).round(2).to_f}% of the previous-year average salary",
          ratio:,
          monthly_base:,
          annual_base:,
          annual_contribution: annual_base * regime.parameter_decimal!("self_employed_social_security_rate"),
          contribution_rate: regime.parameter_decimal!("self_employed_social_security_rate")
        }
      end

      def self.under_35_contribution_base(regime:, social_security_regime:)
        minimum_monthly_salary = regime.parameter_decimal!("minimum_monthly_salary")
        monthly_base = minimum_monthly_salary * regime.parameter_decimal!("under_35_special_base_min_salary_ratio")
        annual_base = monthly_base * 12
        contribution_rate =
          if social_security_regime.to_s == "under_35_first_12_months"
            regime.parameter_decimal!("under_35_special_first_year_rate")
          else
            regime.parameter_decimal!("under_35_special_second_year_rate")
          end

        {
          social_security_regime: social_security_regime.to_s,
          label: "55% of the official minimum salary under the under-35 special regime",
          ratio: nil,
          monthly_base:,
          annual_base:,
          annual_contribution: annual_base * contribution_rate,
          contribution_rate:
        }
      end

      def self.contribution_ratio(net_income, regime)
        annual_net_income = net_income.to_d

        return regime.parameter_decimal!("self_employed_base_ratio_tier_1") if annual_net_income <= regime.parameter_decimal!("self_employed_base_ratio_tier_1_threshold")
        return regime.parameter_decimal!("self_employed_base_ratio_tier_2") if annual_net_income <= regime.parameter_decimal!("self_employed_base_ratio_tier_2_threshold")
        return regime.parameter_decimal!("self_employed_base_ratio_tier_3") if annual_net_income <= regime.parameter_decimal!("self_employed_base_ratio_tier_3_threshold")
        return regime.parameter_decimal!("self_employed_base_ratio_tier_4") if annual_net_income <= regime.parameter_decimal!("self_employed_base_ratio_tier_4_threshold")
        return regime.parameter_decimal!("self_employed_base_ratio_tier_5") if annual_net_income <= regime.parameter_decimal!("self_employed_base_ratio_tier_5_threshold")

        regime.parameter_decimal!("self_employed_base_ratio_tier_6")
      end
    end
  end
end
