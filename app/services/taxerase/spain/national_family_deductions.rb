module Taxerase
  module Spain
    class NationalFamilyDeductions
      include InputNormalization

      LARGE_FAMILY_CATEGORIES = %w[none general special].freeze

      def self.call(regime:, **kwargs)
        new(regime:, **kwargs).call
      end

      def self.validation_errors(**kwargs)
        new(regime: nil, **kwargs).validation_errors
      end

      def initialize(
        regime:,
        maternity_eligible_months: 0,
        nursery_expenses_paid: 0,
        large_family_category: "none",
        large_family_extra_children: 0,
        single_parent_two_children: false,
        disabled_descendants_count: 0,
        disabled_ascendants_count: 0,
        spouse_disability_dependant: false
      )
        @regime = regime
        @maternity_eligible_months = maternity_eligible_months
        @nursery_expenses_paid = nursery_expenses_paid
        @large_family_category = large_family_category.to_s.presence || "none"
        @large_family_extra_children = large_family_extra_children
        @single_parent_two_children = boolean(single_parent_two_children)
        @disabled_descendants_count = disabled_descendants_count
        @disabled_ascendants_count = disabled_ascendants_count
        @spouse_disability_dependant = boolean(spouse_disability_dependant)
      end

      def validation_errors
        errors = []
        errors << "maternity_eligible_months must be an integer between 0 and 12" unless parsed_maternity_months.between?(0, 12)
        errors << "nursery_expenses_paid must be 0 or greater" if parsed_nursery_expenses.negative?
        errors << "large_family_category is not supported" unless LARGE_FAMILY_CATEGORIES.include?(large_family_category)
        errors << "large_family_extra_children must be an integer between 0 and 12" unless parsed_large_family_extra_children.between?(0, 12)
        errors << "disabled_descendants_count must be an integer between 0 and 12" unless parsed_disabled_descendants_count.between?(0, 12)
        errors << "disabled_ascendants_count must be an integer between 0 and 12" unless parsed_disabled_ascendants_count.between?(0, 12)
        errors
      end

      def call
        items = deduction_items

        {
          items:,
          total: items.sum { |item| item.fetch(:amount) },
          summary: summary(items)
        }
      end

      private

      attr_reader :regime, :maternity_eligible_months, :nursery_expenses_paid, :large_family_category, :large_family_extra_children,
        :single_parent_two_children, :disabled_descendants_count, :disabled_ascendants_count, :spouse_disability_dependant

      def deduction_items
        [
          item("Maternity deduction", maternity_deduction),
          item("Nursery increment", nursery_deduction),
          item("Large family deduction", large_family_deduction),
          item("Single parent with two children deduction", single_parent_deduction),
          item("Disabled descendants in charge deduction", disability_deduction(parsed_disabled_descendants_count)),
          item("Disabled ascendants in charge deduction", disability_deduction(parsed_disabled_ascendants_count)),
          item("Spouse with disability in charge deduction", spouse_disability_deduction)
        ].compact
      end

      def item(label, amount)
        return nil unless amount.positive?

        { label:, amount: }
      end

      def maternity_deduction
        return BigDecimal("0") unless parsed_maternity_months.positive?

        parsed_maternity_months * parameter_decimal!("maternity_monthly_deduction")
      end

      def nursery_deduction
        return BigDecimal("0") unless parsed_nursery_expenses.positive?

        [ parsed_nursery_expenses, parameter_decimal!("nursery_deduction_cap") ].min
      end

      def large_family_deduction
        return BigDecimal("0") if large_family_category == "none" && parsed_large_family_extra_children.zero?

        base =
          case large_family_category
          when "general"
            parameter_decimal!("large_family_general_deduction")
          when "special"
            parameter_decimal!("large_family_special_deduction")
          else
            BigDecimal("0")
          end

        base + parsed_large_family_extra_children * parameter_decimal!("large_family_extra_child_deduction")
      end

      def single_parent_deduction
        single_parent_two_children ? parameter_decimal!("single_parent_two_children_deduction") : BigDecimal("0")
      end

      def disability_deduction(count)
        return BigDecimal("0") unless count.positive?

        count * parameter_decimal!("family_disability_deduction")
      end

      def spouse_disability_deduction
        spouse_disability_dependant ? parameter_decimal!("spouse_disability_deduction") : BigDecimal("0")
      end

      def summary(items)
        return "no national family deductions" if items.empty?

        items.map { |item| item.fetch(:label) }.join(", ")
      end

      def parsed_maternity_months
        @parsed_maternity_months ||= integer(maternity_eligible_months)
      end

      def parsed_large_family_extra_children
        @parsed_large_family_extra_children ||= integer(large_family_extra_children)
      end

      def parsed_disabled_descendants_count
        @parsed_disabled_descendants_count ||= integer(disabled_descendants_count)
      end

      def parsed_disabled_ascendants_count
        @parsed_disabled_ascendants_count ||= integer(disabled_ascendants_count)
      end

      def parsed_nursery_expenses
        @parsed_nursery_expenses ||= decimal(nursery_expenses_paid)
      end

      def parameter_decimal!(key)
        regime&.parameter_decimal!(key) || raise(KeyError, "Missing tax parameter #{key}")
      end
    end
  end
end
