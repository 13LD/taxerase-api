require "rails_helper"

RSpec.describe Taxerase::Netherlands::ThirtyPercentRuling do
  let(:country) { Country.find_by!(code: "NL") }
  let(:regime_2025) { TaxRegime.find_by!(country:, key: "employee_netherlands", tax_year: 2025) }
  let(:regime_2024) { TaxRegime.find_by!(country:, key: "employee_netherlands", tax_year: 2024) }

  describe ".call" do
    it "applies the standard threshold for 2025" do
      result = described_class.call(
        regime: regime_2025,
        annual_gross_income: 60_000,
        apply_thirty_percent_ruling: true,
        thirty_percent_ruling_basis: "standard_threshold"
      )

      expect(result[:untaxed_allowance]).to eq(BigDecimal("13340"))
      expect(result[:taxable_employment_income]).to eq(BigDecimal("46660"))
      expect(result[:threshold]).to eq(BigDecimal("46660"))
    end

    it "applies the reduced threshold for under-30 master's cases" do
      result = described_class.call(
        regime: regime_2025,
        annual_gross_income: 40_000,
        apply_thirty_percent_ruling: true,
        thirty_percent_ruling_basis: "under_30_masters"
      )

      expect(result[:untaxed_allowance]).to eq(BigDecimal("4532"))
      expect(result[:taxable_employment_income]).to eq(BigDecimal("35468"))
      expect(result[:threshold]).to eq(BigDecimal("35468"))
    end

    it "does not apply a salary threshold for scientific research" do
      result = described_class.call(
        regime: regime_2025,
        annual_gross_income: 20_000,
        apply_thirty_percent_ruling: true,
        thirty_percent_ruling_basis: "scientific_research"
      )

      expect(result[:untaxed_allowance]).to eq(BigDecimal("6000"))
      expect(result[:taxable_employment_income]).to eq(BigDecimal("14000"))
      expect(result[:threshold]).to eq(BigDecimal("0"))
    end

    it "applies the 2024 salary cap" do
      result = described_class.call(
        regime: regime_2024,
        annual_gross_income: 300_000,
        apply_thirty_percent_ruling: true,
        thirty_percent_ruling_basis: "scientific_research"
      )

      expect(result[:cap_applied]).to be(true)
      expect(result[:salary_cap]).to eq(BigDecimal("233000"))
      expect(result[:untaxed_allowance]).to eq(BigDecimal("69900"))
    end
  end

  describe ".validation_errors" do
    it "rejects an unknown ruling basis when the checkbox is enabled" do
      expect(
        described_class.validation_errors(
          apply_thirty_percent_ruling: true,
          thirty_percent_ruling_basis: "unknown"
        )
      ).to include("thirty_percent_ruling_basis is not supported for the Netherlands 30% ruling")
    end
  end
end
