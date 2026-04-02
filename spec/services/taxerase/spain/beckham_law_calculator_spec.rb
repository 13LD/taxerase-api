require "rails_helper"

RSpec.describe Taxerase::Spain::BeckhamLawCalculator do
  describe ".call" do
    it "calculates the Spain Beckham Law employment flow for 2025" do
      result = described_class.call(
        gross_income: 60_000,
        salary_period: "YEAR",
        tax_regime_key: "beckham_madrid",
        tax_year: 2025,
        age_bracket: "under_65",
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none"
      )

      expect(result.dig(:metadata, :tax_regime_key)).to eq("beckham_madrid")
      expect(result.dig(:breakdown, :annual_income_tax)).to eq(14_400.0)
      expect(result.dig(:breakdown, :annual_social_security)).to eq(3817.63)
      expect(result.dig(:breakdown, :annual_net_income)).to eq(41_782.37)
    end

    it "applies the 47% bracket above 600,000 euros" do
      result = described_class.call(
        gross_income: 700_000,
        salary_period: "YEAR",
        tax_regime_key: "beckham_madrid",
        tax_year: 2025,
        age_bracket: "under_65",
        children_count: 0,
        children_under_three_count: 0,
        disability_level: "none"
      )

      expect(result.dig(:breakdown, :annual_income_tax)).to eq(191_000.0)
      expect(result.dig(:breakdown, :annual_net_income)).to eq(505_182.37)
    end
  end
end
