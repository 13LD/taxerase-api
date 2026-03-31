require "rails_helper"

RSpec.describe Taxerase::Spain2025::SelfEmployedCalculator do
  describe ".call" do
    it "calculates the Madrid direct-estimation self-employed flow" do
      result = described_class.call(
        gross_income: 60_000,
        deductible_expenses: 10_000,
        salary_period: "YEAR",
        tax_regime_key: "self_employed_madrid"
      )

      expect(result.dig(:metadata, :country_code)).to eq("ES")
      expect(result.dig(:metadata, :tax_regime_key)).to eq("self_employed_madrid")
      expect(result.dig(:breakdown, :annual_social_security)).to be_within(0.01).of(6_033.74)
      expect(result.dig(:breakdown, :annual_income_tax)).to be_within(0.01).of(9_560.43)
      expect(result.dig(:breakdown, :annual_net_income)).to be_within(0.01).of(34_405.84)
      expect(result.dig(:breakdown, :effective_tax_rate)).to be_within(0.01).of(25.99)
    end

    it "raises a validation error for invalid expenses" do
      expect do
        described_class.call(
          gross_income: 60_000,
          deductible_expenses: -1,
          salary_period: "YEAR",
          tax_regime_key: "self_employed_madrid"
        )
      end.to raise_error(
        described_class::ValidationError,
        "deductible_expenses must be 0 or greater"
      )
    end
  end
end
