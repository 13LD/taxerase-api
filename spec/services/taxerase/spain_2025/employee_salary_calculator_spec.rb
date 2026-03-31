require "rails_helper"

RSpec.describe Taxerase::Spain2025::EmployeeSalaryCalculator do
  describe ".call" do
    it "calculates the default annual Spain employee scenario" do
      result = described_class.call(gross_income: 60_000, salary_period: "YEAR")

      expect(result.dig(:metadata, :country_code)).to eq("ES")
      expect(result.dig(:input, :annual_gross_income)).to eq(60_000.0)
      expect(result.dig(:breakdown, :annual_social_security)).to be_within(0.01).of(3_817.63)
      expect(result.dig(:breakdown, :annual_income_tax)).to be_within(0.01).of(13_946.01)
      expect(result.dig(:breakdown, :annual_net_income)).to be_within(0.01).of(42_236.36)
      expect(result.dig(:breakdown, :effective_tax_rate)).to be_within(0.01).of(29.61)
    end

    it "normalizes monthly income to annual income" do
      result = described_class.call(gross_income: 5_000, salary_period: "MONTH")

      expect(result.dig(:input, :annual_gross_income)).to eq(60_000.0)
    end

    it "raises a validation error for invalid input" do
      expect do
        described_class.call(gross_income: -1, salary_period: "WEEK")
      end.to raise_error(
        described_class::ValidationError,
        "gross_income must be a number greater than 0, salary_period must be YEAR or MONTH"
      )
    end
  end
end
