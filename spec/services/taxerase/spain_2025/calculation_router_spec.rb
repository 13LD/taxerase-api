require "rails_helper"

RSpec.describe Taxerase::Spain2025::CalculationRouter do
  describe ".regime_options" do
    it "returns the db-backed regime options with support metadata" do
      options = described_class.regime_options
      employee = options.find { |option| option[:key] == "resident_employee_madrid" }
      self_employed = options.find { |option| option[:key] == "resident_self_employed_general" }

      expect(employee[:supported]).to be(true)
      expect(employee[:status]).to eq("Live")
      expect(self_employed[:supported]).to be(false)
      expect(self_employed[:status]).to eq("Research")
    end
  end

  describe ".call" do
    it "routes supported regimes to a live calculator" do
      result = described_class.call(
        gross_income: 60_000,
        salary_period: "YEAR",
        tax_regime_key: "resident_employee_madrid"
      )

      expect(result.dig(:metadata, :tax_regime_key)).to eq("resident_employee_madrid")
    end

    it "rejects unsupported regimes with a clear message" do
      expect do
        described_class.call(
          gross_income: 60_000,
          salary_period: "YEAR",
          tax_regime_key: "resident_self_employed_general"
        )
      end.to raise_error(
        described_class::UnsupportedRegimeError,
        "Resident self-employed - general is stored in the rules database, but its calculator flow is not implemented yet."
      )
    end
  end
end
