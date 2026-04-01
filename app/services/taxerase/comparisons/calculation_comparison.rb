module Taxerase
  module Comparisons
    class CalculationComparison
      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      SUMMARY_METRICS = [
        {
          key: "annual_net_income",
          label: "Annual net income",
          value_type: "currency",
          higher_is_better: true
        },
        {
          key: "monthly_net_income",
          label: "Monthly net income",
          value_type: "currency",
          higher_is_better: true
        },
        {
          key: "effective_tax_rate",
          label: "Effective tax rate",
          value_type: "percentage_points",
          higher_is_better: false
        },
        {
          key: "total_tax",
          label: "Total tax",
          value_type: "currency",
          higher_is_better: false
        }
      ].freeze

      def self.call(
        left_country_code:,
        left_tax_regime_key:,
        right_country_code:,
        right_tax_regime_key:,
        tax_year:,
        selected_category:,
        gross_income:,
        salary_period:,
        deductible_expenses: 0,
        age_bracket: nil,
        children_count: 0,
        children_under_three_count: 0,
        disability_level: nil
      )
        new(
          left_country_code:,
          left_tax_regime_key:,
          right_country_code:,
          right_tax_regime_key:,
          tax_year:,
          selected_category:,
          gross_income:,
          salary_period:,
          deductible_expenses:,
          age_bracket:,
          children_count:,
          children_under_three_count:,
          disability_level:
        ).call
      end

      def initialize(
        left_country_code:,
        left_tax_regime_key:,
        right_country_code:,
        right_tax_regime_key:,
        tax_year:,
        selected_category:,
        gross_income:,
        salary_period:,
        deductible_expenses:,
        age_bracket:,
        children_count:,
        children_under_three_count:,
        disability_level:
      )
        @left_country_code = left_country_code
        @left_tax_regime_key = left_tax_regime_key
        @right_country_code = right_country_code
        @right_tax_regime_key = right_tax_regime_key
        @tax_year = tax_year.to_i
        @selected_category = selected_category
        @gross_income = gross_income
        @salary_period = salary_period
        @deductible_expenses = deductible_expenses
        @age_bracket = age_bracket
        @children_count = children_count
        @children_under_three_count = children_under_three_count
        @disability_level = disability_level
      end

      def call
        validate!

        {
          metadata: {
            tax_year: tax_year,
            selected_category: selected_category
          },
          left: comparison_side_payload(left_regime, left_result),
          right: comparison_side_payload(right_regime, right_result),
          summary_metrics: build_summary_metrics
        }
      end

      private

      attr_reader :left_country_code, :left_tax_regime_key, :right_country_code, :right_tax_regime_key, :tax_year,
        :selected_category, :gross_income, :salary_period, :deductible_expenses, :age_bracket, :children_count,
        :children_under_three_count, :disability_level

      def validate!
        errors = []
        errors << "left_country_code is required" if left_country_code.blank?
        errors << "left_tax_regime_key is required" if left_tax_regime_key.blank?
        errors << "right_country_code is required" if right_country_code.blank?
        errors << "right_tax_regime_key is required" if right_tax_regime_key.blank?
        errors << "selected_category must be employee or self_employed" unless %w[employee self_employed].include?(selected_category)
        errors << "tax_year must be a supported year" if tax_year <= 0

        errors.concat(regime_selection_errors)
        raise ValidationError.new(errors) if errors.any?
      end

      def regime_selection_errors
        errors = []
        errors << "left comparison selection is not available" if left_regime.blank?
        errors << "right comparison selection is not available" if right_regime.blank?
        return errors if errors.any?

        if left_regime[:category] != selected_category
          errors << "left comparison selection does not match the selected tax profile"
        end
        if right_regime[:category] != selected_category
          errors << "right comparison selection does not match the selected tax profile"
        end

        errors
      end

      def left_result
        @left_result ||= calculate_side(left_country_code, left_tax_regime_key)
      end

      def right_result
        @right_result ||= calculate_side(right_country_code, right_tax_regime_key)
      end

      def left_regime
        @left_regime ||= find_public_regime(left_country_code, left_tax_regime_key)
      end

      def right_regime
        @right_regime ||= find_public_regime(right_country_code, right_tax_regime_key)
      end

      def calculate_side(country_code, tax_regime_key)
        normalized_input = normalized_comparison_input_for(country_code)

        router_for(country_code).call(
          gross_income: gross_income,
          salary_period: salary_period,
          tax_year: tax_year,
          tax_regime_key: tax_regime_key,
          deductible_expenses: selected_category == "self_employed" ? deductible_expenses : 0,
          age_bracket: normalized_input[:age_bracket],
          children_count: normalized_input[:children_count],
          children_under_three_count: normalized_input[:children_under_three_count],
          disability_level: normalized_input[:disability_level]
        )
      rescue StandardError => error
        raise error if error.is_a?(ValidationError)
        raise ValidationError.new(error.respond_to?(:errors) ? error.errors : [ error.message ])
      end

      def find_public_regime(country_code, tax_regime_key)
        definition = Taxerase::CountryCalculators::Registry.fetch(country_code)

        definition.public_catalog[:regime_options].find do |regime|
          regime[:tax_year] == tax_year && regime[:key] == tax_regime_key
        end
      rescue KeyError
        nil
      end

      def router_for(country_code)
        Taxerase::CountryCalculators::Registry.fetch(country_code).calculation_router
      end

      def normalized_comparison_input_for(country_code)
        Taxerase::CountryCalculators::Registry.fetch(country_code).normalize_comparison_input(
          age_bracket: age_bracket,
          children_count: children_count,
          children_under_three_count: children_under_three_count,
          disability_level: disability_level
        )
      end

      def comparison_side_payload(regime, result)
        {
          country_code: result.dig(:metadata, :country_code),
          country_name: result.dig(:metadata, :country_name),
          region: regime[:region],
          tax_regime_key: result.dig(:metadata, :tax_regime_key),
          tax_regime_name: result.dig(:metadata, :tax_regime_name)
        }
      end

      def build_summary_metrics
        SUMMARY_METRICS.map do |metric|
          left_value = left_result.dig(:breakdown, metric.fetch(:key).to_sym)
          right_value = right_result.dig(:breakdown, metric.fetch(:key).to_sym)
          delta = round_metric(right_value - left_value, metric.fetch(:value_type))

          {
            key: metric.fetch(:key),
            label: metric.fetch(:label),
            value_type: metric.fetch(:value_type),
            higher_is_better: metric.fetch(:higher_is_better),
            left_value:,
            right_value:,
            delta_value: delta,
            preferred_side: preferred_side(metric.fetch(:higher_is_better), left_value, right_value)
          }
        end
      end

      def preferred_side(higher_is_better, left_value, right_value)
        return "tie" if left_value == right_value

        if higher_is_better
          right_value > left_value ? "right" : "left"
        else
          right_value < left_value ? "right" : "left"
        end
      end

      def round_metric(value, value_type)
        precision = value_type == "percentage_points" ? 2 : 2
        value.round(precision)
      end
    end
  end
end
