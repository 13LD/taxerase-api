require "rails_helper"

RSpec.describe Taxerase::CountryCalculators::AndorraDefinition do
  subject(:definition) { described_class.new }

  describe "#page_title" do
    it "builds a country-specific page title" do
      expect(definition.page_title).to eq("Taxerase | Andorra Tax Calculator")
    end
  end

  describe "#build_props" do
    it "builds the calculator payload for the public Andorra web app" do
      props = definition.build_props
      expected_default_regime_key = Taxerase::Andorra::CalculationRouter.default_regime_key(2026)

      expect(props[:country]).to eq(code: "AD", name: "Andorra", currency_code: "EUR")
      expect(props[:input_currency_options]).to eq([
        { code: "EUR", name: "EUR" }
      ])
      expect(props[:tax_year_options]).to eq([ 2024, 2025, 2026 ])
      expect(props[:default_tax_regime_key]).to eq(expected_default_regime_key)
      expect(props[:regime_options].map { |regime| regime[:key] })
        .to contain_exactly(
          "employee_andorra",
          "employee_andorra",
          "employee_andorra",
          "self_employed_andorra",
          "self_employed_andorra",
          "self_employed_andorra"
        )
      expect(props[:default_input]).to include(
        gross_income: 60_000,
        input_currency_code: "EUR",
        salary_period: "YEAR",
        tax_year: 2026,
        deductible_expenses: 0,
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none"
      )
      expect(props[:initial_result].dig(:metadata, :country_code)).to eq("AD")
      expect(props[:initial_result].dig(:metadata, :tax_regime_key)).to eq(expected_default_regime_key)
    end
  end
end
