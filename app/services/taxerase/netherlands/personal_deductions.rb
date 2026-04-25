module Taxerase
  module Netherlands
    class PersonalDeductions
      HEALTHCARE_KEYS = %i[
        healthcare_medicines_prescription
        healthcare_aids_and_adaptations
        healthcare_transport
        healthcare_diet_prescribed
        healthcare_extra_family_help
        healthcare_extra_clothing_bedding
        healthcare_other_eligible
      ].freeze

      def self.call(**attributes)
        new(**attributes).call
      end

      def initialize(regime:, profile:, taxable_income:, combined_income:, inputs: {})
        @regime = regime
        @profile = profile
        @taxable_income = BigDecimal(taxable_income.to_s)
        @combined_income = BigDecimal(combined_income.to_s)
        @inputs = inputs || {}
      end

      def call
        components = {
          partner_alimony: amount(:partner_alimony_paid),
          healthcare_costs: healthcare_deduction,
          temporary_home_stay_disabled: temporary_home_stay_deduction,
          gifts: gift_deduction,
          aov_premiums: amount(:deductible_aov_premium),
          lijfrente_premiums: amount(:deductible_lijfrente_premium),
          cessation_annuity_premiums: amount(:cessation_annuity_premium)
        }
        current_year_total = components.values.sum(BigDecimal("0"))
        prior_carryforward = amount(:remaining_personal_deduction_carryforward)
        total_available = current_year_total + prior_carryforward
        applied = [ total_available, taxable_income ].min
        carryforward = [ total_available - applied, 0 ].max

        {
          components:,
          current_year_total:,
          prior_carryforward:,
          total_available:,
          applied:,
          carryforward:,
          taxable_income_after_deductions: [ taxable_income - applied, 0 ].max,
          notes: notes
        }
      end

      private

      attr_reader :regime, :profile, :taxable_income, :combined_income, :inputs

      def healthcare_deduction
        eligible_costs = HEALTHCARE_KEYS.sum { |key| amount(key) }
        uplifted_costs = eligible_costs * healthcare_uplift_multiplier
        threshold = combined_income * parameter_decimal("healthcare_cost_threshold_rate")

        [ uplifted_costs - threshold, 0 ].max
      end

      def healthcare_uplift_multiplier
        return BigDecimal("1") if combined_income > parameter_decimal("healthcare_uplift_income_ceiling")

        BigDecimal("1") + if profile.fetch(:aow_eligible)
          parameter_decimal("healthcare_uplift_rate_aow")
        else
          parameter_decimal("healthcare_uplift_rate_under_aow")
        end
      end

      def temporary_home_stay_deduction
        (amount(:temporary_home_stay_disabled_km) * parameter_decimal("temporary_home_stay_km_rate")) +
          (amount(:temporary_home_stay_disabled_days) * parameter_decimal("temporary_home_stay_day_rate"))
      end

      def gift_deduction
        ordinary = amount(:ordinary_anbi_gifts)
        periodic = amount(:periodic_anbi_gifts)
        cultural = amount(:cultural_anbi_gifts)
        cultural_uplift = [
          cultural * parameter_decimal("cultural_gift_uplift_rate"),
          parameter_decimal("cultural_gift_uplift_cap")
        ].min
        ordinary_threshold = [ combined_income * parameter_decimal("ordinary_gift_threshold_rate"),
          parameter_decimal("ordinary_gift_min_threshold") ].max
        ordinary_cap = combined_income * parameter_decimal("ordinary_gift_income_cap_rate")
        deductible_ordinary = [ [ ordinary + cultural, ordinary_cap ].min - ordinary_threshold, 0 ].max

        periodic + deductible_ordinary + cultural_uplift
      end

      def notes
        [
          "Remaining personal deductions are applied against Box 1 taxable income first and carried forward when they exceed the available taxable base.",
          "Healthcare costs use the documented threshold and low-income uplift inputs; non-modeled statutory exclusions are expected to be filtered before entry.",
          "Gift deductions model ordinary, periodic, and cultural ANBI gifts with the cultural uplift cap."
        ]
      end

      def amount(key)
        BigDecimal(inputs[key].to_s.presence || "0")
      rescue ArgumentError
        BigDecimal("0")
      end

      def parameter_decimal(key)
        ParameterReader.decimal(regime, key)
      end
    end
  end
end
