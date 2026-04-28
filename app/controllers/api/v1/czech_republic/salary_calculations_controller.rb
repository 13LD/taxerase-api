module Api
  module V1
    module CzechRepublic
      class SalaryCalculationsController < ApplicationController
        rescue_from Taxerase::CzechRepublic::EmployeeCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::CzechRepublic::SelfEmployedCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::CzechRepublic::CalculationRouter::UnsupportedRegimeError, with: :render_validation_error
        rescue_from Taxerase::InputCurrencyHandler::ValidationError, with: :render_validation_error

        def create
          render json: calculator_result_payload(Taxerase::CzechRepublic::CalculationRouter.call(
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
            disability_level: calculation_params[:disability_level],
            child_credit_claim_share: calculation_params[:child_credit_claim_share],
            apply_spouse_credit: calculation_params[:apply_spouse_credit],
            spouse_income: calculation_params[:spouse_income],
            spouse_ztp_p: calculation_params[:spouse_ztp_p],
            spouse_cares_child_under_three: calculation_params[:spouse_cares_child_under_three],
            mortgage_interest_paid: calculation_params[:mortgage_interest_paid],
            pension_contributions: calculation_params[:pension_contributions],
            life_insurance_contributions: calculation_params[:life_insurance_contributions],
            donations_amount: calculation_params[:donations_amount],
            self_employed_tax_mode: calculation_params[:self_employed_tax_mode],
            osvc_activity_status: calculation_params[:osvc_activity_status]
          ))
        end

        private

        def calculation_params
          @calculation_params ||= calculator_calculation_params(
            Taxerase::CzechRepublic::CalculationRouter,
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
            :disability_level,
            :child_credit_claim_share,
            :apply_spouse_credit,
            :spouse_income,
            :spouse_ztp_p,
            :spouse_cares_child_under_three,
            :mortgage_interest_paid,
            :pension_contributions,
            :life_insurance_contributions,
            :donations_amount,
            :self_employed_tax_mode,
            :osvc_activity_status,
            public_defaults: { age_bracket: "standard" }
          )
        end

        def render_validation_error(error)
          render json: validation_error_payload(error), status: :unprocessable_content
        end
      end
    end
  end
end
