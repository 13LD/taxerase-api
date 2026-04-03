module Taxerase
  module Andorra
    module SelfEmployedContributionBase
      def self.call(net_income:, regime:)
        ratio = contribution_ratio(net_income, regime)
        monthly_average_salary = regime.parameter_decimal!("monthly_average_salary")
        minimum_monthly_salary = regime.parameter_decimal!("minimum_monthly_salary")
        monthly_base = [ monthly_average_salary * ratio, minimum_monthly_salary ].max
        annual_base = monthly_base * 12

        {
          ratio:,
          monthly_base:,
          annual_base:
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
