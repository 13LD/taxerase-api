module Api
  module V1
    module Portugal
      class SalaryCalculationsController < ApplicationController
        rescue_from Taxerase::Portugal::EmployeeCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Portugal::SelfEmployedCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Portugal::CalculationRouter::UnsupportedRegimeError, with: :render_validation_error
        rescue_from Taxerase::InputCurrencyHandler::ValidationError, with: :render_validation_error

        def create
          render json: Taxerase::Portugal::CalculationRouter.call(
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
            business_activity_type: calculation_params[:business_activity_type],
            ascendants_count: calculation_params[:ascendants_count],
            general_family_expenses: calculation_params[:general_family_expenses],
            health_expenses: calculation_params[:health_expenses],
            education_expenses: calculation_params[:education_expenses],
            housing_rent: calculation_params[:housing_rent],
            alimony_paid: calculation_params[:alimony_paid],
            care_home_expenses: calculation_params[:care_home_expenses],
            domestic_work_expenses: calculation_params[:domestic_work_expenses]
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
            :business_activity_type,
            :ascendants_count,
            :general_family_expenses,
            :health_expenses,
            :education_expenses,
            :housing_rent,
            :alimony_paid,
            :care_home_expenses,
            :domestic_work_expenses
          )
        end

        def render_validation_error(error)
          render json: { errors: error.errors }, status: :unprocessable_content
        end
      end
    end
  end
end
