require "rails_helper"

RSpec.describe Taxerase::Poland::CalculationRouter do
  describe ".public_tax_year_options" do
    it "exposes only supported public years" do
      expect(described_class.public_tax_year_options).to eq([ 2025, 2026 ])
    end
  end

  describe ".call" do
    it "calculates every supported public regime from the seeded rules" do
      supported_regimes = described_class.public_regime_options

      expect(supported_regimes).not_to be_empty

      supported_regimes.each do |regime|
        result = described_class.call(
          gross_income: 120_000,
          deductible_expenses: regime[:category] == "self_employed" ? 20_000 : 0,
          salary_period: "YEAR",
          tax_year: regime[:tax_year],
          tax_regime_key: regime[:key],
          age_bracket: "age_26_to_retirement",
          children_count: 2,
          apply_return_relief: false,
          apply_family_4plus_relief: false,
          apply_working_senior_relief: false
        )

        expect(result.dig(:metadata, :country_code)).to eq("PL")
        expect(result.dig(:metadata, :tax_regime_key)).to eq(regime[:key])
        expect(result.dig(:metadata, :tax_year)).to eq(regime[:tax_year])
        expect(result[:sources]).not_to be_empty
        expect(result.dig(:breakdown, :annual_net_income)).to be > 0
        expect(result[:detail_cards]).not_to be_empty
      end
    end
  end
end
