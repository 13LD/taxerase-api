module Taxerase
  module Netherlands
    class CalculationRouter
      class UnsupportedRegimeError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super(errors.join(", "))
        end
      end

      COUNTRY_CODE = "NL".freeze

      SUPPORTED_METHODS = {
        EmployeeCalculator::CALCULATION_METHOD => EmployeeCalculator,
        SelfEmployedCalculator::CALCULATION_METHOD => SelfEmployedCalculator
      }.freeze

      def self.call(
        gross_income:,
        salary_period:,
        tax_year:,
        tax_regime_key: nil,
        deductible_expenses: 0,
        age_bracket: "under_aow_age",
        apply_thirty_percent_ruling: false,
        thirty_percent_ruling_basis: nil,
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none"
      )
        regime = regime_for!(tax_regime_key.presence || default_regime_key(tax_year), tax_year)
        calculator = SUPPORTED_METHODS[regime.parameter_text("calculation_method")]

        raise UnsupportedRegimeError.new([ unsupported_message_for(regime) ]) unless calculator

        if calculator == SelfEmployedCalculator
          calculator.call(
            gross_income:,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            deductible_expenses:,
            age_bracket:
          )
        else
          calculator.call(
            gross_income:,
            salary_period:,
            tax_regime_key: regime.key,
            tax_year:,
            age_bracket:,
            apply_thirty_percent_ruling:,
            thirty_percent_ruling_basis:
          )
        end
      end

      def self.default_regime_key(tax_year)
        preferred_method_keys = SUPPORTED_METHODS.keys
        regimes = country.tax_regimes
          .includes(:tax_parameters)
          .where(tax_year:, category: "employee", active: true)
          .order(:region, :name)

        preferred = regimes.find do |regime|
          preferred_method_keys.include?(regime.parameter_text("calculation_method"))
        end

        preferred&.key || regimes.first&.key
      end

      def self.regime_options
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
              supported:,
              status: supported ? "Live" : "Research",
              sources: regime.source_links
            }
          end
      end

      def self.public_regime_options
        regime_options.select { |regime| regime[:supported] }
      end

      def self.public_tax_year_options
        public_regime_options.map { |regime| regime[:tax_year] }.uniq.sort
      end

      def self.supported?(regime_or_key, tax_year = nil)
        regime = if regime_or_key.is_a?(TaxRegime)
          regime_or_key
        else
          TaxRegime.find_by(country:, key: regime_or_key, tax_year:)
        end

        regime.present? && regime.country_id == country.id && SUPPORTED_METHODS.key?(regime.parameter_text("calculation_method"))
      end

      def self.regime_for!(regime_key, tax_year)
        TaxRegime.includes(:country, :tax_brackets, :tax_parameters, tax_source_usages: :official_tax_source).find_by!(
          country:,
          key: regime_key,
          tax_year:
        )
      rescue ActiveRecord::RecordNotFound
        raise UnsupportedRegimeError.new([ "#{regime_key} is not available for the Netherlands #{tax_year}." ])
      end

      def self.unsupported_message_for(regime)
        if regime.official_tax_sources.any?
          "#{regime.name} has official sources linked for #{regime.tax_year}, but its calculator flow is not implemented yet."
        else
          "#{regime.name} is stored in the rules database, but its calculator flow is not implemented yet."
        end
      end

      def self.country
        @country ||= Country.find_by!(code: COUNTRY_CODE)
      end
    end
  end
end
