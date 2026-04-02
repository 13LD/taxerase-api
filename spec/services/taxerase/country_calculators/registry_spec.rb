require "rails_helper"

RSpec.describe Taxerase::CountryCalculators::Registry do
  describe ".default" do
    it "returns the default country calculator definition" do
      expect(described_class.default).to be_a(Taxerase::CountryCalculators::SpainDefinition)
    end
  end

  describe ".country_options" do
    it "lists the registered public country calculators" do
      expect(described_class.country_options).to include(include(code: "ES", name: "Spain", currency_code: "EUR"))
      expect(described_class.country_options).to include(include(code: "NL", name: "Netherlands", currency_code: "EUR"))
      expect(described_class.country_options).to include(include(code: "PL", name: "Poland", currency_code: "PLN"))
      expect(described_class.country_options).to include(include(code: "CZ", name: "Czech Republic", currency_code: "CZK"))
    end
  end

  describe ".comparison_profile_catalog" do
    it "lists registered comparison profiles from the country definitions" do
      expect(described_class.comparison_profile_catalog).to include(
        include(key: "employee", uses_deductible_expenses: false),
        include(key: "self_employed", uses_deductible_expenses: true)
      )
    end
  end

  describe ".fetch_comparison_profile" do
    it "resolves a registered comparison profile" do
      expect(described_class.fetch_comparison_profile("employee"))
        .to include(key: "employee", uses_deductible_expenses: false)
    end

    it "raises a clear error for unknown comparison profiles" do
      expect { described_class.fetch_comparison_profile("special_regime") }
        .to raise_error(KeyError, 'No comparison profile is registered for "special_regime".')
    end
  end

  describe ".fetch" do
    it "resolves a registered country calculator" do
      definition = described_class.fetch("es")

      expect(definition).to be_a(Taxerase::CountryCalculators::SpainDefinition)
      expect(definition.country).to eq(code: "ES", name: "Spain", currency_code: "EUR")
    end

    it "raises a clear error for unknown countries" do
      expect { described_class.fetch("PT") }
        .to raise_error(KeyError, 'No country calculator is registered for "PT".')
    end

    it "resolves the Netherlands country calculator" do
      definition = described_class.fetch("nl")

      expect(definition).to be_a(Taxerase::CountryCalculators::NetherlandsDefinition)
      expect(definition.country).to eq(code: "NL", name: "Netherlands", currency_code: "EUR")
    end

    it "resolves the Poland country calculator" do
      definition = described_class.fetch("pl")

      expect(definition).to be_a(Taxerase::CountryCalculators::PolandDefinition)
      expect(definition.country).to eq(code: "PL", name: "Poland", currency_code: "PLN")
    end

    it "resolves the Czech Republic country calculator" do
      definition = described_class.fetch("cz")

      expect(definition).to be_a(Taxerase::CountryCalculators::CzechRepublicDefinition)
      expect(definition.country).to eq(code: "CZ", name: "Czech Republic", currency_code: "CZK")
    end
  end
end
