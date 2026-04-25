module Taxerase
  module Netherlands
    class EntrepreneurReliefs
      def self.call(**attributes)
        new(**attributes).call
      end

      def initialize(regime:, profile:, gross_income:, deductible_expenses:, inputs: {})
        @regime = regime
        @profile = profile
        @gross_income = BigDecimal(gross_income.to_s)
        @deductible_expenses = BigDecimal(deductible_expenses.to_s)
        @inputs = inputs || {}
      end

      def call
        expense_components = {
          ordinary_expenses: deductible_expenses,
          private_vehicle_km: private_vehicle_deduction,
          mixed_costs: mixed_cost_deduction,
          home_workspace: home_workspace_deduction
        }
        annual_deductible_expenses = expense_components.values.sum(BigDecimal("0"))
        profit_before_reliefs = [ gross_income - annual_deductible_expenses, 0 ].max
        relief_components = reliefs_for(profit_before_reliefs)
        entrepreneur_deduction = relief_components.except(:kia).values.sum(BigDecimal("0"))
        profit_after_entrepreneur_deduction = [ profit_before_reliefs - entrepreneur_deduction, 0 ].max
        kia = [ relief_components.fetch(:kia), profit_after_entrepreneur_deduction ].min
        profit_after_investment_reliefs = [ profit_after_entrepreneur_deduction - kia, 0 ].max

        {
          eligibility: eligibility,
          expenses: {
            components: expense_components,
            total: annual_deductible_expenses
          },
          reliefs: {
            components: relief_components.merge(kia:),
            entrepreneur_deduction:,
            total: entrepreneur_deduction + kia
          },
          business_profit_before_reliefs: profit_before_reliefs,
          profit_after_entrepreneur_deduction:,
          profit_after_investment_reliefs:,
          notes: notes
        }
      end

      private

      attr_reader :regime, :profile, :gross_income, :deductible_expenses, :inputs

      def reliefs_for(profit)
        {
          self_employed_deduction: self_employed_deduction(profit),
          starters_deduction: starters_deduction(profit),
          disability_starter_deduction: disability_starter_deduction(profit),
          s_and_o_deduction: s_and_o_deduction,
          meewerkaftrek: meewerkaftrek(profit),
          stakingsaftrek: stakingsaftrek,
          kia: kia_deduction
        }
      end

      def eligibility
        @eligibility ||= {
          entrepreneur: boolean(:qualifies_as_entrepreneur, default: true),
          hours_worked: amount(:hours_worked_in_business, default: standard_hours),
          hours_criterion_met: hours_criterion_met?,
          disability_hours_criterion_met: disability_hours_criterion_met?,
          other_work_hours_higher: boolean(:has_other_work_hours_higher_than_business)
        }
      end

      def hours_criterion_met?
        boolean(:qualifies_as_entrepreneur, default: true) &&
          amount(:hours_worked_in_business, default: standard_hours) >= standard_hours &&
          !boolean(:has_other_work_hours_higher_than_business)
      end

      def disability_hours_criterion_met?
        boolean(:qualifies_as_entrepreneur, default: true) &&
          boolean(:disabled_starter_scheme) &&
          amount(:hours_worked_in_business, default: standard_hours) >= parameter_decimal("disability_starter_hours_criterion")
      end

      def self_employed_deduction(profit)
        return BigDecimal("0") unless eligibility.fetch(:hours_criterion_met)

        [ profit, self_employed_deduction_amount ].min
      end

      def starters_deduction(profit)
        return BigDecimal("0") unless eligibility.fetch(:hours_criterion_met)
        return BigDecimal("0") unless amount(:startup_uses_in_last_5_years, default: 3) < 3

        [ profit, age_adjusted_amount("starters_deduction") ].min
      end

      def disability_starter_deduction(profit)
        return BigDecimal("0") unless eligibility.fetch(:disability_hours_criterion_met)
        return BigDecimal("0") if profile.fetch(:aow_eligible)

        use_count = amount(:disabled_starter_deduction_uses).to_i
        amount_key = case use_count
        when 0 then "disability_starter_deduction_first"
        when 1 then "disability_starter_deduction_second"
        else "disability_starter_deduction_third"
        end

        [ profit, parameter_decimal(amount_key) ].min
      end

      def s_and_o_deduction
        return BigDecimal("0") unless eligibility.fetch(:hours_criterion_met)
        return BigDecimal("0") unless boolean(:has_s_and_o_declaration)
        return BigDecimal("0") unless amount(:s_and_o_hours) >= parameter_decimal("s_and_o_hours_minimum")

        parameter_decimal("s_and_o_deduction") +
          (boolean(:s_and_o_starter) ? parameter_decimal("s_and_o_starter_deduction") : BigDecimal("0"))
      end

      def meewerkaftrek(profit)
        return BigDecimal("0") unless eligibility.fetch(:hours_criterion_met)
        return BigDecimal("0") unless boolean(:fiscal_partner)
        return BigDecimal("0") unless amount(:partner_fee_paid) < parameter_decimal("meewerkaftrek_partner_fee_cap")

        hours = amount(:partner_unpaid_hours)
        rate = case hours
        when 525...875 then parameter_decimal("meewerkaftrek_rate_525")
        when 875...1225 then parameter_decimal("meewerkaftrek_rate_875")
        when 1225...1750 then parameter_decimal("meewerkaftrek_rate_1225")
        else
          hours >= 1750 ? parameter_decimal("meewerkaftrek_rate_1750") : BigDecimal("0")
        end

        profit * rate
      end

      def stakingsaftrek
        return BigDecimal("0") unless boolean(:business_ceased)
        return BigDecimal("0") if boolean(:stakingsaftrek_used_before)

        [ amount(:cessation_profit), parameter_decimal("stakingsaftrek_cap") ].min
      end

      def kia_deduction
        basis = amount(:kia_basis)
        lower_bound = parameter_decimal("kia_lower_bound")
        return BigDecimal("0") if basis < lower_bound

        first_cap = parameter_decimal("kia_first_cap")
        fixed_cap = parameter_decimal("kia_fixed_cap")
        phaseout_cap = parameter_decimal("kia_phaseout_cap")

        if basis <= first_cap
          basis * parameter_decimal("kia_rate")
        elsif basis <= fixed_cap
          parameter_decimal("kia_fixed_amount")
        elsif basis <= phaseout_cap
          [
            parameter_decimal("kia_fixed_amount") -
              ((basis - fixed_cap) * parameter_decimal("kia_phaseout_rate")),
            0
          ].max
        else
          BigDecimal("0")
        end
      end

      def private_vehicle_deduction
        amount(:private_vehicle_business_km) * parameter_decimal("private_vehicle_km_rate")
      end

      def mixed_cost_deduction
        costs = amount(:limited_deductible_costs_amount)
        return BigDecimal("0") unless costs.positive?

        if boolean(:choose_80_percent_method)
          costs * parameter_decimal("mixed_cost_deductible_rate")
        else
          [ costs - parameter_decimal("mixed_cost_fixed_nondeductible_amount"), 0 ].max
        end
      end

      def home_workspace_deduction
        return BigDecimal("0") unless boolean(:home_workspace_independent)

        amount(:home_workspace_costs)
      end

      def notes
        notes = [
          "Entrepreneur and hours-criterion eligibility are modeled explicitly; defaults preserve the previous calculator assumption that both are satisfied.",
          "Mixed costs use either the 80% method or the fixed non-deductible amount depending on the selected input.",
          "Home workspace costs are ignored unless the independent-workspace condition is selected."
        ]
        notes << "Cessation annuity premiums are passed to the personal-deduction layer and capped there by entered premium amount."
        notes
      end

      def self_employed_deduction_amount
        profile.fetch(:aow_eligible) ? parameter_decimal("self_employed_deduction_aow") :
          parameter_decimal("self_employed_deduction_under_aow")
      end

      def age_adjusted_amount(key)
        amount = parameter_decimal(key)
        profile.fetch(:aow_eligible) ? amount / 2 : amount
      end

      def standard_hours
        parameter_decimal("hours_criterion")
      end

      def boolean(key, default: false)
        value = inputs.key?(key) ? inputs[key] : default
        ActiveModel::Type::Boolean.new.cast(value)
      end

      def amount(key, default: 0)
        BigDecimal((inputs.key?(key) ? inputs[key] : default).to_s.presence || "0")
      rescue ArgumentError
        BigDecimal("0")
      end

      def parameter_decimal(key)
        ParameterReader.decimal(regime, key)
      end
    end
  end
end
