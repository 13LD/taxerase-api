module Taxerase
  module Spain
    class EmployeeExpenses
      include InputNormalization

      DISABLED_WORKER_STATUSES = %w[none level_33_to_64 level_65_plus_or_support].freeze

      def self.call(regime:, union_dues:, professional_fees:, legal_defense_costs:, disabled_worker_status:, geographic_mobility:)
        new(
          regime:,
          union_dues:,
          professional_fees:,
          legal_defense_costs:,
          disabled_worker_status:,
          geographic_mobility:
        ).call
      end

      def self.validation_errors(union_dues:, professional_fees:, legal_defense_costs:, disabled_worker_status:)
        new(
          regime: nil,
          union_dues:,
          professional_fees:,
          legal_defense_costs:,
          disabled_worker_status:,
          geographic_mobility: false
        ).validation_errors
      end

      def initialize(regime:, union_dues:, professional_fees:, legal_defense_costs:, disabled_worker_status:, geographic_mobility:)
        @regime = regime
        @union_dues = union_dues
        @professional_fees = professional_fees
        @legal_defense_costs = legal_defense_costs
        @disabled_worker_status = disabled_worker_status.to_s.presence || "none"
        @geographic_mobility = boolean(geographic_mobility)
      end

      def validation_errors
        errors = []
        errors << "union_dues must be 0 or greater" if parsed_union_dues.negative?
        errors << "professional_fees must be 0 or greater" if parsed_professional_fees.negative?
        errors << "legal_defense_costs must be 0 or greater" if parsed_legal_defense_costs.negative?
        errors << "disabled_worker_status is not supported" unless DISABLED_WORKER_STATUSES.include?(disabled_worker_status)
        errors
      end

      def call
        {
          union_dues: parsed_union_dues,
          professional_fees: professional_fees_deduction,
          legal_defense_costs: legal_defense_deduction,
          disabled_worker_expense: disabled_worker_expense,
          geographic_mobility_expense: geographic_mobility_expense,
          total: total,
          summary: summary
        }
      end

      private

      attr_reader :regime, :union_dues, :professional_fees, :legal_defense_costs, :disabled_worker_status, :geographic_mobility

      def parsed_union_dues
        @parsed_union_dues ||= decimal(union_dues)
      end

      def parsed_professional_fees
        @parsed_professional_fees ||= decimal(professional_fees)
      end

      def parsed_legal_defense_costs
        @parsed_legal_defense_costs ||= decimal(legal_defense_costs)
      end

      def professional_fees_deduction
        return BigDecimal("0") unless parsed_professional_fees.positive?

        [ parsed_professional_fees, parameter_decimal!("professional_fee_deduction_cap") ].min
      end

      def legal_defense_deduction
        return BigDecimal("0") unless parsed_legal_defense_costs.positive?

        [ parsed_legal_defense_costs, parameter_decimal!("legal_defense_deduction_cap") ].min
      end

      def disabled_worker_expense
        case disabled_worker_status
        when "level_33_to_64"
          parameter_decimal!("disabled_worker_expense")
        when "level_65_plus_or_support"
          parameter_decimal!("disabled_worker_high_expense")
        else
          BigDecimal("0")
        end
      end

      def geographic_mobility_expense
        geographic_mobility ? parameter_decimal!("geographic_mobility_expense") : BigDecimal("0")
      end

      def total
        parsed_union_dues + professional_fees_deduction + legal_defense_deduction + disabled_worker_expense + geographic_mobility_expense
      end

      def summary
        parts = []
        parts << "union dues" if parsed_union_dues.positive?
        parts << "professional fees" if professional_fees_deduction.positive?
        parts << "legal-defense costs" if legal_defense_deduction.positive?
        parts << "disabled-worker expense" if disabled_worker_expense.positive?
        parts << "geographic mobility" if geographic_mobility_expense.positive?
        parts.presence&.join(", ") || "no extra employment expenses"
      end

      def parameter_decimal!(key)
        regime&.parameter_decimal!(key) || raise(KeyError, "Missing tax parameter #{key}")
      end
    end
  end
end
