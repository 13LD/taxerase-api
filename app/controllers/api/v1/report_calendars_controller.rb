module Api
  module V1
    class ReportCalendarsController < ApplicationController
      before_action :require_calendar_profile!

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      def show
        render json: Taxerase::Compliance::ReportCalendar.call(
          country_code: params[:country_code],
          tax_year: params[:tax_year]
        )
      end

      private

      def require_calendar_profile!
        if !user_signed_in?
          render json: { errors: [ "Sign in to open the calendar." ] }, status: :unauthorized
        elsif current_user.profile&.country_code.blank?
          render json: { errors: [ "Add a country to your profile before opening the calendar." ] },
                 status: :forbidden
        end
      end

      def render_not_found(error)
        render json: { errors: [ error.message ] }, status: :not_found
      end
    end
  end
end
