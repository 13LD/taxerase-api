module Taxerase
  module Andorra
    module CalculatorSupport
      DISABILITY_LEVELS = %w[none recognized_disability].freeze
      ZERO_VALUE_DETAIL_CARD_LABELS = [
        "Spouse phase-in increment",
        "Dependent disability uplift",
        "Habitual-home investment base reduction",
        "Affordable-rental housing investment base reduction",
        "Higher-education tuition reduction",
        "Housing rent support estimate (non-tax)"
      ].freeze
      HOUSING_SUPPORT_ASSUMPTION = "Housing rent support is shown as a separate sourced estimate outside IRPF and CASS totals. Use it only when the selected-year housing-support conditions are met.".freeze

      private

      def common_andorra_validation_errors(include_deductible_expenses: false)
        errors = []
        errors << "children_count must be 0 or greater" if parsed_children_count.negative?
        errors << "ascendants_count must be 0 or greater" if parsed_ascendants_count.negative?
        errors << "disabled_dependents_count must be 0 or greater" if parsed_disabled_dependents_count.negative?
        if parsed_disabled_dependents_count > parsed_children_count + parsed_ascendants_count
          errors << "disabled_dependents_count cannot exceed the total number of declared dependents"
        end
        errors << "disability_level must be one of: #{DISABILITY_LEVELS.join(', ')}" unless DISABILITY_LEVELS.include?(disability_level.to_s)
        errors.concat(TaxRelief.validation_errors(
          children_count: parsed_children_count + parsed_ascendants_count,
          disability_level: disability_level,
          has_spouse_or_partner: has_spouse_or_partner,
          spouse_without_income: spouse_without_income,
          spouse_general_income: spouse_general_income,
          disabled_dependents_count: parsed_disabled_dependents_count,
          mortgage_interest: mortgage_interest,
          home_acquisition_investment: home_acquisition_investment,
          affordable_rental_housing_investment: affordable_rental_housing_investment,
          higher_education_tuition: higher_education_tuition,
          pension_contributions: pension_contributions,
          alimony_paid: alimony_paid
        ))
        errors.concat(HousingSupport.validation_errors(
          apply_housing_rent_support: apply_housing_rent_support,
          housing_support_priority_group: housing_support_priority_group,
          housing_rent: housing_rent
        ))

        if include_deductible_expenses
          errors << "deductible_expenses must be 0 or greater" if parsed_deductible_expenses.negative?
          errors << "deductible_expenses is too large for the current calculator" if parsed_deductible_expenses > 50_000_000
        end

        errors
      rescue ArgumentError
        fallback_errors = [
          "children_count must be 0 or greater",
          "ascendants_count must be 0 or greater",
          "disabled_dependents_count must be 0 or greater"
        ]
        include_deductible_expenses ? fallback_errors + [ "deductible_expenses must be 0 or greater" ] : fallback_errors
      end

      def build_common_input_payload(annual_gross_income:)
        {
          gross_income: round_currency(parsed_gross_income),
          salary_period: normalized_salary_period,
          tax_year: tax_year,
          annual_gross_income: round_currency(annual_gross_income),
          monthly_gross_income: round_currency(annual_gross_income / 12),
          age_bracket: "standard",
          children_count: parsed_children_count,
          children_under_three_count: 0,
          disability_level: disability_level.to_s,
          ascendants_count: parsed_ascendants_count,
          disabled_dependents_count: parsed_disabled_dependents_count,
          has_spouse_or_partner: has_spouse_or_partner?,
          spouse_without_income: spouse_without_income?,
          spouse_general_income: round_currency(parsed_spouse_general_income),
          mortgage_interest: round_currency(parsed_mortgage_interest),
          home_acquisition_investment: round_currency(parsed_home_acquisition_investment),
          affordable_rental_housing_investment: round_currency(parsed_affordable_rental_housing_investment),
          higher_education_tuition: round_currency(parsed_higher_education_tuition),
          pension_contributions: round_currency(parsed_pension_contributions),
          alimony_paid: round_currency(parsed_alimony_paid),
          apply_housing_rent_support: apply_housing_rent_support?,
          housing_support_priority_group: housing_support_priority_group?,
          housing_rent: round_currency(parsed_housing_rent)
        }
      end

      def andorra_tax_relief(net_general_income:)
        @andorra_tax_relief ||= {}
        cache_key = net_general_income.to_s("F")
        total_dependents = parsed_children_count + parsed_ascendants_count

        @andorra_tax_relief[cache_key] ||= begin
          reductions = TaxRelief.reductions(
            children_count: total_dependents,
            disability_level: disability_level,
            has_spouse_or_partner: has_spouse_or_partner,
            spouse_without_income: spouse_without_income,
            spouse_general_income: spouse_general_income,
            disabled_dependents_count: parsed_disabled_dependents_count,
            mortgage_interest: mortgage_interest,
            home_acquisition_investment: home_acquisition_investment,
            affordable_rental_housing_investment: affordable_rental_housing_investment,
            higher_education_tuition: higher_education_tuition,
            pension_contributions: pension_contributions,
            alimony_paid: alimony_paid,
            net_general_income: net_general_income,
            parameter_decimal: method(:parameter_decimal)
          )
        end
      end

      def andorra_housing_support
        @andorra_housing_support ||= HousingSupport.estimate(
          annual_housing_rent: parsed_housing_rent,
          apply_housing_rent_support: apply_housing_rent_support,
          housing_support_priority_group: housing_support_priority_group,
          parameter_decimal: method(:parameter_decimal)
        )
      end

      def parsed_gross_income
        @parsed_gross_income ||= BigDecimal(gross_income.to_s)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_deductible_expenses
        @parsed_deductible_expenses ||= BigDecimal(deductible_expenses.to_s)
      rescue ArgumentError
        BigDecimal("0")
      end

      def parsed_children_count
        @parsed_children_count ||= TaxRelief.parse_count(children_count)
      end

      def parsed_ascendants_count
        @parsed_ascendants_count ||= TaxRelief.parse_count(ascendants_count)
      end

      def parsed_disabled_dependents_count
        @parsed_disabled_dependents_count ||= TaxRelief.parse_count(disabled_dependents_count)
      end

      def parsed_mortgage_interest
        @parsed_mortgage_interest ||= TaxRelief.parse_amount(mortgage_interest)
      end

      def parsed_home_acquisition_investment
        @parsed_home_acquisition_investment ||= TaxRelief.parse_amount(home_acquisition_investment)
      end

      def parsed_affordable_rental_housing_investment
        @parsed_affordable_rental_housing_investment ||= TaxRelief.parse_amount(affordable_rental_housing_investment)
      end

      def parsed_higher_education_tuition
        @parsed_higher_education_tuition ||= TaxRelief.parse_amount(higher_education_tuition)
      end

      def parsed_spouse_general_income
        @parsed_spouse_general_income ||= TaxRelief.parse_amount(spouse_general_income)
      end

      def parsed_pension_contributions
        @parsed_pension_contributions ||= TaxRelief.parse_amount(pension_contributions)
      end

      def parsed_alimony_paid
        @parsed_alimony_paid ||= TaxRelief.parse_amount(alimony_paid)
      end

      def parsed_housing_rent
        @parsed_housing_rent ||= HousingSupport.parse_amount(housing_rent)
      end

      def has_spouse_or_partner?
        TaxRelief.boolean_value?(has_spouse_or_partner)
      end

      def spouse_without_income?
        TaxRelief.boolean_value?(spouse_without_income)
      end

      def apply_housing_rent_support?
        HousingSupport.boolean_value?(apply_housing_rent_support)
      end

      def housing_support_priority_group?
        HousingSupport.boolean_value?(housing_support_priority_group)
      end

      def normalized_salary_period
        @normalized_salary_period ||= salary_period.to_s.upcase
      end

      def normalize_annual_gross_income
        normalized_salary_period == "MONTH" ? parsed_gross_income * 12 : parsed_gross_income
      end

      def country_record
        @country_record ||= Taxerase::Andorra::CalculationRouter.country
      end

      def parameter_decimal(key)
        value = regime.tax_parameters.find { |parameter| parameter.key == key }&.value_decimal
        return value.to_d if value.present?

        seeded_default_parameter_decimal(key)
      end

      def seeded_default_parameter_decimal(key)
        values =
          if tax_year.to_i >= 2025
            {
              "dependent_reduction" => BigDecimal("1000"),
              "family_member_disability_extra" => BigDecimal("500"),
              "habitual_home_investment_reduction_rate" => BigDecimal("0.50"),
              "habitual_home_investment_reduction_cap" => BigDecimal("5000"),
              "affordable_rental_housing_investment_reduction_rate" => BigDecimal("0.50"),
              "affordable_rental_housing_investment_reduction_cap" => BigDecimal("5000"),
              "higher_education_tuition_reduction_cap" => BigDecimal("300")
            }
          else
            {
              "dependent_reduction" => BigDecimal("750"),
              "family_member_disability_extra" => BigDecimal("375"),
              "habitual_home_investment_reduction_rate" => BigDecimal("0.25"),
              "habitual_home_investment_reduction_cap" => BigDecimal("1000"),
              "affordable_rental_housing_investment_reduction_rate" => BigDecimal("0"),
              "affordable_rental_housing_investment_reduction_cap" => BigDecimal("0"),
              "higher_education_tuition_reduction_cap" => BigDecimal("0")
            }
          end

        values.fetch(key) { raise KeyError, "Missing tax parameter #{key} for #{regime.key}" }
      end

      def round_currency(amount)
        amount.round(2).to_f
      end

      def round_percentage(decimal)
        (decimal * 100).round(2).to_f
      end

      def supported_reductions_assumption(include_taxpayer_disability:)
        reduction_labels = [
          ("taxpayer disability uplift" if include_taxpayer_disability),
          "spouse or partner no-income or partial-income personal-minimum phase-in",
          "dependents",
          "dependent disability uplift",
          "habitual-home investment base reduction",
          "affordable-rental housing investment base reduction",
          "higher-education tuition reduction",
          "pension contributions",
          "alimony paid"
        ].compact.join(", ")

        "Supported reductions in this calculator: #{reduction_labels}."
      end

      def append_housing_support_assumption(base_assumptions)
        return base_assumptions unless apply_housing_rent_support?

        base_assumptions + [ HOUSING_SUPPORT_ASSUMPTION ]
      end

      def prune_zero_value_detail_cards(cards)
        cards.reject do |card|
          card[:value].zero? && ZERO_VALUE_DETAIL_CARD_LABELS.include?(card[:label])
        end
      end
    end
  end
end
