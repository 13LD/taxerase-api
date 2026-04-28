class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :store_auth_return_path, if: :devise_controller?

  private

  def store_auth_return_path
    return unless request.get? || request.head?

    return unless params.key?(:return_to)

    return_path = safe_return_path(params[:return_to])
    if return_path.present?
      session["user_return_to"] = return_path
    else
      session.delete("user_return_to")
    end
  end

  def safe_return_path(value)
    return if value.blank?

    return_path = value.to_s
    decoded_return_path = URI.decode_uri_component(return_path)
    return if unsafe_return_path?(return_path) || unsafe_return_path?(decoded_return_path)

    uri = URI.parse(return_path)
    return unless uri.host.nil? && uri.scheme.nil?
    return unless return_path.start_with?("/") && !return_path.start_with?("//")

    return_path
  rescue URI::InvalidURIError, ArgumentError
    nil
  end

  def unsafe_return_path?(value)
    value.match?(/[\\\x00-\x1f\x7f]/) || value.start_with?("//")
  end

  def after_sign_in_path_for(resource)
    return_path = session.delete("user_return_to").presence || root_path
    return return_path unless resource.is_a?(User) && resource.profile.blank?

    edit_profile_path(return_to: return_path)
  end

  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end

  def calculator_auth_props
    {
      signed_in: user_signed_in?,
      email: current_user&.email,
      selected_country_code: current_user&.selected_country_code,
      selected_country_name: current_user&.selected_country_name,
      profile_type: current_user&.profile_type,
      profile_type_label: current_user&.profile_type_label,
      profile_path: edit_profile_path,
      sign_in_path: new_user_session_path,
      sign_out_path: destroy_user_session_path,
      sign_up_path: new_user_registration_path,
      authenticity_token: form_authenticity_token
    }
  end

  def calculator_profile_category
    supported_profile_type(params[:profile_type]) ||
      supported_profile_type(current_user&.profile_type) ||
      Profile::DEFAULT_PROFILE_TYPE
  end

  def supported_profile_type(value)
    profile_type = Profile.normalize_profile_type(value)
    return unless Profile::PROFILE_TYPES.key?(profile_type)

    profile_type
  end

  def validation_error_payload(error)
    payload = { errors: error.errors }
    payload[:rule_statuses] = error.rule_statuses if error.respond_to?(:rule_statuses) && error.rule_statuses.present?
    payload
  end
end
