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

      expect(regime_for(spain, "employee_madrid", 2025).country).to eq(spain)
      expect(regime_for(spain, "self_employed_madrid", 2025).country).to eq(spain)
      expect(regime_for(spain, "beckham_madrid", 2025).country).to eq(spain)
      expect(regime_for(netherlands, "employee_netherlands", 2025).country).to eq(netherlands)
      expect(regime_for(netherlands, "self_employed_netherlands", 2025).country).to eq(netherlands)
      expect(regime_for(poland, "employee_poland", 2025).country).to eq(poland)
      expect(regime_for(poland, "self_employed_poland", 2025).country).to eq(poland)
      expect(regime_for(czech_republic, "employee_czech_republic", 2025).country).to eq(czech_republic)
      expect(regime_for(czech_republic, "self_employed_czech_republic", 2025).country).to eq(czech_republic)
      expect(regime_for(portugal, "employee_portugal", 2025).country).to eq(portugal)
      expect(regime_for(portugal, "self_employed_portugal", 2025).country).to eq(portugal)
      expect(regime_for(andorra, "employee_andorra", 2025).country).to eq(andorra)
      expect(regime_for(andorra, "self_employed_andorra", 2025).country).to eq(andorra)

      andorra_source_mismatches = source_mismatches_for(andorra)
      spain_source_mismatches = source_mismatches_for(spain)
      netherlands_source_mismatches = source_mismatches_for(netherlands)
      poland_source_mismatches = source_mismatches_for(poland)
      czech_source_mismatches = source_mismatches_for(czech_republic)
      portugal_source_mismatches = source_mismatches_for(portugal)

      expect(andorra_source_mismatches).to be_empty
      expect(spain_source_mismatches).to be_empty
      expect(netherlands_source_mismatches).to be_empty
      expect(poland_source_mismatches).to be_empty
      expect(czech_source_mismatches).to be_empty
      expect(portugal_source_mismatches).to be_empty
    end
  end

  def regime_for(country, key, tax_year)
    TaxRegime.for_country_year(country:, tax_year:).find_by!(key:)
  end

  def source_mismatches_for(country)
    TaxSourceUsage
      .joins(tax_regime: :tax_rule_set)
      .joins(:official_tax_source)
      .where(tax_rule_sets: { country_id: country.id })
      .where.not(official_tax_sources: { country_id: country.id })
  end
end
