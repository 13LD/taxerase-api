require "rails_helper"

RSpec.describe Taxerase::CountryCalculators::CzechRepublicDefinition do
  subject(:definition) { described_class.new }

  describe "#page_title" do
    it "builds a country-specific page title" do
      expect(definition.page_title).to eq("Taxerase | Czech Republic Tax Calculator")
    end
  end

  describe "#build_props" do
    it "builds the calculator payload for the public Czech Republic web app" do
      props = definition.build_props
      expected_default_regime_key = Taxerase::CzechRepublic::CalculationRouter.default_regime_key(2025)

      expect(props[:country]).to eq(code: "CZ", name: "Czech Republic", currency_code: "CZK")
      expect(props[:input_currency_options]).to eq([
        { code: "CZK", name: "CZK" },
        { code: "EUR", name: "EUR" }
      ])
      expect(props[:tax_year_options]).to eq([ 2025 ])
      expect(props[:default_tax_regime_key]).to eq(expected_default_regime_key)
      expect(props[:regime_options].map { |regime| regime[:key] })
        .to include("employee_czech_republic", "self_employed_czech_republic")
      expect(props[:default_input]).to include(
        gross_income: 600_000,
        input_currency_code: "CZK",
        salary_period: "YEAR",
        tax_year: 2025,
        deductible_expenses: 0,
        expense_deduction_method: "flat_expense_60",
        children_count: 0,
        disability_level: "none"
      )
      expect(props[:initial_result].dig(:metadata, :country_code)).to eq("CZ")
      expect(props[:initial_result].dig(:metadata, :tax_regime_key)).to eq(expected_default_regime_key)
    end
  end

  describe "#public_catalog" do
    it "exposes Czech Republic regimes in the public comparison catalog" do
      expect(definition.public_catalog[:regime_options].map { |regime| regime[:key] })
        .to contain_exactly("employee_czech_republic", "self_employed_czech_republic")
    end
  end

  describe "#comparison_call_overrides" do
    it "defaults Czech self-employed comparisons to the 60% flat expense method" do
      expect(
        definition.comparison_call_overrides(profile_key: "self_employed", input: {})
      ).to eq(
        expense_deduction_method: "flat_expense_60"
      )
    end
  end
end
