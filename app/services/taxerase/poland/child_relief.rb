module Taxerase
  module Poland
    class ChildRelief
      CHILD_RELIEF_KEYS = {
        1 => "child_relief_first_child",
        2 => "child_relief_second_child",
        3 => "child_relief_third_child",
        4 => "child_relief_fourth_plus_child"
      }.freeze

      def self.call(regime:, children_count:)
        parsed_children_count = Integer(children_count.to_s, exception: false) || 0
        return BigDecimal("0") if parsed_children_count <= 0

        (1..parsed_children_count).sum do |child_index|
          key = CHILD_RELIEF_KEYS.fetch([ child_index, 4 ].min)
          regime.parameter_decimal!(key)
        end
      end
    end
  end
end
