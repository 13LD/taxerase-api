module Taxerase
  module Spain
    class PersonalFamilyMinimums
      include InputNormalization

      AGE_BRACKETS = %w[under_65 from_65_to_74 age_75_plus].freeze
      DISABILITY_LEVELS = %w[none level_33_to_64 level_33_to_64_with_support level_65_plus].freeze

      def self.call(
        regime:,
        age_bracket:,
        children_count:,
        children_under_three_count:,
        disability_level:,
        ascendants_count: 0,
        ascendants_over_75_count: 0,
        ascendant_disability_33_count: 0,
        ascendant_disability_65_count: 0,
        ascendant_disability_support_count: 0
      )
        new(
          regime:,
          age_bracket:,
          children_count:,
          children_under_three_count:,
          disability_level:,
          ascendants_count:,
          ascendants_over_75_count:,
          ascendant_disability_33_count:,
          ascendant_disability_65_count:,
          ascendant_disability_support_count:
        ).call
      end

      def self.validation_errors(
        age_bracket:,
        children_count:,
        children_under_three_count:,
        disability_level:,
        ascendants_count: 0,
        ascendants_over_75_count: 0,
        ascendant_disability_33_count: 0,
        ascendant_disability_65_count: 0,
        ascendant_disability_support_count: 0
      )
        new(
          regime: nil,
          age_bracket:,
          children_count:,
          children_under_three_count:,
          disability_level:,
          ascendants_count:,
          ascendants_over_75_count:,
          ascendant_disability_33_count:,
          ascendant_disability_65_count:,
          ascendant_disability_support_count:
        ).validation_errors
      end

      def initialize(
        regime:,
        age_bracket:,
        children_count:,
        children_under_three_count:,
        disability_level:,
        ascendants_count:,
        ascendants_over_75_count:,
        ascendant_disability_33_count:,
        ascendant_disability_65_count:,
        ascendant_disability_support_count:
      )
        @regime = regime
        @age_bracket = age_bracket.to_s.presence || "under_65"
        @children_count = children_count
        @children_under_three_count = children_under_three_count
        @disability_level = disability_level.to_s.presence || "none"
        @ascendants_count = ascendants_count
        @ascendants_over_75_count = ascendants_over_75_count
        @ascendant_disability_33_count = ascendant_disability_33_count
        @ascendant_disability_65_count = ascendant_disability_65_count
        @ascendant_disability_support_count = ascendant_disability_support_count
      end

      def validation_errors
        errors = []
        errors << "age_bracket is not supported" unless AGE_BRACKETS.include?(age_bracket)
        errors << "disability_level is not supported" unless DISABILITY_LEVELS.include?(disability_level)
        errors << "children_count must be an integer between 0 and 12" unless parsed_children_count.between?(0, 12)
        errors << "children_under_three_count must be an integer between 0 and children_count" unless parsed_children_under_three_count.between?(0, parsed_children_count)
        errors << "ascendants_count must be an integer between 0 and 12" unless parsed_ascendants_count.between?(0, 12)
        errors << "ascendants_over_75_count must be an integer between 0 and ascendants_count" unless parsed_ascendants_over_75_count.between?(0, parsed_ascendants_count)
        errors << "ascendant_disability_33_count must be an integer between 0 and ascendants_count" unless parsed_ascendant_disability_33_count.between?(0, parsed_ascendants_count)
        errors << "ascendant_disability_65_count must be an integer between 0 and ascendants_count" unless parsed_ascendant_disability_65_count.between?(0, parsed_ascendants_count)
        errors << "ascendant disability counts must not exceed ascendants_count" unless disabled_ascendants_count.between?(0, parsed_ascendants_count)
        errors << "ascendant_disability_support_count must be an integer between 0 and disabled ascendants" unless parsed_ascendant_disability_support_count.between?(0, disabled_ascendants_count)
        errors
      end

      def call
        {
          state_amount: state_amount,
          regional_amount: regional_amount,
          age_bracket: age_bracket,
          children_count: parsed_children_count,
          children_under_three_count: parsed_children_under_three_count,
          ascendants_count: parsed_ascendants_count,
          ascendants_over_75_count: parsed_ascendants_over_75_count,
          ascendant_disability_33_count: parsed_ascendant_disability_33_count,
          ascendant_disability_65_count: parsed_ascendant_disability_65_count,
          ascendant_disability_support_count: parsed_ascendant_disability_support_count,
          disability_level: disability_level,
          state_common_additions: state_common_additions,
          regional_common_additions: regional_common_additions,
          summary: summary
        }
      end

      private

      attr_reader :regime, :age_bracket, :children_count, :children_under_three_count, :disability_level,
        :ascendants_count, :ascendants_over_75_count, :ascendant_disability_33_count, :ascendant_disability_65_count,
        :ascendant_disability_support_count

      def parsed_children_count
        @parsed_children_count ||= integer(children_count)
      end

      def parsed_children_under_three_count
        @parsed_children_under_three_count ||= integer(children_under_three_count)
      end

      def parsed_ascendants_count
        @parsed_ascendants_count ||= integer(ascendants_count)
      end

      def parsed_ascendants_over_75_count
        @parsed_ascendants_over_75_count ||= integer(ascendants_over_75_count)
      end

      def parsed_ascendant_disability_33_count
        @parsed_ascendant_disability_33_count ||= integer(ascendant_disability_33_count)
      end

      def parsed_ascendant_disability_65_count
        @parsed_ascendant_disability_65_count ||= integer(ascendant_disability_65_count)
      end

      def parsed_ascendant_disability_support_count
        @parsed_ascendant_disability_support_count ||= integer(ascendant_disability_support_count)
      end

      def state_amount
        parameter_decimal!("state_taxpayer_minimum") + state_common_additions
      end

      def regional_amount
        parameter_decimal!("regional_taxpayer_minimum") + regional_common_additions
      end

      def state_common_additions
        age_increment + descendant_minimum + ascendant_minimum + disability_minimum + ascendant_disability_minimum
      end

      alias regional_common_additions state_common_additions

      def age_increment
        case age_bracket
        when "under_65"
          BigDecimal("0")
        when "from_65_to_74"
          parameter_decimal!("taxpayer_age_65_increment")
        when "age_75_plus"
          parameter_decimal!("taxpayer_age_65_increment") + parameter_decimal!("taxpayer_age_75_increment")
        else
          BigDecimal("0")
        end
      end

      def descendant_minimum
        total = BigDecimal("0")

        parsed_children_count.times do |index|
          total +=
            case index
            when 0
              parameter_decimal!("first_descendant_minimum")
            when 1
              parameter_decimal!("second_descendant_minimum")
            when 2
              parameter_decimal!("third_descendant_minimum")
            else
              parameter_decimal!("fourth_and_next_descendant_minimum")
            end
        end

        total + (parameter_decimal!("descendant_under_three_minimum") * parsed_children_under_three_count)
      end

      def ascendant_minimum
        return BigDecimal("0") if parsed_ascendants_count.zero? && parsed_ascendants_over_75_count.zero?

        (parameter_decimal!("ascendant_minimum") * parsed_ascendants_count) +
          (parameter_decimal!("ascendant_over_75_increment") * parsed_ascendants_over_75_count)
      end

      def disability_minimum
        case disability_level
        when "none"
          BigDecimal("0")
        when "level_33_to_64"
          parameter_decimal!("taxpayer_disability_33_minimum")
        when "level_33_to_64_with_support"
          parameter_decimal!("taxpayer_disability_33_minimum") + parameter_decimal!("taxpayer_disability_support_increment")
        when "level_65_plus"
          parameter_decimal!("taxpayer_disability_65_minimum") + parameter_decimal!("taxpayer_disability_support_increment")
        else
          BigDecimal("0")
        end
      end

      def ascendant_disability_minimum
        return BigDecimal("0") if disabled_ascendants_count.zero? && parsed_ascendant_disability_support_count.zero?

        (parameter_decimal!("ascendant_disability_33_minimum") * parsed_ascendant_disability_33_count) +
          (parameter_decimal!("ascendant_disability_65_minimum") * parsed_ascendant_disability_65_count) +
          (parameter_decimal!("ascendant_disability_support_increment") * parsed_ascendant_disability_support_count)
      end

      def disabled_ascendants_count
        parsed_ascendant_disability_33_count + parsed_ascendant_disability_65_count
      end

      def summary
        parts = []
        parts << age_summary
        parts << children_summary
        parts << ascendants_summary
        parts << disability_summary
        parts.join(", ")
      end

      def age_summary
        case age_bracket
        when "under_65"
          "under 65"
        when "from_65_to_74"
          "65 to 74"
        when "age_75_plus"
          "75 or older"
        end
      end

      def children_summary
        child_label =
          case parsed_children_count
          when 0
            "no children"
          when 1
            "1 child"
          else
            "#{parsed_children_count} children"
          end

        return child_label if parsed_children_under_three_count.zero?

        under_three_label =
          if parsed_children_under_three_count == 1
            "1 under 3"
          else
            "#{parsed_children_under_three_count} under 3"
          end

        "#{child_label} (#{under_three_label})"
      end

      def disability_summary
        case disability_level
        when "none"
          "no taxpayer disability"
        when "level_33_to_64"
          "taxpayer disability 33% to 64%"
        when "level_33_to_64_with_support"
          "taxpayer disability 33% to 64% with reduced mobility or support needs"
        when "level_65_plus"
          "taxpayer disability 65% or more"
        end
      end

      def ascendants_summary
        label =
          case parsed_ascendants_count
          when 0
            "no ascendants"
          when 1
            "1 ascendant"
          else
            "#{parsed_ascendants_count} ascendants"
          end

        details = []
        details << "#{parsed_ascendants_over_75_count} over 75" if parsed_ascendants_over_75_count.positive?
        details << "#{disabled_ascendants_count} disabled" if disabled_ascendants_count.positive?

        return label if details.empty?

        "#{label} (#{details.join(', ')})"
      end

      def parameter_decimal!(key)
        regime&.parameter_decimal!(key) || raise(KeyError, "Missing tax parameter #{key}")
      end
    end
  end
end
