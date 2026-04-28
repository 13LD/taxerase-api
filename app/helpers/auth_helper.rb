module AuthHelper
  def auth_country_options
    Taxerase::CountryCalculators::Registry::DEFINITIONS.map do |code, definition|
      [ definition.country.fetch(:name), code ]
    end
  end

  def profile_type_options
    Profile::PROFILE_TYPES.map do |value, label|
      [ label, value ]
    end
  end

  def auth_return_to_param
    params[:return_to].presence || session["user_return_to"].presence || root_path
  end
end
