module Taxerase
  module Netherlands
    class TaxCredits
      def self.call(**attributes)
        new(**attributes).call
      end

      def initialize(
        regime:,
        profile:,
        taxable_income:,
        labour_income:,
        fiscal_partner: false,
        partner_labour_income: 0,
        children_under_12_count: 0,
        single_aow_household: false,
        wajong_status: false,
        green_investments_value: 0
      )
        @regime = regime
        @profile = profile
        @taxable_income = decimal(taxable_income)
        @labour_income = decimal(labour_income)
        @fiscal_partner = ActiveModel::Type::Boolean.new.cast(fiscal_partner)
        @partner_labour_income = decimal(partner_labour_income)
        @children_under_12_count = (children_under_12_count.presence || 0).to_i
        @single_aow_household = ActiveModel::Type::Boolean.new.cast(single_aow_household)
        @wajong_status = ActiveModel::Type::Boolean.new.cast(wajong_status)
        @green_investments_value = decimal(green_investments_value)
      end

      def call
        components = {
          general_tax_credit: general_tax_credit,
          labour_tax_credit: labour_tax_credit,
          income_dependent_combination_credit: income_dependent_combination_credit,
          older_person_credit: older_person_credit,
          single_older_person_credit: single_older_person_credit,
          young_disabled_credit: young_disabled_credit,
          green_investment_credit: green_investment_credit
        }

        {
          components:,
          total: components.values.sum(BigDecimal("0")),
          eligibility: {
            iack: iack_eligible?,
            fiscal_partner: fiscal_partner,
            older_person: profile.fetch(:aow_eligible),
            single_older_person: single_aow_household && profile.fetch(:aow_eligible),
            young_disabled: wajong_status && !profile.fetch(:aow_eligible)
          }
        }
      end

      private

      attr_reader :regime, :profile, :taxable_income, :labour_income, :fiscal_partner,
        :partner_labour_income, :children_under_12_count, :single_aow_household,
        :wajong_status, :green_investments_value

      def general_tax_credit
        FormulaBrackets.call(
          regime:,
          bracket_group: profile.fetch(:aow_eligible) ? "general_tax_credit_aow" : "general_tax_credit_under_aow",
          amount: taxable_income
        )
      end

      def labour_tax_credit
        FormulaBrackets.call(
          regime:,
          bracket_group: profile.fetch(:aow_eligible) ? "labour_tax_credit_aow" : "labour_tax_credit_under_aow",
          amount: labour_income
        )
      end

      def income_dependent_combination_credit
        return BigDecimal("0") unless iack_eligible?

        threshold = parameter_decimal("iack_income_threshold")
        max_credit = parameter_decimal("iack_max_credit")
        rate = parameter_decimal("iack_rate")

        [ (labour_income - threshold) * rate, max_credit ].min.clamp(BigDecimal("0"), max_credit)
      end

      def iack_eligible?
        return false if profile.fetch(:aow_eligible)
        return false unless children_under_12_count.positive?
        return false unless labour_income > parameter_decimal("iack_income_threshold")

        !fiscal_partner || labour_income < partner_labour_income
      end

      def older_person_credit
        return BigDecimal("0") unless profile.fetch(:aow_eligible)

        max_credit = parameter_decimal("older_person_credit_max")
        threshold = parameter_decimal("older_person_credit_income_threshold")
        reduction_rate = parameter_decimal("older_person_credit_reduction_rate")
        reduction = [ taxable_income - threshold, 0 ].max * reduction_rate

        [ max_credit - reduction, 0 ].max
      end

      def single_older_person_credit
        return BigDecimal("0") unless single_aow_household && profile.fetch(:aow_eligible)

        parameter_decimal("single_older_person_credit")
      end

      def young_disabled_credit
        return BigDecimal("0") unless wajong_status && !profile.fetch(:aow_eligible)

        parameter_decimal("young_disabled_credit")
      end

      def green_investment_credit
        exemption_cap = fiscal_partner ? parameter_decimal("green_investment_exemption_partner") :
          parameter_decimal("green_investment_exemption_single")
        eligible_value = [ green_investments_value, exemption_cap ].min

        eligible_value * parameter_decimal("green_investment_credit_rate")
      end

      def parameter_decimal(key)
        ParameterReader.decimal(regime, key)
      end

      def decimal(value)
        BigDecimal(value.to_s.presence || "0")
      rescue ArgumentError
        BigDecimal("0")
      end
    end
  end
end
