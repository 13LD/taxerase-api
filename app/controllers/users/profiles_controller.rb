module Users
  class ProfilesController < ApplicationController
    before_action :authenticate_user!

    def edit
      @profile = profile_record
      @profile_return_to = profile_return_to
    end

    def update
      @profile = profile_record

      if @profile.update(profile_params)
        redirect_to profile_return_to, notice: "Profile updated."
      else
        @profile_return_to = profile_return_to
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def profile_record
      current_user.profile || current_user.build_profile(
        country_code: Profile::DEFAULT_COUNTRY_CODE,
        profile_type: Profile::DEFAULT_PROFILE_TYPE
      )
    end

    def profile_params
      params.require(:profile).permit(:country_code, :profile_type)
    end

    def profile_return_to
      safe_return_path(params[:return_to]) || root_path
    end
  end
end
