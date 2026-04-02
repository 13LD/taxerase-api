module Api
  module V1
    module CzechRepublic
      class SalaryCalculationsController < ApplicationController
        rescue_from Taxerase::CzechRepublic::EmployeeCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::CzechRepublic::SelfEmployedCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::CzechRepublic::CalculationRouter::UnsupportedRegimeError, with: :render_validation_error
        rescue_from Taxerase::InputCurrencyHandler::ValidationError, with: :render_validation_error

        def create
          render json: Taxerase::CzechRepublic::CalculationRouter.call(
            gross_income: calculation_params[:gross_income],
            input_currency_code: calculation_params[:input_currency_code],
            salary_period: calculation_params[:salary_period],
            tax_year: calculation_params[:tax_year].to_i,
            tax_regime_key: calculation_params[:tax_regime_key],
            deductible_expenses: calculation_params[:deductible_expenses],
            expense_deduction_method: calculation_params[:expense_deduction_method],
            age_bracket: calculation_params[:age_bracket],
            children_count: calculation_params[:children_count],
            children_under_three_count: calculation_params[:children_under_three_count],
            disability_level: calculation_params[:disability_level]
          )
        end

        private

        def calculation_params
          params.require(:calculation).permit(
            :gross_income,
            :input_currency_code,
            :salary_period,
            :tax_year,
            :tax_regime_key,
            :deductible_expenses,
            :expense_deduction_method,
            :age_bracket,
            :children_count,
            :children_under_three_count,
            :disability_level
          )
        end

        def render_validation_error(error)
          render json: { errors: error.errors }, status: :unprocessable_content
        end
      end
    end
  end
end
