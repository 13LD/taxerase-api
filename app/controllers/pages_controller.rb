class PagesController < ApplicationController
  def home
    calculator_definition = Taxerase::CountryCalculators::Registry.fetch(
      params[:country].presence || current_user&.selected_country_code ||
        Taxerase::CountryCalculators::Registry::DEFAULT_COUNTRY_CODE
    )

    @page_title = calculator_definition.page_title
    @calculator_props = calculator_props_payload(calculator_definition)
  rescue KeyError, ActiveRecord::RecordNotFound, ArgumentError
    calculator_definition = Taxerase::CountryCalculators::Registry.default_available

    @page_title = calculator_definition.page_title
    @calculator_props = calculator_props_payload(calculator_definition)
  end
end
