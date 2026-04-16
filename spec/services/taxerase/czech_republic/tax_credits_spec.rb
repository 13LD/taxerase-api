require "rails_helper"

RSpec.describe Taxerase::CzechRepublic::TaxCredits do
  let(:regime) do
    TaxRegime
      .for_country_year(country: Country.find_by!(code: "CZ"), tax_year: 2025)
      .find_by!(key: "employee_czech_republic")
  end

  describe ".child_tax_bonus" do
    it "blocks the bonus below the annual qualifying income threshold" do
      bonus = described_class.child_tax_bonus(
        regime: regime,
        annual_qualifying_income: 120_000,
        child_credit: 65_364,
        tax_after_standard_credits: 0
      )

      expect(bonus).to eq(0)
    end

    it "pays the bonus once the annual qualifying income threshold is met" do
      bonus = described_class.child_tax_bonus(
        regime: regime,
        annual_qualifying_income: 124_800,
        child_credit: 15_204,
        tax_after_standard_credits: 0
      )

      expect(bonus).to eq(BigDecimal("15204"))
    end
  end
end
