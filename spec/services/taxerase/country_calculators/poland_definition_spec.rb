require "rails_helper"

RSpec.describe Taxerase::CountryCalculators::PolandDefinition do
  subject(:definition) { described_class.new }

  describe "#page_title" do
    it "builds a country-specific page title" do
      expect(definition.page_title).to eq("Taxerase | Poland Tax Calculator")
    end
  end

  describe "#build_props" do
    it "builds the calculator payload for the public Poland web app" do
      props = definition.build_props
      expected_default_regime_key = Taxerase::Poland::CalculationRouter.default_regime_key(2026)

      expect(props[:country]).to eq(code: "PL", name: "Poland", currency_code: "PLN")
      expect(props[:input_currency_options]).to eq([
        { code: "PLN", name: "PLN" },
        { code: "EUR", name: "EUR" }
      ])
      expect(props[:tax_year_options]).to eq([ 2025, 2026 ])
      expect(props[:default_tax_regime_key]).to eq(expected_default_regime_key)
      expect(props[:regime_options].map { |regime| regime[:key] })
        .to include("employee_poland", "self_employed_poland")
      expect(props[:default_input]).to include(
        gross_income: 180_000,
        input_currency_code: "PLN",
        salary_period: "YEAR",
        tax_year: 2026,
        deductible_expenses: 0,
        age_bracket: "age_26_to_retirement",
        apply_return_relief: false,
        apply_family_4plus_relief: false,
        apply_working_senior_relief: false
      )
      expect(props[:initial_result].dig(:metadata, :country_code)).to eq("PL")
      expect(props[:initial_result].dig(:metadata, :tax_year)).to eq(2026)
      expect(props[:initial_result].dig(:metadata, :tax_regime_key)).to eq(expected_default_regime_key)
    end
  end

  describe "#public_catalog" do
    it "exposes Poland regimes in the public comparison catalog" do
      expect(definition.public_catalog[:regime_options].map { |regime| [ regime[:key], regime[:tax_year] ] })
        .to contain_exactly(
          [ "employee_poland", 2025 ],
          [ "self_employed_poland", 2025 ],
          [ "employee_poland", 2026 ],
          [ "self_employed_poland", 2026 ]
        )
    end
  end

  describe "#comparison_call_overrides" do
    it "forces Poland self-employed comparisons onto the flat-tax path" do
      expect(
        definition.comparison_call_overrides(profile_key: "self_employed", input: {})
      ).to eq(
        b2b_tax_form: "flat_tax"
      )
    end

    it "does not override employee comparisons" do
      expect(
        definition.comparison_call_overrides(profile_key: "employee", input: {})
      ).to eq({})
    end
  end
end
