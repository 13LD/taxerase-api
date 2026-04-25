module Taxerase
  module Spain
    module InputNormalization
      module_function

      def decimal(value)
        BigDecimal(value.to_s)
      rescue ArgumentError
        BigDecimal("0")
      end

      def integer(value)
        Integer(value, exception: false) || -1
      end

      def boolean(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end
    end
  end
end
