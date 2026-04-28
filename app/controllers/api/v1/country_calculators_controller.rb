module Api
  module V1
    class CountryCalculatorsController < ApplicationController
      rescue_from KeyError, with: :render_not_found
      rescue_from Taxerase::CountryCalculators::Registry::UnavailableCountryError, with: :render_not_found

      def show
        definition = Taxerase::CountryCalculators::Registry.fetch(params[:country_code])

        render json: {
          page_title: definition.page_title,
          calculator_props: calculator_props_payload(definition)
        }
      rescue ActiveRecord::RecordNotFound, ArgumentError
        render_not_found(
          Taxerase::CountryCalculators::Registry::UnavailableCountryError.new(
            "#{definition.country.fetch(:name)} calculator data is not available. Run db:seed."
          )
        )
      end

      private

      def render_not_found(error)
        render json: { errors: [ error.message ] }, status: :not_found
      end
    end
  end
end
