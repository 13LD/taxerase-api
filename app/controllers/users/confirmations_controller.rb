module Users
  class ConfirmationsController < Devise::ConfirmationsController
    def pending
      @confirmation_email = session[:pending_confirmation_email]
    end

    private

    def after_confirmation_path_for(_resource_name, _resource)
      return_path = session["user_return_to"].presence || root_path

      new_user_session_path(return_to: return_path)
    end
  end
end
