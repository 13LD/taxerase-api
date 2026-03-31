class PagesController < ApplicationController
  def home
    calculator_definition = Taxerase::CountryCalculators::Registry.fetch(
      params[:country].presence || Taxerase::CountryCalculators::Registry::DEFAULT_COUNTRY_CODE
    )

    @page_title = calculator_definition.page_title
    @calculator_props = calculator_definition.build_props
  end
end
