require "rails_helper"

RSpec.describe Taxerase::Seeds::TaxData do
  describe ".call" do
    it "keeps seeded regimes and sources attached to the correct country" do
      expect { described_class.call }.not_to raise_error

      spain = Country.find_by!(code: "ES")
      netherlands = Country.find_by!(code: "NL")

      expect(TaxRegime.find_by!(country: spain, key: "employee_madrid", tax_year: 2025).country).to eq(spain)
      expect(TaxRegime.find_by!(country: spain, key: "self_employed_madrid", tax_year: 2025).country).to eq(spain)
      expect(TaxRegime.find_by!(country: netherlands, key: "employee_netherlands", tax_year: 2025).country).to eq(netherlands)
      expect(TaxRegime.find_by!(country: netherlands, key: "self_employed_netherlands", tax_year: 2025).country).to eq(netherlands)

      spain_source_mismatches = TaxSourceUsage
        .joins(:tax_regime, :official_tax_source)
        .where(tax_regimes: { country_id: spain.id })
        .where.not(official_tax_sources: { country_code: "ES" })

      netherlands_source_mismatches = TaxSourceUsage
        .joins(:tax_regime, :official_tax_source)
        .where(tax_regimes: { country_id: netherlands.id })
        .where.not(official_tax_sources: { country_code: "NL" })

      expect(spain_source_mismatches).to be_empty
      expect(netherlands_source_mismatches).to be_empty
    end
  end
end
