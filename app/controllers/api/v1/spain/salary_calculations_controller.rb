module Api
  module V1
    module Spain
      class SalaryCalculationsController < ApplicationController
        rescue_from Taxerase::Spain2025::EmployeeSalaryCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Spain2025::CalculationRouter::UnsupportedRegimeError, with: :render_validation_error

        def create
          render json: Taxerase::Spain2025::CalculationRouter.call(
            gross_income: calculation_params[:gross_income],
            salary_period: calculation_params[:salary_period],
            tax_regime_key: calculation_params[:tax_regime_key]
          )
        end

        private

        def calculation_params
          params.require(:calculation).permit(:gross_income, :salary_period, :tax_regime_key)
        end

        def render_validation_error(error)
          render json: { errors: error.errors }, status: :unprocessable_content
        end
      end
    end
  end
end
