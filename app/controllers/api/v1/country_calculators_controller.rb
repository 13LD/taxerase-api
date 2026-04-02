module Api
  module V1
    class CountryCalculatorsController < ApplicationController
      rescue_from KeyError, with: :render_not_found

      def show
        definition = Taxerase::CountryCalculators::Registry.fetch(params[:country_code])

        render json: {
          page_title: definition.page_title,
          calculator_props: definition.build_props
        }
      end

      private

      def render_not_found(error)
        render json: { errors: [ error.message ] }, status: :not_found
      end
    end
  end
end
