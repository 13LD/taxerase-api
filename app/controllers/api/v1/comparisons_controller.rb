module Api
  module V1
    class ComparisonsController < ApplicationController
      rescue_from Taxerase::Comparisons::CalculationComparison::ValidationError, with: :render_validation_error

      def create
        render json: Taxerase::Comparisons::CalculationComparison.call(
          left_country_code: comparison_params[:left_country_code],
          left_tax_regime_key: comparison_params[:left_tax_regime_key],
          right_country_code: comparison_params[:right_country_code],
          right_tax_regime_key: comparison_params[:right_tax_regime_key],
          tax_year: comparison_params[:tax_year],
          selected_category: comparison_params[:selected_category],
          gross_income: comparison_params[:gross_income],
          input_currency_code: comparison_params[:input_currency_code],
          salary_period: comparison_params[:salary_period],
          deductible_expenses: comparison_params[:deductible_expenses],
          age_bracket: comparison_params[:age_bracket],
          children_count: comparison_params[:children_count],
          children_under_three_count: comparison_params[:children_under_three_count],
          disability_level: comparison_params[:disability_level]
        )
      end

      private

      def comparison_params
        params.require(:comparison).permit(
          :left_country_code,
          :left_tax_regime_key,
          :right_country_code,
          :right_tax_regime_key,
          :tax_year,
          :selected_category,
          :gross_income,
          :input_currency_code,
          :salary_period,
          :deductible_expenses,
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
