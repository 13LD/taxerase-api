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

      SUPPORTED_CATEGORIES = {
        "employee" => EmployeeSalaryCalculator,
        "self_employed" => SelfEmployedCalculator
      }.freeze
      COUNTRY_CODE = "ES".freeze

      def self.call(gross_income:, salary_period:, tax_regime_key: nil, deductible_expenses: 0)
        regime = regime_for!(tax_regime_key.presence || default_regime_key)
        calculator = SUPPORTED_CATEGORIES[regime.category]

        raise UnsupportedRegimeError.new([ unsupported_message_for(regime) ]) unless calculator

        case regime.category
        when "employee"
          calculator.call(gross_income:, salary_period:, tax_regime_key: regime.key)
        when "self_employed"
          calculator.call(gross_income:, salary_period:, tax_regime_key: regime.key, deductible_expenses:)
        else
          raise UnsupportedRegimeError.new([ unsupported_message_for(regime) ])
        end
      end

      def self.default_regime_key
        RegionCatalog.default_employee_regime_key
      end

      def self.regime_options
        country.tax_regimes.where(tax_year: EmployeeSalaryCalculator::TAX_YEAR).order(:category, :region, :name).map do |regime|
          {
            key: regime.key,
            name: regime.name,
            region: regime.region,
            category: regime.category,
            description: regime.description,
            supported: supported?(regime),
            status: supported?(regime) ? "Live" : "Research"
          }
        end
      end

      def self.supported?(regime_or_key)
        regime = if regime_or_key.is_a?(TaxRegime)
          regime_or_key
        else
          TaxRegime.find_by(country:, key: regime_or_key, tax_year: EmployeeSalaryCalculator::TAX_YEAR)
        end

        regime.present? && SUPPORTED_CATEGORIES.key?(regime.category)
      end

      def self.unsupported_message_for(regime_or_key)
        regime = if regime_or_key.is_a?(TaxRegime)
          regime_or_key
        else
          TaxRegime.find_by(country:, key: regime_or_key, tax_year: EmployeeSalaryCalculator::TAX_YEAR)
        end

        regime_name = regime&.name || regime_or_key
        "#{regime_name} is stored in the rules database, but its calculator flow is not implemented yet."
      end

      def self.regime_for!(regime_key)
        TaxRegime.includes(:country, :tax_brackets, :tax_parameters).find_by!(
          country:,
          key: regime_key,
          tax_year: EmployeeSalaryCalculator::TAX_YEAR
        )
      rescue ActiveRecord::RecordNotFound
        raise UnsupportedRegimeError.new([ "#{regime_key} is not available for Spain 2025." ])
      end

      def self.country
        @country ||= Country.find_by!(code: COUNTRY_CODE)
      end
    end
  end
end
