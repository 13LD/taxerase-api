require "rails_helper"

RSpec.describe Taxerase::Spain2025::CalculationRouter do
  describe ".regime_options" do
    it "returns the db-backed regime options with support metadata" do
      options = described_class.regime_options
      employee = options.find { |option| option[:key] == "employee_madrid" }
      self_employed = options.find { |option| option[:key] == "self_employed_madrid" }
      company = options.find { |option| option[:key] == "corporate_income_general" }

      expect(employee[:supported]).to be(true)
      expect(employee[:status]).to eq("Live")
      expect(self_employed[:supported]).to be(true)
      expect(self_employed[:status]).to eq("Live")
      expect(company[:supported]).to be(false)
    end
  end

  describe ".call" do
    it "routes employee regimes to the employee calculator" do
      result = described_class.call(
        gross_income: 60_000,
        salary_period: "YEAR",
        tax_regime_key: "employee_madrid"
      )

      expect(result.dig(:metadata, :tax_regime_key)).to eq("employee_madrid")
    end

    it "routes self-employed regimes to the self-employed calculator" do
      result = described_class.call(
        gross_income: 60_000,
        deductible_expenses: 10_000,
        salary_period: "YEAR",
        tax_regime_key: "self_employed_madrid"
      )

      expect(result.dig(:metadata, :tax_regime_key)).to eq("self_employed_madrid")
      expect(result.dig(:breakdown, :annual_deductible_expenses)).to eq(10_000.0)
    end

    it "rejects unsupported regimes with a clear message" do
      expect do
        described_class.call(
          gross_income: 60_000,
          salary_period: "YEAR",
          tax_regime_key: "corporate_income_general"
        )
      end.to raise_error(
        described_class::UnsupportedRegimeError,
        "Corporate income tax - general is stored in the rules database, but its calculator flow is not implemented yet."
      )
    end
  end
end
