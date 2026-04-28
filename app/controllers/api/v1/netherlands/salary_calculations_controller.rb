module Api
  module V1
    module Netherlands
      class SalaryCalculationsController < ApplicationController
        rescue_from Taxerase::Netherlands::EmployeeCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Netherlands::SelfEmployedCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Netherlands::CalculationRouter::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Netherlands::CalculationRouter::UnsupportedRegimeError, with: :render_validation_error
        rescue_from Taxerase::InputCurrencyHandler::ValidationError, with: :render_validation_error

        def create
          calculation = calculation_params.to_h.symbolize_keys

          render json: calculator_result_payload(Taxerase::Netherlands::CalculationRouter.call(
            gross_income: calculation[:gross_income],
            input_currency_code: calculation[:input_currency_code],
            salary_period: calculation[:salary_period],
            tax_year: calculation[:tax_year].to_i,
            tax_regime_key: calculation[:tax_regime_key],
            deductible_expenses: calculation[:deductible_expenses],
            age_bracket: calculation[:age_bracket],
            apply_thirty_percent_ruling: calculation[:apply_thirty_percent_ruling],
            thirty_percent_ruling_basis: calculation[:thirty_percent_ruling_basis],
            children_count: calculation[:children_count],
            children_under_three_count: calculation[:children_under_three_count],
            disability_level: calculation[:disability_level],
            **calculation.slice(*optional_input_keys)
          ))
        end

        private

        def calculation_params
          @calculation_params ||= calculator_calculation_params(
            Taxerase::Netherlands::CalculationRouter,
            :gross_income,
            :input_currency_code,
            :salary_period,
            :tax_year,
            :tax_regime_key,
            :deductible_expenses,
            :age_bracket,
            :apply_thirty_percent_ruling,
            :thirty_percent_ruling_basis,
            :children_count,
            :children_under_three_count,
            :disability_level,
            *optional_input_keys,
            public_defaults: { age_bracket: "under_aow_age" }
          )
        end

        def optional_input_keys
          (
            Taxerase::Netherlands::CalculationRouter::CREDIT_AND_DEDUCTION_INPUT_KEYS +
              Taxerase::Netherlands::CalculationRouter::ENTREPRENEUR_INPUT_KEYS
          ) - %i[children_count children_under_three_count disability_level]
        end

        def render_validation_error(error)
          render json: validation_error_payload(error), status: :unprocessable_content
        end
      end
    end
  end
end
