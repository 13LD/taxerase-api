module Api
  module V1
    module Spain
      class SalaryCalculationsController < ApplicationController
        rescue_from Taxerase::Spain::CommonRegimeEmployeeCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Spain::CommonRegimeSelfEmployedCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Spain::BeckhamLawCalculator::ValidationError, with: :render_validation_error
        rescue_from Taxerase::Spain::CalculationRouter::UnsupportedRegimeError, with: :render_validation_error
        rescue_from Taxerase::InputCurrencyHandler::ValidationError, with: :render_validation_error

        def create
          render json: Taxerase::Spain::CalculationRouter.call(
            gross_income: calculation_params[:gross_income],
            input_currency_code: calculation_params[:input_currency_code],
            salary_period: calculation_params[:salary_period],
            tax_year: calculation_params[:tax_year].to_i,
            tax_regime_key: calculation_params[:tax_regime_key],
            deductible_expenses: calculation_params[:deductible_expenses],
            apply_beckham_law: calculation_params[:apply_beckham_law],
            age_bracket: calculation_params[:age_bracket],
            children_count: calculation_params[:children_count],
            children_under_three_count: calculation_params[:children_under_three_count],
            disability_level: calculation_params[:disability_level],
            ascendants_count: calculation_params[:ascendants_count],
            ascendants_over_75_count: calculation_params[:ascendants_over_75_count],
            ascendant_disability_33_count: calculation_params[:ascendant_disability_33_count],
            ascendant_disability_65_count: calculation_params[:ascendant_disability_65_count],
            ascendant_disability_support_count: calculation_params[:ascendant_disability_support_count],
            joint_filing_mode: calculation_params[:joint_filing_mode],
            union_dues: calculation_params[:union_dues],
            professional_fees: calculation_params[:professional_fees],
            legal_defense_costs: calculation_params[:legal_defense_costs],
            disabled_worker_status: calculation_params[:disabled_worker_status],
            geographic_mobility: calculation_params[:geographic_mobility],
            maternity_eligible_months: calculation_params[:maternity_eligible_months],
            nursery_expenses_paid: calculation_params[:nursery_expenses_paid],
            large_family_category: calculation_params[:large_family_category],
            large_family_extra_children: calculation_params[:large_family_extra_children],
            single_parent_two_children: calculation_params[:single_parent_two_children],
            disabled_descendants_count: calculation_params[:disabled_descendants_count],
            disabled_ascendants_count: calculation_params[:disabled_ascendants_count],
            spouse_disability_dependant: calculation_params[:spouse_disability_dependant],
            contribution_group: calculation_params[:contribution_group],
            self_employed_estimation_method: calculation_params[:self_employed_estimation_method],
            home_office_supply_expenses: calculation_params[:home_office_supply_expenses],
            home_office_ownership_expenses: calculation_params[:home_office_ownership_expenses],
            home_office_business_use_percentage: calculation_params[:home_office_business_use_percentage],
            meals_expenses: calculation_params[:meals_expenses],
            reta_contribution_mode: calculation_params[:reta_contribution_mode],
            family_collaborator: calculation_params[:family_collaborator],
            corporate_self_employed: calculation_params[:corporate_self_employed],
            apply_reta_pluriactivity: calculation_params[:apply_reta_pluriactivity],
            employment_common_contingencies_paid: calculation_params[:employment_common_contingencies_paid]
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
            :apply_beckham_law,
            :age_bracket,
            :children_count,
            :children_under_three_count,
            :disability_level,
            :ascendants_count,
            :ascendants_over_75_count,
            :ascendant_disability_33_count,
            :ascendant_disability_65_count,
            :ascendant_disability_support_count,
            :joint_filing_mode,
            :union_dues,
            :professional_fees,
            :legal_defense_costs,
            :disabled_worker_status,
            :geographic_mobility,
            :maternity_eligible_months,
            :nursery_expenses_paid,
            :large_family_category,
            :large_family_extra_children,
            :single_parent_two_children,
            :disabled_descendants_count,
            :disabled_ascendants_count,
            :spouse_disability_dependant,
            :contribution_group,
            :self_employed_estimation_method,
            :home_office_supply_expenses,
            :home_office_ownership_expenses,
            :home_office_business_use_percentage,
            :meals_expenses,
            :reta_contribution_mode,
            :family_collaborator,
            :corporate_self_employed,
            :apply_reta_pluriactivity,
            :employment_common_contingencies_paid
          )
        end

        def render_validation_error(error)
          render json: validation_error_payload(error), status: :unprocessable_content
        end
      end
    end
  end
end
