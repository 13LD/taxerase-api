module Taxerase
  module Netherlands
    module ParameterReader
      module_function

      def decimal(regime, key, default: 0)
        regime.tax_parameters.find { |parameter| parameter.key == key }&.value_decimal&.to_d ||
          BigDecimal(default.to_s)
      end
    end
  end
end
