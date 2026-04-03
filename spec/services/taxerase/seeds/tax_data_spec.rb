require "rails_helper"

RSpec.describe Taxerase::Seeds::TaxData do
  describe ".call" do
    it "keeps seeded regimes and sources attached to the correct country" do
      expect { described_class.call }.not_to raise_error

      spain = Country.find_by!(code: "ES")
      netherlands = Country.find_by!(code: "NL")
      poland = Country.find_by!(code: "PL")
      czech_republic = Country.find_by!(code: "CZ")
      portugal = Country.find_by!(code: "PT")
      andorra = Country.find_by!(code: "AD")

      expect(TaxRegime.find_by!(country: spain, key: "employee_madrid", tax_year: 2025).country).to eq(spain)
      expect(TaxRegime.find_by!(country: spain, key: "self_employed_madrid", tax_year: 2025).country).to eq(spain)
      expect(TaxRegime.find_by!(country: spain, key: "beckham_madrid", tax_year: 2025).country).to eq(spain)
      expect(TaxRegime.find_by!(country: netherlands, key: "employee_netherlands", tax_year: 2025).country).to eq(netherlands)
      expect(TaxRegime.find_by!(country: netherlands, key: "self_employed_netherlands", tax_year: 2025).country).to eq(netherlands)
      expect(TaxRegime.find_by!(country: poland, key: "employee_poland", tax_year: 2025).country).to eq(poland)
      expect(TaxRegime.find_by!(country: poland, key: "self_employed_poland", tax_year: 2025).country).to eq(poland)
      expect(TaxRegime.find_by!(country: czech_republic, key: "employee_czech_republic", tax_year: 2025).country).to eq(czech_republic)
      expect(TaxRegime.find_by!(country: czech_republic, key: "self_employed_czech_republic", tax_year: 2025).country).to eq(czech_republic)
      expect(TaxRegime.find_by!(country: portugal, key: "employee_portugal", tax_year: 2025).country).to eq(portugal)
      expect(TaxRegime.find_by!(country: portugal, key: "self_employed_portugal", tax_year: 2025).country).to eq(portugal)
      expect(TaxRegime.find_by!(country: andorra, key: "employee_andorra", tax_year: 2025).country).to eq(andorra)
      expect(TaxRegime.find_by!(country: andorra, key: "self_employed_andorra", tax_year: 2025).country).to eq(andorra)

      andorra_source_mismatches = TaxSourceUsage
        .joins(:tax_regime, :official_tax_source)
        .where(tax_regimes: { country_id: andorra.id })
        .where.not(official_tax_sources: { country_code: "AD" })

      spain_source_mismatches = TaxSourceUsage
        .joins(:tax_regime, :official_tax_source)
        .where(tax_regimes: { country_id: spain.id })
        .where.not(official_tax_sources: { country_code: "ES" })

      netherlands_source_mismatches = TaxSourceUsage
        .joins(:tax_regime, :official_tax_source)
        .where(tax_regimes: { country_id: netherlands.id })
        .where.not(official_tax_sources: { country_code: "NL" })

      poland_source_mismatches = TaxSourceUsage
        .joins(:tax_regime, :official_tax_source)
        .where(tax_regimes: { country_id: poland.id })
        .where.not(official_tax_sources: { country_code: "PL" })

      czech_source_mismatches = TaxSourceUsage
        .joins(:tax_regime, :official_tax_source)
        .where(tax_regimes: { country_id: czech_republic.id })
        .where.not(official_tax_sources: { country_code: "CZ" })

      portugal_source_mismatches = TaxSourceUsage
        .joins(:tax_regime, :official_tax_source)
        .where(tax_regimes: { country_id: portugal.id })
        .where.not(official_tax_sources: { country_code: "PT" })

      expect(andorra_source_mismatches).to be_empty
      expect(spain_source_mismatches).to be_empty
      expect(netherlands_source_mismatches).to be_empty
      expect(poland_source_mismatches).to be_empty
      expect(czech_source_mismatches).to be_empty
      expect(portugal_source_mismatches).to be_empty
    end
  end
end
