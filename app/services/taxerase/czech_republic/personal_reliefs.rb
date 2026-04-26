module Taxerase
  module CzechRepublic
    class PersonalReliefs
      BOOLEAN = ActiveModel::Type::Boolean.new.freeze

      def initialize(
        regime:,
        child_credit_claim_share:,
        apply_spouse_credit:,
        spouse_income:,
        spouse_ztp_p:,
        spouse_cares_child_under_three:,
        mortgage_interest_paid:,
        pension_contributions:,
        life_insurance_contributions:,
        donations_amount:
      )
        @regime = regime
        @child_credit_claim_share = child_credit_claim_share
        @apply_spouse_credit = apply_spouse_credit
        @spouse_income = spouse_income
        @spouse_ztp_p = spouse_ztp_p
        @spouse_cares_child_under_three = spouse_cares_child_under_three
        @mortgage_interest_paid = mortgage_interest_paid
        @pension_contributions = pension_contributions
        @life_insurance_contributions = life_insurance_contributions
        @donations_amount = donations_amount
      end

      def validation_errors
        errors = []
        errors << "child_credit_claim_share must be between 0 and 100" unless child_credit_multiplier.between?(0, 1)
        errors << "spouse_income must be 0 or greater" if parsed_spouse_income.negative?
        errors << "mortgage_interest_paid must be 0 or greater" if parsed_mortgage_interest_paid.negative?
        errors << "pension_contributions must be 0 or greater" if parsed_pension_contributions.negative?
        errors << "life_insurance_contributions must be 0 or greater" if parsed_life_insurance_contributions.negative?
        errors << "donations_amount must be 0 or greater" if parsed_donations_amount.negative?
        errors
      end

      def input_payload
        {
          child_credit_claim_share: round_percentage(child_credit_multiplier),
          apply_spouse_credit: truthy?(apply_spouse_credit),
          spouse_income: round_currency(parsed_spouse_income),
          spouse_ztp_p: truthy?(spouse_ztp_p),
          spouse_cares_child_under_three: truthy?(spouse_cares_child_under_three),
          mortgage_interest_paid: round_currency(parsed_mortgage_interest_paid),
          pension_contributions: round_currency(parsed_pension_contributions),
          life_insurance_contributions: round_currency(parsed_life_insurance_contributions),
          donations_amount: round_currency(parsed_donations_amount)
        }
      end

      def child_credit_multiplier
        @child_credit_multiplier ||= percentage_to_decimal(child_credit_claim_share)
      end

      def spouse_credit
        return BigDecimal("0") unless truthy?(apply_spouse_credit)
        return BigDecimal("0") unless truthy?(spouse_cares_child_under_three)
        return BigDecimal("0") if parsed_spouse_income > parameter_decimal!("spouse_income_limit")

        credit = parameter_decimal!("spouse_credit")
        return credit unless truthy?(spouse_ztp_p)

        credit * parameter_decimal!("spouse_ztp_p_multiplier")
      end

      def non_taxable_deductions_for(tax_base_before_deductions)
        [
          mortgage_interest_deduction,
          pension_life_deduction,
          donation_deduction_for(tax_base_before_deductions)
        ].sum
      end

      private

      attr_reader :regime, :child_credit_claim_share, :apply_spouse_credit, :spouse_income,
        :spouse_ztp_p, :spouse_cares_child_under_three, :mortgage_interest_paid,
        :pension_contributions, :life_insurance_contributions, :donations_amount

      def parsed_spouse_income
        @parsed_spouse_income ||= BigDecimal(spouse_income.to_s)
      rescue ArgumentError
        BigDecimal("-1")
      end

      def parsed_mortgage_interest_paid
        @parsed_mortgage_interest_paid ||= BigDecimal(mortgage_interest_paid.to_s)
      rescue ArgumentError
        BigDecimal("-1")
      end

      def parsed_pension_contributions
        @parsed_pension_contributions ||= BigDecimal(pension_contributions.to_s)
      rescue ArgumentError
        BigDecimal("-1")
      end

      def parsed_life_insurance_contributions
        @parsed_life_insurance_contributions ||= BigDecimal(life_insurance_contributions.to_s)
      rescue ArgumentError
        BigDecimal("-1")
      end

      def parsed_donations_amount
        @parsed_donations_amount ||= BigDecimal(donations_amount.to_s)
      rescue ArgumentError
        BigDecimal("-1")
      end

      def mortgage_interest_deduction
        [ parsed_mortgage_interest_paid, parameter_decimal!("mortgage_interest_cap") ].min
      end

      def pension_life_deduction
        [
          parsed_pension_contributions + parsed_life_insurance_contributions,
          parameter_decimal!("pension_life_contribution_cap")
        ].min
      end

      def donation_deduction_for(tax_base_before_deductions)
        return BigDecimal("0") if parsed_donations_amount < parameter_decimal!("donation_minimum_amount") &&
          parsed_donations_amount <= tax_base_before_deductions * parameter_decimal!("donation_minimum_tax_base_rate")

        [
          parsed_donations_amount,
          tax_base_before_deductions * parameter_decimal!("donation_tax_base_cap_rate")
        ].min
      end

      def parameter_decimal!(key)
        regime.parameter_decimal!(key)
      end

      def percentage_to_decimal(value)
        BigDecimal(value.to_s) / 100
      rescue ArgumentError
        BigDecimal("-1")
      end

      def truthy?(value)
        BOOLEAN.cast(value)
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
