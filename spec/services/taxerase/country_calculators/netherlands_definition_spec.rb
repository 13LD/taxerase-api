require "rails_helper"

RSpec.describe Taxerase::CountryCalculators::NetherlandsDefinition do
  subject(:definition) { described_class.new }

  describe "#page_title" do
    it "builds a country-specific page title" do
      expect(definition.page_title).to eq("Taxerase | Netherlands Tax Calculator")
    end
  end

  describe "#build_props" do
    it "builds the calculator payload for the public Netherlands web app" do
      props = definition.build_props
      expected_default_regime_key = Taxerase::Netherlands::CalculationRouter.default_regime_key(2025)

      expect(props[:country]).to eq(code: "NL", name: "Netherlands")
      expect(props[:country_options]).to include(code: "ES", name: "Spain")
      expect(props[:country_options]).to include(code: "NL", name: "Netherlands")
      expect(props[:tax_year_options]).to eq([ 2024, 2025 ])
      expect(props[:default_tax_regime_key]).to eq(expected_default_regime_key)
      expect(props[:regime_options].map { |regime| regime[:key] })
        .to include("employee_netherlands", "self_employed_netherlands")
      expect(props[:default_input]).to include(
        gross_income: 60_000,
        salary_period: "YEAR",
        tax_year: 2025,
        deductible_expenses: 0,
        age_bracket: "under_aow_age"
      )
      expect(props[:initial_result].dig(:metadata, :country_code)).to eq("NL")
      expect(props[:initial_result].dig(:metadata, :tax_year)).to eq(2025)
      expect(props[:initial_result].dig(:metadata, :tax_regime_key)).to eq(expected_default_regime_key)
    end
  end

  describe "#normalize_comparison_input" do
    it "fills the hidden comparison defaults for the Netherlands" do
      expect(
        definition.normalize_comparison_input(
          age_bracket: nil,
          children_count: nil,
          children_under_three_count: nil,
          disability_level: nil
        )
      ).to eq(
        age_bracket: "under_aow_age",
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none"
      )
    end
  end
end
