require "rails_helper"

RSpec.describe Taxerase::CzechRepublic::CalculationRouter do
  describe ".public_tax_year_options" do
    it "exposes only supported public years" do
      expect(described_class.public_tax_year_options).to eq([ 2025 ])
    end
  end

  describe ".call" do
    it "calculates every supported public regime from the seeded rules" do
      supported_regimes = described_class.public_regime_options

      expect(supported_regimes).not_to be_empty

      supported_regimes.each do |regime|
        result = described_class.call(
          gross_income: 600_000,
          deductible_expenses: regime[:category] == "self_employed" ? 120_000 : 0,
          salary_period: "YEAR",
          tax_year: regime[:tax_year],
          tax_regime_key: regime[:key],
          children_count: 2,
          disability_level: "invalidity_first_or_second_degree"
        )

        expect(result.dig(:metadata, :country_code)).to eq("CZ")
        expect(result.dig(:metadata, :tax_regime_key)).to eq(regime[:key])
        expect(result[:sources]).not_to be_empty
        expect(result[:detail_cards]).not_to be_empty
      end
    end
  end
end
