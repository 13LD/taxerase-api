class PagesController < ApplicationController
  def home
    calculator_definition = Taxerase::CountryCalculators::Registry.home_definition(params[:country])

    @page_title = calculator_definition.page_title
    @calculator_props = calculator_definition.build_props
  end
end
