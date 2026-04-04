module Taxerase
  class InputCurrencyHandler
    class ValidationError < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super(errors.join(", "))
      end
    end

    def initialize(native_currency_code:, supported_currency_codes:)
      @native_currency_code = native_currency_code.to_s.upcase
      @supported_currency_codes = supported_currency_codes.map { |code| code.to_s.upcase }
      @converter = Taxerase::Comparisons::ReferenceRateConverter.new
    end

    def resolve_input_currency_code(input_currency_code)
      resolved_code = input_currency_code.to_s.upcase.presence || native_currency_code
      return resolved_code if supported_currency_codes.include?(resolved_code)

      raise ValidationError.new([ "input_currency_code must be one of: #{supported_currency_codes.join(', ')}" ])
    end

    def convert_amount(amount, input_currency_code:)
      resolved_input_currency_code = resolve_input_currency_code(input_currency_code)
      return amount if resolved_input_currency_code == native_currency_code
      return amount if amount.nil?

      converter.convert(
        amount,
        from_currency_code: resolved_input_currency_code,
        to_currency_code: native_currency_code
      )
    rescue ArgumentError
      amount
    rescue KeyError => error
      raise ValidationError.new([ error.message ])
    end

    def apply_to_result(result, input_currency_code:)
      resolved_input_currency_code = resolve_input_currency_code(input_currency_code)

      result[:metadata][:input_currency_code] = resolved_input_currency_code
      result[:metadata][:native_currency_code] = native_currency_code
      result[:metadata][:display_currency_code] = resolved_input_currency_code
      result[:input][:input_currency_code] = resolved_input_currency_code

      return result if resolved_input_currency_code == native_currency_code

      fx_reference = converter.reference_metadata
      convert_result_amounts!(result, resolved_input_currency_code)
      result[:metadata][:input_fx_reference] = fx_reference
      result[:assumptions] = [
        "Income inputs entered in #{resolved_input_currency_code} are converted to #{native_currency_code} using #{fx_reference[:provider]} rates from #{fx_reference[:rate_date]}.",
        "Displayed monetary amounts are converted back to #{resolved_input_currency_code} for presentation.",
        *Array(result[:assumptions])
      ]
      result
    end

    private

    attr_reader :converter, :native_currency_code, :supported_currency_codes

    INPUT_CURRENCY_KEYS = %i[
      gross_income
      deductible_expenses
      annual_gross_income
      monthly_gross_income
    ].freeze

    NON_CURRENCY_BREAKDOWN_KEYS = %i[effective_tax_rate].freeze

    def convert_result_amounts!(result, display_currency_code)
      convert_input_amounts!(result[:input], display_currency_code)
      convert_breakdown_amounts!(result[:breakdown], display_currency_code)
      convert_detail_cards!(result[:detail_cards], display_currency_code)
    end

    def convert_input_amounts!(input, display_currency_code)
      return unless input.is_a?(Hash)

      INPUT_CURRENCY_KEYS.each do |key|
        next unless input.key?(key)

        input[key] = convert_output_amount(input[key], display_currency_code)
      end
    end

    def convert_breakdown_amounts!(breakdown, display_currency_code)
      return unless breakdown.is_a?(Hash)

      breakdown.each do |key, value|
        next if NON_CURRENCY_BREAKDOWN_KEYS.include?(key.to_sym)

        breakdown[key] = convert_output_amount(value, display_currency_code)
      end
    end

    def convert_detail_cards!(detail_cards, display_currency_code)
      Array(detail_cards).each do |card|
        next unless card.is_a?(Hash) && card.key?(:value)

        card[:value] = convert_output_amount(card[:value], display_currency_code)
      end
    end

    def convert_output_amount(amount, display_currency_code)
      return amount unless amount.is_a?(Numeric)

      converter.convert(
        amount,
        from_currency_code: native_currency_code,
        to_currency_code: display_currency_code
      )
    end
  end
end
