require "rails_helper"

RSpec.describe Taxerase::CountryCalculators::Registry do
  describe ".default" do
    it "returns the default country calculator definition" do
      expect(described_class.default).to be_a(Taxerase::CountryCalculators::SpainDefinition)
    end
  end

  describe ".country_options" do
    it "lists the registered public country calculators" do
      expect(described_class.country_options).to include(code: "ES", name: "Spain")
      expect(described_class.country_options).to include(code: "NL", name: "Netherlands")
    end
  end

  describe ".fetch" do
    it "resolves a registered country calculator" do
      definition = described_class.fetch("es")

      expect(definition).to be_a(Taxerase::CountryCalculators::SpainDefinition)
      expect(definition.country).to eq(code: "ES", name: "Spain")
    end

    it "raises a clear error for unknown countries" do
      expect { described_class.fetch("PT") }
        .to raise_error(KeyError, 'No country calculator is registered for "PT".')
    end

    it "resolves the Netherlands country calculator" do
      definition = described_class.fetch("nl")

      expect(definition).to be_a(Taxerase::CountryCalculators::NetherlandsDefinition)
      expect(definition.country).to eq(code: "NL", name: "Netherlands")
    end
  end
end
