require "rails_helper"

RSpec.describe Taxerase::Comparisons::EcbReferenceRateConverter do
  subject(:converter) { described_class.new }

  describe "#convert_to_eur" do
    it "converts PLN to EUR using the configured ECB reference rate" do
      expect(converter.convert_to_eur(42_523, "PLN")).to eq(10_000.0)
    end

    it "converts CZK to EUR using the configured ECB reference rate" do
      expect(converter.convert_to_eur(243_770, "CZK")).to eq(10_000.0)
    end
  end

  describe "#reference_metadata" do
    it "exposes the ECB source and rate date" do
      expect(converter.reference_metadata).to include(
        base_currency_code: "EUR",
        provider: "ECB",
        rate_date: "2026-03-11"
      )
    end
  end
end
