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

      modelo_130 = spain.tax_reports.find_by!(key: "modelo_130", tax_year: 2026)
      modelo_303 = spain.tax_reports.find_by!(key: "modelo_303", tax_year: 2026)
      modelo_100 = spain.tax_reports.find_by!(key: "modelo_100", tax_year: 2026)
      modelo_130_2025 = spain.tax_reports.find_by!(key: "modelo_130", tax_year: 2025)
      modelo_100_2027 = spain.tax_reports.find_by!(key: "modelo_100", tax_year: 2027)
      btw_aangifte = netherlands.tax_reports.find_by!(key: "btw_aangifte_kwartaal", tax_year: 2026)
      annual_btw = netherlands.tax_reports.find_by!(key: "btw_aangifte_jaar", tax_year: 2026)
      opgaaf_icp = netherlands.tax_reports.find_by!(key: "opgaaf_icp", tax_year: 2026)
      inkomstenbelasting_2027 = netherlands.tax_reports.find_by!(key: "inkomstenbelasting", tax_year: 2027)

      expect(spain.tax_reports.where(tax_year: 2025..2027).group(:tax_year).count).to eq(
        2025 => 5,
        2026 => 5,
        2027 => 5
      )
      expect(modelo_130.report_workflows.pluck(:name)).to include("Submit Modelo 130")
      expect(modelo_100.report_workflows.pluck(:name)).to include("Choose Renta payment method")
      expect(workflow_for(modelo_130, "submit_modelo_130").reference_url).to eq(modelo_130_reference_url)
      expect(workflow_for(modelo_100, "choose_renta_payment_method").reference_url).to eq(renta_payment_reference_url)
      expect(modelo_130.report_events.pluck(:event_type)).to include("submission", "payment")
      expect(modelo_130_2025.report_events.find_by!(key: "q1_submission").window_start_date).to eq(Date.new(2025, 4, 1))
      expect(modelo_130.report_events.find_by!(key: "q1_submission").window_start_date).to eq(Date.new(2026, 4, 1))
      expect(modelo_303.report_events.find_by!(key: "q4_payment").event_date).to eq(Date.new(2027, 1, 30))
      expect(modelo_100.report_events.find_by!(key: "annual_submission").window_start_date).to eq(Date.new(2026, 4, 8))
      expect(modelo_100.report_events.find_by!(key: "second_split_payment").event_date).to eq(Date.new(2026, 11, 5))
      expect(modelo_100_2027.description).to include("2026 income year")
      expect(workflow_for(modelo_100_2027, "choose_renta_payment_method").reference_url).to be_nil
      expect(modelo_100_2027.report_events.find_by!(key: "annual_submission").window_start_date).to eq(Date.new(2027, 4, 8))

      expect(netherlands.tax_reports.where(tax_year: 2025..2027).group(:tax_year).count).to eq(
        2025 => 5,
        2026 => 5,
        2027 => 5
      )
      expect(btw_aangifte.report_workflows.pluck(:name)).to include("Submit BTW aangifte")
      expect(workflow_for(btw_aangifte, "submit_btw_aangifte").reference_url).to eq(btw_deadline_reference_url)
      expect(workflow_for(opgaaf_icp, "submit_opgaaf_icp").reference_url).to eq(icp_reference_url)
      expect(btw_aangifte.report_events.pluck(:event_type)).to include("submission", "payment")
      expect(btw_aangifte.report_events.find_by!(key: "q1_submission").window_start_date).to eq(Date.new(2026, 4, 1))
      expect(btw_aangifte.report_events.find_by!(key: "q4_payment").event_date).to eq(Date.new(2027, 1, 31))
      expect(annual_btw.report_events.find_by!(key: "annual_submission").window_end_date).to eq(Date.new(2027, 3, 31))
      expect(opgaaf_icp.report_events.find_by!(key: "q4_submission").event_date).to eq(Date.new(2027, 2, 28))
      expect(inkomstenbelasting_2027.description).to include("2027 income year")
      expect(inkomstenbelasting_2027.report_events.find_by!(key: "annual_submission").event_date).to eq(Date.new(2028, 5, 1))
    end
  end

  def regime_for(country, key, tax_year)
    TaxRegime.for_country_year(country:, tax_year:).find_by!(key:)
  end

  def workflow_for(report, key)
    report.report_workflows.find_by!(key:)
  end

  def modelo_130_reference_url
    "https://sede.agenciatributaria.gob.es/Sede/procedimientoini/G601.shtml"
  end

  def renta_payment_reference_url
    "https://sede.agenciatributaria.gob.es/Sede/ayuda/manuales-videos-folletos/manuales-ayuda-presentacion/irpf-2025/3-cuestiones-generales/3_3-declaracion-irpf/3_3_4-fraccionamiento-pago-domiciliacion.html"
  end

  def btw_deadline_reference_url
    "https://www.belastingdienst.nl/wps/wcm/connect/nl/btw/content/uiterste-aangifte-en-betaaldatums"
  end

  def icp_reference_url
    "https://www.belastingdienst.nl/wps/wcm/connect/bldcontentnl/belastingdienst/zakelijk/btw/zakendoen_met_het_buitenland/goederen_en_diensten_naar_andere_eu_landen/opgaaf_icp/"
  end

  def source_mismatches_for(country)
    TaxSourceUsage
      .joins(tax_regime: :tax_rule_set)
      .joins(:official_tax_source)
      .where(tax_rule_sets: { country_id: country.id })
      .where.not(official_tax_sources: { country_id: country.id })
  end
end
