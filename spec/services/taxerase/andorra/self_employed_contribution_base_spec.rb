require "rails_helper"

RSpec.describe Taxerase::Andorra::SelfEmployedContributionBase do
  let(:country) { Country.find_by!(code: "AD") }

  def regime_for(tax_year)
    TaxRegime
      .for_country_year(country:, tax_year:)
      .find_by!(key: "self_employed_andorra")
  end

  describe ".call" do
    it "uses the seeded standard ratio table without forcing the base up to the minimum salary" do
      result = described_class.call(
        net_income: 10_000,
        regime: regime_for(2025),
        social_security_regime: "standard"
      )

      expect(result[:ratio]).to eq(BigDecimal("0.5"))
      expect(result[:monthly_base]).to be_within(BigDecimal("0.01")).of(BigDecimal("1280.495"))
      expect(result[:annual_contribution]).to be_within(BigDecimal("0.01")).of(BigDecimal("3380.5068"))
    end

    it "applies the under-35 first-year special regime on 55% of the minimum salary" do
      result = described_class.call(
        net_income: 20_000,
        regime: regime_for(2026),
        social_security_regime: "under_35_first_12_months"
      )

      expect(result[:monthly_base]).to be_within(BigDecimal("0.01")).of(BigDecimal("838.9315"))
      expect(result[:contribution_rate]).to eq(BigDecimal("0.1"))
      expect(result[:annual_contribution]).to be_within(BigDecimal("0.01")).of(BigDecimal("1006.7178"))
    end
  end
end
