require "rails_helper"

RSpec.describe Taxerase::Spain::PersonalFamilyMinimums do
  let(:regime) do
    TaxRegime
      .for_country_year(country: Country.find_by!(code: "ES"), tax_year: 2025)
      .find_by!(key: "employee_madrid")
  end

  describe ".call" do
    it "builds state and regional personal-family minimums from the selected profile" do
      result = described_class.call(
        regime: regime,
        age_bracket: "age_75_plus",
        children_count: 2,
        children_under_three_count: 1,
        disability_level: "level_65_plus"
      )

      expect(result[:state_amount]).to eq(BigDecimal("28000"))
      expect(result[:regional_amount]).to eq(BigDecimal("28406.65"))
      expect(result[:summary]).to eq("75 or older, 2 children (1 under 3), taxpayer disability 65% or more")
    end
  end

  describe ".validation_errors" do
    it "rejects impossible child counts" do
      errors = described_class.validation_errors(
        age_bracket: "under_65",
        children_count: 1,
        children_under_three_count: 2,
        disability_level: "none"
      )

      expect(errors).to include("children_under_three_count must be an integer between 0 and children_count")
    end
  end
end
