module Api
  module V1
    module Andorra
      class SalaryCalculationsController < ApplicationController
        rescue_from Taxerase::Andorra::EmployeeCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Andorra::SelfEmployedCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Andorra::CalculationRouter::UnsupportedRegimeError, with: :render_validation_error
        rescue_from Taxerase::InputCurrencyHandler::ValidationError, with: :render_validation_error

        def create
          render json: calculator_result_payload(Taxerase::Andorra::CalculationRouter.call(
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
            has_spouse_or_partner: calculation_params[:has_spouse_or_partner],
            spouse_without_income: calculation_params[:spouse_without_income],
            spouse_general_income: calculation_params[:spouse_general_income],
            mortgage_interest: calculation_params[:mortgage_interest],
            home_acquisition_investment: calculation_params[:home_acquisition_investment],
            affordable_rental_housing_investment: calculation_params[:affordable_rental_housing_investment],
            higher_education_tuition: calculation_params[:higher_education_tuition],
            pension_contributions: calculation_params[:pension_contributions],
            alimony_paid: calculation_params[:alimony_paid],
            self_employed_social_security_regime: calculation_params[:self_employed_social_security_regime],
            apply_housing_rent_support: calculation_params[:apply_housing_rent_support],
            housing_support_priority_group: calculation_params[:housing_support_priority_group],
            housing_rent: calculation_params[:housing_rent]
          ))
        end

        private

        def calculation_params
          @calculation_params ||= calculator_calculation_params(
            Taxerase::Andorra::CalculationRouter,
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
            :has_spouse_or_partner,
            :spouse_without_income,
            :spouse_general_income,
            :mortgage_interest,
            :home_acquisition_investment,
            :affordable_rental_housing_investment,
            :higher_education_tuition,
            :pension_contributions,
            :alimony_paid,
            :self_employed_social_security_regime,
            :apply_housing_rent_support,
            :housing_support_priority_group,
            :housing_rent,
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
