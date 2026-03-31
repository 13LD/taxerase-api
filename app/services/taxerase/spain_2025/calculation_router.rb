module Taxerase
  module Spain2025
    class CalculationRouter
      class UnsupportedRegimeError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      SUPPORTED_CALCULATORS = {
        EmployeeSalaryCalculator::REGIME_KEY => EmployeeSalaryCalculator
      }.freeze

      def self.call(gross_income:, salary_period:, tax_regime_key: nil)
        regime_key = tax_regime_key.presence || default_regime_key
        calculator = SUPPORTED_CALCULATORS[regime_key]

        raise UnsupportedRegimeError.new([unsupported_message_for(regime_key)]) unless calculator

        calculator.call(gross_income:, salary_period:)
      end

      def self.default_regime_key
        EmployeeSalaryCalculator::REGIME_KEY
      end

      def self.regime_options
        country = Country.find_by!(code: "ES")

        country.tax_regimes.where(tax_year: EmployeeSalaryCalculator::TAX_YEAR).order(:category, :name).map do |regime|
          {
            key: regime.key,
            name: regime.name,
            category: regime.category,
            description: regime.description,
            supported: supported?(regime.key),
            status: supported?(regime.key) ? "Live" : "Research"
          }
        end
      end

      def self.supported?(regime_key)
        SUPPORTED_CALCULATORS.key?(regime_key)
      end

      def self.unsupported_message_for(regime_key)
        regime_name = TaxRegime.find_by(key: regime_key, tax_year: EmployeeSalaryCalculator::TAX_YEAR)&.name || regime_key
        "#{regime_name} is stored in the rules database, but its calculator flow is not implemented yet."
      end
    end
  end
end
