module Taxerase
  module Spain
    class SelfEmployedExpenses
      include InputNormalization

      ESTIMATION_METHODS = %w[direct_simplified direct_normal modules].freeze

      def self.call(regime:, **kwargs)
        new(regime:, **kwargs).call
      end

      def self.validation_errors(**kwargs)
        new(regime: nil, **kwargs).validation_errors
      end

      def initialize(
        regime:,
        deductible_expenses:,
        home_office_supply_expenses: 0,
        home_office_ownership_expenses: 0,
        home_office_business_use_percentage: 0,
        meals_expenses: 0,
        self_employed_estimation_method: "direct_simplified"
      )
        @regime = regime
        @deductible_expenses = deductible_expenses
        @home_office_supply_expenses = home_office_supply_expenses
        @home_office_ownership_expenses = home_office_ownership_expenses
        @home_office_business_use_percentage = home_office_business_use_percentage
        @meals_expenses = meals_expenses
        @self_employed_estimation_method = self_employed_estimation_method.to_s.presence || "direct_simplified"
      end

      def validation_errors
        errors = []
        errors << "self_employed_estimation_method is not supported" unless ESTIMATION_METHODS.include?(self_employed_estimation_method)
        errors << "deductible_expenses must be 0 or greater" if parsed_deductible_expenses.negative?
        errors << "home_office_supply_expenses must be 0 or greater" if parsed_home_office_supply_expenses.negative?
        errors << "home_office_ownership_expenses must be 0 or greater" if parsed_home_office_ownership_expenses.negative?
        errors << "home_office_business_use_percentage must be between 0 and 100" unless parsed_home_office_business_use_percentage.between?(0, 100)
        errors << "meals_expenses must be 0 or greater" if parsed_meals_expenses.negative?
        errors
      end

      def call
        {
          estimation_method: self_employed_estimation_method,
          ordinary_expenses: ordinary_expenses,
          home_office_supply_deduction: home_office_supply_deduction,
          home_office_ownership_deduction: home_office_ownership_deduction,
          meals_deduction: meals_deduction,
          direct_expenses_total: direct_expenses_total,
          modules_net_income_rate: modules_net_income_rate,
          summary: summary
        }
      end

      private

      attr_reader :regime, :deductible_expenses, :home_office_supply_expenses, :home_office_ownership_expenses,
        :home_office_business_use_percentage, :meals_expenses, :self_employed_estimation_method

      def ordinary_expenses
        return BigDecimal("0") if self_employed_estimation_method == "modules"

        parsed_deductible_expenses
      end

      def home_office_supply_deduction
        return BigDecimal("0") if self_employed_estimation_method == "modules"
        return BigDecimal("0") unless parsed_home_office_supply_expenses.positive?
        return BigDecimal("0") unless parsed_home_office_business_use_percentage.positive?

        parsed_home_office_supply_expenses *
          parameter_decimal!("home_office_supply_deduction_rate") *
          (parsed_home_office_business_use_percentage / 100)
      end

      def home_office_ownership_deduction
        return BigDecimal("0") if self_employed_estimation_method == "modules"
        return BigDecimal("0") unless parsed_home_office_ownership_expenses.positive?
        return BigDecimal("0") unless parsed_home_office_business_use_percentage.positive?

        parsed_home_office_ownership_expenses * (parsed_home_office_business_use_percentage / 100)
      end

      def meals_deduction
        return BigDecimal("0") if self_employed_estimation_method == "modules"

        parsed_meals_expenses
      end

      def direct_expenses_total
        ordinary_expenses + home_office_supply_deduction + home_office_ownership_deduction + meals_deduction
      end

      def modules_net_income_rate
        self_employed_estimation_method == "modules" ? parameter_decimal!("modules_net_income_rate") : BigDecimal("0")
      end

      def summary
        case self_employed_estimation_method
        when "direct_simplified"
          "direct estimation simplified with home-office and meal expense classes"
        when "direct_normal"
          "direct normal estimation without the simplified 5% difficult-to-justify deduction"
        when "modules"
          "objective-estimation modules estimate using the seeded net-income rate"
        end
      end

      def parsed_deductible_expenses
        @parsed_deductible_expenses ||= decimal(deductible_expenses)
      end

      def parsed_home_office_supply_expenses
        @parsed_home_office_supply_expenses ||= decimal(home_office_supply_expenses)
      end

      def parsed_home_office_ownership_expenses
        @parsed_home_office_ownership_expenses ||= decimal(home_office_ownership_expenses)
      end

      def parsed_home_office_business_use_percentage
        @parsed_home_office_business_use_percentage ||= decimal(home_office_business_use_percentage)
      end

      def parsed_meals_expenses
        @parsed_meals_expenses ||= decimal(meals_expenses)
      end

      def parameter_decimal!(key)
        regime&.parameter_decimal!(key) || raise(KeyError, "Missing tax parameter #{key}")
      end
    end
  end
end
