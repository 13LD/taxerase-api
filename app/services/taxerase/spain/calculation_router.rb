module Taxerase
  module Spain
    class CalculationRouter
      class UnsupportedRegimeError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      SUPPORTED_METHODS = {
        CommonRegimeEmployeeCalculator::CALCULATION_METHOD => CommonRegimeEmployeeCalculator,
        CommonRegimeSelfEmployedCalculator::CALCULATION_METHOD => CommonRegimeSelfEmployedCalculator
      }.freeze

      def self.call(gross_income:, salary_period:, tax_year:, tax_regime_key: nil, deductible_expenses: 0)
        regime = regime_for!(tax_regime_key.presence || default_regime_key(tax_year), tax_year)
        calculator = SUPPORTED_METHODS[regime.parameter_text("calculation_method")]

        raise UnsupportedRegimeError.new([unsupported_message_for(regime)]) unless calculator

        if calculator == CommonRegimeSelfEmployedCalculator
          calculator.call(gross_income:, salary_period:, tax_regime_key: regime.key, tax_year:, deductible_expenses:)
        else
          calculator.call(gross_income:, salary_period:, tax_regime_key: regime.key, tax_year:)
        end
      end

      def self.default_regime_key(tax_year)
        preferred_method_keys = SUPPORTED_METHODS.keys
        regimes = TaxRegime
          .includes(:tax_parameters)
          .where(country: Country.find_by!(code: "ES"), tax_year:, category: "employee", active: true)
          .order(:region, :name)

        preferred = regimes.find do |regime|
          preferred_method_keys.include?(regime.parameter_text("calculation_method"))
        end

        preferred&.key || regimes.first&.key
      end

      def self.regime_options
        country = Country.find_by!(code: "ES")

        country.tax_regimes
          .includes(tax_source_usages: :official_tax_source)
          .order(:tax_year, :category, :region, :name)
          .map do |regime|
            supported = supported?(regime)
            {
              key: regime.key,
              name: regime.name,
              region: regime.region,
              category: regime.category,
              tax_year: regime.tax_year,
              description: regime.description,
              supported: supported,
              status: supported ? "Live" : "Research",
              sources: regime.source_links
            }
          end
      end

      def self.supported?(regime_or_key, tax_year = nil)
        regime = regime_or_key.is_a?(TaxRegime) ? regime_or_key : TaxRegime.find_by(key: regime_or_key, tax_year:)
        regime.present? && SUPPORTED_METHODS.key?(regime.parameter_text("calculation_method"))
      end

      def self.regime_for!(regime_key, tax_year)
        TaxRegime.includes(:country, :tax_brackets, :tax_parameters, tax_source_usages: :official_tax_source).find_by!(
          key: regime_key,
          tax_year:
        )
      rescue ActiveRecord::RecordNotFound
        raise UnsupportedRegimeError.new(["#{regime_key} is not available for Spain #{tax_year}."])
      end

      def self.unsupported_message_for(regime)
        if regime.official_tax_sources.any?
          "#{regime.name} has official sources linked for #{regime.tax_year}, but its calculator flow is not implemented yet."
        else
          "#{regime.name} is stored in the rules database, but its calculator flow is not implemented yet."
        end
      end
    end
  end
end
