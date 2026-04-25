module Taxerase
  module Spain2025
    class CalculationRouter
      class UnsupportedRegimeError < Taxerase::UnsupportedRegimeError; end

      SUPPORTED_CATEGORIES = {
        "employee" => EmployeeSalaryCalculator,
        "self_employed" => SelfEmployedCalculator
      }.freeze
      COUNTRY_CODE = "ES".freeze

      def self.call(gross_income:, salary_period:, tax_regime_key: nil, deductible_expenses: 0)
        regime = regime_for!(tax_regime_key.presence || default_regime_key)
        calculator = SUPPORTED_CATEGORIES[regime.category]

        raise unsupported_regime_error_for(regime) unless calculator

        case regime.category
        when "employee"
          calculator.call(gross_income:, salary_period:, tax_regime_key: regime.key)
        when "self_employed"
          calculator.call(gross_income:, salary_period:, tax_regime_key: regime.key, deductible_expenses:)
        else
          raise unsupported_regime_error_for(regime)
        end
      end

      def self.default_regime_key
        RegionCatalog.default_employee_regime_key
      end

      def self.regime_options
        TaxRegime
          .includes(:official_tax_sources)
          .for_country_year(country:, tax_year: EmployeeSalaryCalculator::TAX_YEAR)
          .order(:category, :region, :name)
          .map do |regime|
            {
              key: regime.key,
              name: regime.name,
              region: regime.region,
              category: regime.category,
              description: regime.description,
              supported: supported?(regime),
              status: supported?(regime) ? "Live" : "Research",
              rule_statuses: supported?(regime) ? [] : unsupported_rule_statuses_for(regime)
            }
          end
      end

      def self.supported?(regime_or_key)
        regime = if regime_or_key.is_a?(TaxRegime)
          regime_or_key
        else
          TaxRegime
            .for_country_year(country:, tax_year: EmployeeSalaryCalculator::TAX_YEAR)
            .find_by(key: regime_or_key)
        end

        regime.present? && SUPPORTED_CATEGORIES.key?(regime.category)
      end

      def self.unsupported_message_for(regime_or_key)
        regime = if regime_or_key.is_a?(TaxRegime)
          regime_or_key
        else
          TaxRegime
            .for_country_year(country:, tax_year: EmployeeSalaryCalculator::TAX_YEAR)
            .find_by(key: regime_or_key)
        end

        regime_name = regime&.name || regime_or_key
        "#{regime_name} is stored in the rules database, but its calculator flow is not implemented yet."
      end

      def self.regime_for!(regime_key)
        TaxRegime
          .includes(:country, :tax_brackets, :tax_parameters)
          .for_country_year(country:, tax_year: EmployeeSalaryCalculator::TAX_YEAR)
          .find_by!(key: regime_key)
      rescue ActiveRecord::RecordNotFound
        raise UnsupportedRegimeError.new([ "#{regime_key} is not available for Spain 2025." ])
      end

      def self.unsupported_regime_error_for(regime)
        UnsupportedRegimeError.new(
          [ unsupported_message_for(regime) ],
          rule_statuses: unsupported_rule_statuses_for(regime)
        )
      end

      def self.unsupported_rule_statuses_for(regime)
        [
          Taxerase::RuleStatus.not_implemented(
            rule_key: "#{regime.key}:#{EmployeeSalaryCalculator::TAX_YEAR}:calculator_flow",
            label: "#{regime.name} calculator flow",
            message: unsupported_message_for(regime),
            source_keys: regime.official_tax_sources.map(&:key)
          )
        ]
      end

      def self.country
        @country ||= Country.find_by!(code: COUNTRY_CODE)
      end
    end
  end
end
