require "rails_helper"

RSpec.describe Taxerase::CountryCalculators::SpainDefinition do
  subject(:definition) { described_class.new }

  describe "#page_title" do
    it "builds a country-specific page title" do
      expect(definition.page_title).to eq("Taxerase | Spain Tax Calculator")
    end
  end

  describe "#build_props" do
    it "builds the calculator payload for the public Spain web app" do
      props = definition.build_props
      expected_default_regime_key = Taxerase::Spain::CalculationRouter.default_regime_key(2025)

      expect(props[:country]).to eq(code: "ES", name: "Spain")
      expect(props[:tax_year_options]).to eq([ 2024, 2025 ])
      expect(props[:default_tax_regime_key]).to eq(expected_default_regime_key)
      expect(props[:regime_options].map { |regime| regime[:key] })
        .to include("employee_madrid", "self_employed_madrid")
      expect(props[:regime_options].map { |regime| regime[:key] })
        .not_to include("employee_navarre")
      expect(props[:default_input]).to include(
        gross_income: 60_000,
        salary_period: "YEAR",
        tax_year: 2025,
        deductible_expenses: 0,
        age_bracket: "under_65",
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none"
      )
      expect(props[:initial_result].dig(:metadata, :country_code)).to eq("ES")
      expect(props[:initial_result].dig(:metadata, :tax_year)).to eq(2025)
      expect(props[:initial_result].dig(:metadata, :tax_regime_key)).to eq(expected_default_regime_key)
    end
  end

  describe "#normalize_comparison_input" do
    it "fills the hidden comparison defaults for Spain" do
      expect(
        definition.normalize_comparison_input(
          age_bracket: nil,
          children_count: nil,
          children_under_three_count: nil,
          disability_level: nil
        )
      ).to eq(
        age_bracket: "under_65",
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none"
      )
    end
  end
end
