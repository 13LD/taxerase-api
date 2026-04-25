module Api
  module V1
    module Poland
      class SalaryCalculationsController < ApplicationController
        rescue_from Taxerase::Poland::EmployeeCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Poland::SelfEmployedCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Poland::CalculationRouter::UnsupportedRegimeError, with: :render_validation_error
        rescue_from Taxerase::InputCurrencyHandler::ValidationError, with: :render_validation_error

        def create
          render json: Taxerase::Poland::CalculationRouter.call(
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
            apply_return_relief: calculation_params[:apply_return_relief],
            apply_family_4plus_relief: calculation_params[:apply_family_4plus_relief],
            apply_working_senior_relief: calculation_params[:apply_working_senior_relief],
            revenue_cost_mode: calculation_params[:revenue_cost_mode],
            monthly_tax_relief_mode: calculation_params[:monthly_tax_relief_mode],
            ppk_employee_rate: calculation_params[:ppk_employee_rate],
            ppk_employer_rate: calculation_params[:ppk_employer_rate],
            employer_accident_rate: calculation_params[:employer_accident_rate],
            include_labor_fund: calculation_params[:include_labor_fund],
            include_fgsp: calculation_params[:include_fgsp],
            b2b_tax_form: calculation_params[:b2b_tax_form],
            lump_sum_rate: calculation_params[:lump_sum_rate],
            social_insurance_mode: calculation_params[:social_insurance_mode],
            include_sickness_contribution: calculation_params[:include_sickness_contribution],
            business_days_in_month: calculation_params[:business_days_in_month],
            previous_year_average_monthly_income: calculation_params[:previous_year_average_monthly_income]
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
            :apply_return_relief,
            :apply_family_4plus_relief,
            :apply_working_senior_relief,
            :revenue_cost_mode,
            :monthly_tax_relief_mode,
            :ppk_employee_rate,
            :ppk_employer_rate,
            :employer_accident_rate,
            :include_labor_fund,
            :include_fgsp,
            :b2b_tax_form,
            :lump_sum_rate,
            :social_insurance_mode,
            :include_sickness_contribution,
            :business_days_in_month,
            :previous_year_average_monthly_income
          )
        end

        def render_validation_error(error)
          render json: validation_error_payload(error), status: :unprocessable_content
        end
      end
    end
  end
end
