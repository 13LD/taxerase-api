module Api
  module V1
    class ReportCalendarsController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      def show
        render json: Taxerase::Compliance::ReportCalendar.call(
          country_code: params[:country_code],
          tax_year: params[:tax_year]
        )
      end

      private

      def render_not_found(error)
        render json: { errors: [ error.message ] }, status: :not_found
      end
    end
  end
end
