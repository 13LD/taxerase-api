module Api
  module V1
    module Andorra
      class SalaryCalculationsController < ApplicationController
        rescue_from Taxerase::Andorra::EmployeeCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Andorra::SelfEmployedCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Andorra::CalculationRouter::UnsupportedRegimeError, with: :render_validation_error
        rescue_from Taxerase::InputCurrencyHandler::ValidationError, with: :render_validation_error

        def create
          render json: Taxerase::Andorra::CalculationRouter.call(
            gross_income: calculation_params[:gross_income],
            input_currency_code: calculation_params[:input_currency_code],
            salary_period: calculation_params[:salary_period],
            tax_year: calculation_params[:tax_year].to_i,
            tax_regime_key: calculation_params[:tax_regime_key],
            deductible_expenses: calculation_params[:deductible_expenses],
            age_bracket: calculation_params[:age_bracket],
            children_count: calculation_params[:children_count],
            children_under_three_count: calculation_params[:children_under_three_count],
            disability_level: calculation_params[:disability_level],
            ascendants_count: calculation_params[:ascendants_count],
            disabled_dependents_count: calculation_params[:disabled_dependents_count],
            spouse_without_income: calculation_params[:spouse_without_income],
            mortgage_interest: calculation_params[:mortgage_interest],
            pension_contributions: calculation_params[:pension_contributions],
            alimony_paid: calculation_params[:alimony_paid]
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
            :age_bracket,
            :children_count,
            :children_under_three_count,
            :disability_level,
            :ascendants_count,
            :disabled_dependents_count,
            :spouse_without_income,
            :mortgage_interest,
            :pension_contributions,
            :alimony_paid
          )
        end

        def render_validation_error(error)
          render json: { errors: error.errors }, status: :unprocessable_content
        end
      end
    end
  end
end
