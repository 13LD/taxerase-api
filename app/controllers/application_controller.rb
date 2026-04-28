class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  PUBLIC_CALCULATION_PARAM_KEYS = %i[
    gross_income
    input_currency_code
    tax_year
    tax_regime_key
    deductible_expenses
  ].freeze
  PUBLIC_CALCULATION_DEFAULTS = {
    salary_period: "YEAR",
    children_count: 0,
    children_under_three_count: 0,
    disability_level: "none"
  }.freeze
  PUBLIC_CALCULATION_PROFILE_CATEGORIES = %w[employee self_employed].freeze
  PUBLIC_CALCULATION_BREAKDOWN_KEYS = %i[
    annual_net_income
    monthly_net_income
    effective_tax_rate
  ].freeze

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
      profile_country_code: current_user&.profile&.country_code,
      selected_country_code: current_user&.selected_country_code,
      selected_country_name: current_user&.selected_country_name,
      profile_type: current_user&.profile_type,
      profile_type_label: current_user&.profile_type_label,
      profile_path: edit_profile_path,
      sign_in_path: new_user_session_path,
      sign_out_path: destroy_user_session_path,
      authenticity_token: form_authenticity_token
    }
  end

  def calculator_profile_category
    supported_profile_type(params[:profile_type]) ||
      supported_profile_type(current_user&.profile_type) ||
      Profile::DEFAULT_PROFILE_TYPE
  end

  def calculator_props_payload(calculator_definition)
    calculator_definition.build_props(
      profile_category: calculator_profile_category
    ).tap do |props|
      props[:initial_result] = calculator_result_payload(props.fetch(:initial_result))
    end.merge(auth: calculator_auth_props)
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

  def calculator_calculation_params(calculation_router, *permitted_keys, public_defaults: {})
    permitted_params = params.require(:calculation).permit(*permitted_keys)
    return permitted_params if user_signed_in?

    public_calculation_params(permitted_params, calculation_router, public_defaults)
  end

  def calculator_result_payload(result)
    return result if user_signed_in?

    public_calculation_result(result)
  end

  def public_calculation_params(permitted_params, calculation_router, public_defaults)
    public_values = PUBLIC_CALCULATION_DEFAULTS
      .merge(public_defaults)
      .merge(permitted_params.slice(*PUBLIC_CALCULATION_PARAM_KEYS).to_h.symbolize_keys)
    public_params = ActionController::Parameters.new(public_values).permit!
    public_params[:tax_regime_key] = public_calculation_regime_key(public_params, calculation_router)
    public_params
  end

  def public_calculation_regime_key(public_params, calculation_router)
    regime_key = public_params[:tax_regime_key].presence
    tax_year = public_params[:tax_year].to_i
    return if regime_key.blank? || tax_year.zero?

    regime = calculation_router.find_regime(regime_key, tax_year)
    return regime_key if public_calculation_regime?(regime, calculation_router)

    calculation_router.default_regime_key(tax_year)
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def public_calculation_regime?(regime, calculation_router)
    regime.present? &&
      PUBLIC_CALCULATION_PROFILE_CATEGORIES.include?(regime.category) &&
      calculation_router.supported?(regime)
  end

  def public_calculation_result(result)
    result_hash = result.deep_symbolize_keys

    {
      input: result_hash[:input],
      metadata: result_hash[:metadata],
      breakdown: result_hash.fetch(:breakdown, {}).slice(*PUBLIC_CALCULATION_BREAKDOWN_KEYS),
      detail_cards: [],
      assumptions: [],
      sources: [],
      rule_statuses: []
    }
  end
end
