require "rails_helper"

RSpec.describe "Api::V1::ReportCalendars", type: :request do
  describe "GET /api/v1/countries/:country_code/report_calendar" do
    before do |example|
      sign_in_api_user unless example.metadata[:skip_calendar_auth]
    end

    it "requires authentication", :skip_calendar_auth do
      get api_v1_country_report_calendar_path(country_code: "ES"), params: { tax_year: 2026 }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)["errors"]).to include("Sign in to open the calendar.")
    end

    it "requires a profile country", :skip_calendar_auth do
      user = User.create!(
        email: "calendar-no-profile@example.com",
        password: "password123",
        confirmed_at: Time.current
      )
      sign_in user

      get api_v1_country_report_calendar_path(country_code: "ES"), params: { tax_year: 2026 }

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body)["errors"])
        .to include("Add a country to your profile before opening the calendar.")
    end

    it "returns Spain report deadlines with workflows and typed events" do
      get api_v1_country_report_calendar_path(country_code: "ES"), params: { tax_year: 2026 }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      reports = expect_multi_year_calendar(json, country_code: "ES")
      modelo_130 = report_by_key_and_year(reports, "modelo_130", 2026)
      modelo_303 = report_by_key_and_year(reports, "modelo_303", 2026)
      modelo_390 = report_by_key_and_year(reports, "modelo_390", 2026)
      modelo_349 = report_by_key_and_year(reports, "modelo_349", 2026)
      modelo_100 = report_by_key_and_year(reports, "modelo_100", 2026)
      modelo_303_2027 = report_by_key_and_year(reports, "modelo_303", 2027)
      modelo_100_2027 = report_by_key_and_year(reports, "modelo_100", 2027)

      expect(reports.map { |report| report["name"] }).to include(
        "Modelo 100",
        "Modelo 130",
        "Modelo 303",
        "Modelo 390",
        "Modelo 349"
      )
      expect(report_by_key_and_year(reports, "modelo_130", 2025)["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2025-04-20",
          "window_start_date" => "2025-04-01",
          "window_end_date" => "2025-04-20"
        )
      )
      expect(report_by_key_and_year(reports, "modelo_100", 2027)["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2027-06-30",
          "window_start_date" => "2027-04-08",
          "window_end_date" => "2027-06-30"
        )
      )
      expect(modelo_303_2027["events"]).to include(
        hash_including("event_type" => "payment", "event_date" => "2028-01-30")
      )
      expect(modelo_130["workflows"].map { |workflow| workflow["name"] }).to include(
        "Prepare quarterly IRPF inputs",
        "Submit Modelo 130",
        "Settle the quarterly IRPF payment"
      )
      expect(workflow_by_key(modelo_130, "submit_modelo_130")["reference_url"]).to eq(modelo_130_reference_url)
      expect(modelo_130["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2026-04-20",
          "window_start_date" => "2026-04-01",
          "window_end_date" => "2026-04-20"
        ),
        hash_including("event_type" => "payment", "event_date" => "2026-04-20")
      )
      expect(modelo_303["events"]).to include(
        hash_including("event_type" => "payment", "event_date" => "2027-01-30")
      )
      expect(modelo_390["events"]).to contain_exactly(
        hash_including("event_type" => "submission", "event_date" => "2027-01-30")
      )
      expect(modelo_349["events"].map { |event| event["event_type"] }).to all(eq("submission"))
      expect(modelo_100["workflows"].map { |workflow| workflow["name"] }).to include(
        "Review Renta taxpayer data",
        "Submit Modelo 100",
        "Choose Renta payment method"
      )
      expect(workflow_by_key(modelo_100, "choose_renta_payment_method")["reference_url"]).to eq(renta_payment_reference_url)
      expect(workflow_by_key(modelo_100_2027, "choose_renta_payment_method")["reference_url"]).to be_nil
      expect(modelo_100["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2026-06-30",
          "window_start_date" => "2026-04-08",
          "window_end_date" => "2026-06-30"
        ),
        hash_including("event_type" => "payment", "event_date" => "2026-06-30"),
        hash_including("event_type" => "payment", "event_date" => "2026-11-05")
      )
    end

    it "returns Netherlands report deadlines with workflows and spillover events" do
      get api_v1_country_report_calendar_path(country_code: "NL"), params: { tax_year: 2026 }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      reports = expect_multi_year_calendar(json, country_code: "NL")
      btw_aangifte = report_by_key_and_year(reports, "btw_aangifte_kwartaal", 2026)
      annual_btw = report_by_key_and_year(reports, "btw_aangifte_jaar", 2026)
      opgaaf_icp = report_by_key_and_year(reports, "opgaaf_icp", 2026)
      oss_btw = report_by_key_and_year(reports, "oss_btw_melding", 2026)
      inkomstenbelasting = report_by_key_and_year(reports, "inkomstenbelasting", 2026)
      btw_aangifte_2027 = report_by_key_and_year(reports, "btw_aangifte_kwartaal", 2027)
      inkomstenbelasting_2027 = report_by_key_and_year(reports, "inkomstenbelasting", 2027)

      expect(reports.map { |report| report["name"] }).to include(
        "BTW aangifte",
        "Annual BTW aangifte",
        "Opgaaf ICP",
        "OSS BTW melding",
        "Inkomstenbelasting"
      )
      expect(btw_aangifte["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2026-04-30",
          "window_start_date" => "2026-04-01",
          "window_end_date" => "2026-04-30"
        ),
        hash_including("event_type" => "payment", "event_date" => "2027-01-31")
      )
      expect(btw_aangifte_2027["events"]).to include(
        hash_including("event_type" => "payment", "event_date" => "2028-01-31")
      )
      expect(annual_btw["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2027-03-31",
          "window_start_date" => "2027-01-01",
          "window_end_date" => "2027-03-31"
        )
      )
      expect(opgaaf_icp["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2027-02-28",
          "window_start_date" => "2027-01-01",
          "window_end_date" => "2027-02-28"
        )
      )
      expect(oss_btw["events"]).to include(
        hash_including("event_type" => "payment", "event_date" => "2027-01-31")
      )
      expect(workflow_by_key(btw_aangifte, "submit_btw_aangifte")["reference_url"]).to eq(btw_deadline_reference_url)
      expect(workflow_by_key(opgaaf_icp, "submit_opgaaf_icp")["reference_url"]).to eq(icp_reference_url)
      expect(workflow_by_key(oss_btw, "submit_and_pay_oss")["reference_url"]).to eq(oss_reference_url)
      expect(inkomstenbelasting["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2027-05-01",
          "window_start_date" => "2027-03-01",
          "window_end_date" => "2027-05-01"
        )
      )
      expect(inkomstenbelasting_2027["events"]).to include(
        hash_including("event_type" => "submission", "event_date" => "2028-05-01")
      )
    end

    it "returns Portugal report deadlines with workflows and spillover events" do
      get api_v1_country_report_calendar_path(country_code: "PT"), params: { tax_year: 2026 }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      reports = expect_multi_year_calendar(json, country_code: "PT", expected_reports_per_year: 5)
      modelo_3 = report_by_key_and_year(reports, "irs_modelo_3", 2026)
      irs_payments = report_by_key_and_year(reports, "irs_pagamentos_por_conta", 2026)
      quarterly_iva = report_by_key_and_year(reports, "iva_periodica_trimestral", 2026)
      monthly_iva = report_by_key_and_year(reports, "iva_periodica_mensal", 2026)
      invoice_communication = report_by_key_and_year(reports, "comunicacao_faturas", 2026)
      quarterly_iva_2027 = report_by_key_and_year(reports, "iva_periodica_trimestral", 2027)

      expect(reports.map { |report| report["name"] }).to include(
        "Declaracao Modelo 3",
        "IRS payments on account",
        "Quarterly IVA return",
        "Monthly IVA return",
        "Invoice communication"
      )
      expect(modelo_3["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2026-06-30",
          "window_start_date" => "2026-04-01",
          "window_end_date" => "2026-06-30"
        ),
        hash_including("event_type" => "payment", "event_date" => "2026-08-31")
      )
      expect(irs_payments["events"].map { |event| event["event_date"] }).to eq(
        %w[2026-07-20 2026-09-21 2026-12-21]
      )
      expect(quarterly_iva["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2027-02-20",
          "window_start_date" => "2027-02-01",
          "window_end_date" => "2027-02-20"
        ),
        hash_including("event_type" => "payment", "event_date" => "2027-02-25")
      )
      expect(quarterly_iva_2027["events"]).to include(
        hash_including("event_type" => "payment", "event_date" => "2028-02-25")
      )
      expect(monthly_iva["workflows"].map { |workflow| workflow["name"] }).to include(
        "Confirm monthly IVA status",
        "Submit monthly IVA return",
        "Pay monthly IVA"
      )
      expect(workflow_by_key(monthly_iva, "submit_monthly_iva")["reference_url"]).to eq(portugal_declarations_reference_url)
      expect(workflow_by_key(quarterly_iva, "pay_quarterly_iva")["reference_url"]).to eq(portugal_payments_reference_url)
      expect(invoice_communication["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2026-08-31",
          "window_start_date" => "2026-08-01",
          "window_end_date" => "2026-08-31"
        )
      )
    end

    it "returns Poland report deadlines with PIT, JPK, ZUS, and KSeF workflows" do
      get api_v1_country_report_calendar_path(country_code: "PL"), params: { tax_year: 2026 }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      reports = expect_multi_year_calendar(json, country_code: "PL", expected_reports_per_year: 5)
      pit_annual = report_by_key_and_year(reports, "pit_annual", 2026)
      jpk_v7m = report_by_key_and_year(reports, "jpk_v7_monthly", 2026)
      ksef_rollout = report_by_key_and_year(reports, "ksef_rollout", 2026)

      expect(reports.map { |report| report["name"] }).to include(
        "Annual PIT return",
        "Monthly PIT advances",
        "Monthly JPK_V7M VAT return",
        "Monthly ZUS DRA",
        "KSeF rollout"
      )
      expect(pit_annual["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2026-04-30",
          "window_start_date" => "2026-02-15",
          "window_end_date" => "2026-04-30"
        )
      )
      expect(jpk_v7m["events"]).to include(
        hash_including("event_type" => "submission", "event_date" => "2026-12-28"),
        hash_including("event_type" => "payment", "event_date" => "2027-01-25")
      )
      expect(workflow_by_key(ksef_rollout, "configure_ksef_access")["reference_url"]).to eq(ksef_reference_url)
      expect(ksef_rollout["events"]).to include(
        hash_including("event_type" => "submission", "event_date" => "2026-02-01"),
        hash_including("event_type" => "submission", "event_date" => "2026-04-01")
      )
    end

    it "returns Czech Republic report deadlines with income tax, VAT, control statement, and pausalni workflows" do
      get api_v1_country_report_calendar_path(country_code: "CZ"), params: { tax_year: 2026 }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      reports = expect_multi_year_calendar(json, country_code: "CZ", expected_reports_per_year: 5)
      income_tax = report_by_key_and_year(reports, "personal_income_tax_return", 2026)
      vat_return = report_by_key_and_year(reports, "vat_return_monthly", 2026)
      control_statement = report_by_key_and_year(reports, "vat_control_statement_monthly", 2026)
      pausalni_dan = report_by_key_and_year(reports, "pausalni_dan_monthly", 2026)

      expect(reports.map { |report| report["name"] }).to include(
        "Personal income tax return",
        "Monthly VAT return",
        "Monthly VAT control statement",
        "Monthly pausalni dan advance",
        "Monthly payroll withholding"
      )
      expect(income_tax["events"]).to include(
        hash_including("event_type" => "submission", "event_date" => "2026-04-01"),
        hash_including("event_type" => "submission", "event_date" => "2026-05-04"),
        hash_including("event_type" => "submission", "event_date" => "2026-07-01")
      )
      expect(vat_return["events"]).to include(
        hash_including("event_type" => "submission", "event_date" => "2026-12-28"),
        hash_including("event_type" => "payment", "event_date" => "2027-01-25")
      )
      expect(workflow_by_key(control_statement, "submit_control_statement")["reference_url"]).to eq(czech_control_statement_reference_url)
      expect(pausalni_dan["events"]).to include(
        hash_including("event_type" => "payment", "event_date" => "2026-01-20"),
        hash_including("event_type" => "payment", "event_date" => "2026-12-21")
      )
    end

    it "returns Andorra report deadlines with IRPF, IGI, and IS workflows" do
      get api_v1_country_report_calendar_path(country_code: "AD"), params: { tax_year: 2026 }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      reports = expect_multi_year_calendar(json, country_code: "AD", expected_reports_per_year: 6)
      irpf = report_by_key_and_year(reports, "irpf_form_300", 2026)
      irpf_payment = report_by_key_and_year(reports, "irpf_form_320", 2026)
      semiannual_igi = report_by_key_and_year(reports, "igi_form_900_semiannual", 2026)
      quarterly_igi = report_by_key_and_year(reports, "igi_form_900_quarterly", 2026)
      monthly_igi = report_by_key_and_year(reports, "igi_form_900_monthly", 2026)
      corporate_tax = report_by_key_and_year(reports, "is_form_805", 2026)

      expect(reports.map { |report| report["name"] }).to include(
        "IRPF annual return",
        "IRPF payment on account",
        "Semiannual IGI return",
        "Quarterly IGI return",
        "Monthly IGI return",
        "Corporate tax return"
      )
      expect(irpf["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2026-09-30",
          "window_start_date" => "2026-04-01",
          "window_end_date" => "2026-09-30"
        ),
        hash_including("event_type" => "payment", "event_date" => "2026-09-30")
      )
      expect(workflow_by_key(irpf, "submit_irpf_form_300")["reference_url"]).to eq(andorra_irpf_reference_url)
      expect(irpf_payment["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2026-09-30",
          "window_start_date" => "2026-09-01",
          "window_end_date" => "2026-09-30"
        )
      )
      expect(workflow_by_key(irpf_payment, "submit_irpf_form_320")["reference_url"])
        .to eq(andorra_irpf_payment_reference_url)
      expect(semiannual_igi["events"]).to include(
        hash_including("event_type" => "submission", "event_date" => "2026-07-31"),
        hash_including("event_type" => "payment", "event_date" => "2027-01-31")
      )
      expect(quarterly_igi["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2026-04-30",
          "window_start_date" => "2026-04-01",
          "window_end_date" => "2026-04-30"
        ),
        hash_including("event_type" => "payment", "event_date" => "2027-01-31")
      )
      expect(workflow_by_key(quarterly_igi, "submit_quarterly_igi")["reference_url"]).to eq(andorra_igi_reference_url)
      expect(monthly_igi["events"]).to include(
        hash_including("event_type" => "submission", "event_date" => "2026-02-28"),
        hash_including("event_type" => "payment", "event_date" => "2027-01-31")
      )
      expect(corporate_tax["events"]).to include(
        hash_including(
          "event_type" => "submission",
          "event_date" => "2026-07-31",
          "window_start_date" => "2026-07-01",
          "window_end_date" => "2026-07-31"
        ),
        hash_including(
          "event_type" => "payment",
          "event_date" => "2026-09-30",
          "window_start_date" => "2026-09-01",
          "window_end_date" => "2026-09-30"
        )
      )
      expect(workflow_by_key(corporate_tax, "submit_is_form_805")["reference_url"]).to eq(andorra_is_reference_url)
      expect(workflow_by_key(corporate_tax, "submit_is_form_810")["reference_url"])
        .to eq(andorra_is_payment_reference_url)
    end

    it "returns an empty report list for countries without compliance report data" do
      Country.create!(code: "ZZ", name: "No Calendar", currency_code: "EUR")

      get api_v1_country_report_calendar_path(country_code: "ZZ"), params: { tax_year: 2026 }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("country", "code")).to eq("ZZ")
      expect(json["reports"]).to eq([])
    end
  end

  def expect_multi_year_calendar(json, country_code:, expected_reports_per_year: 5)
    reports = json.fetch("reports")

    expect(json.dig("country", "code")).to eq(country_code)
    expect(json["tax_year"]).to eq(2026)
    expect(json["tax_years"]).to eq([ 2025, 2026, 2027 ])
    expect(json["start_year"]).to eq(2025)
    expect(json["end_year"]).to eq(2027)
    expect(reports.size).to eq(expected_reports_per_year * 3)
    expect(reports.map { |report| report["tax_year"] }.uniq).to eq([ 2025, 2026, 2027 ])

    reports
  end

  def report_by_key_and_year(reports, key, tax_year)
    reports.find { |report| report["key"] == key && report["tax_year"] == tax_year }
  end

  def workflow_by_key(report, key)
    report.fetch("workflows").find { |workflow| workflow["key"] == key }
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

  def oss_reference_url
    "https://www.belastingdienst.nl/e-commerce"
  end

  def portugal_declarations_reference_url
    "https://info.portaldasfinancas.gov.pt/pt/apoio_contribuinte/calendario_fiscal/Pages/Quadro_res_Decl_2026.aspx"
  end

  def portugal_payments_reference_url
    "https://info.portaldasfinancas.gov.pt/pt/apoio_contribuinte/calendario_fiscal/Pages/Quadro_res_Pag_2026.aspx"
  end

  def ksef_reference_url
    "https://ksef.podatki.gov.pl/informacje-ogolne-ksef-20/zakres-obowiazkowego-ksef/"
  end

  def czech_control_statement_reference_url
    "https://portal.gov.cz/en/sluzby-vs/vat-control-statement-S20031"
  end

  def andorra_irpf_reference_url
    "https://www.e-tramits.ad/tramits/ca/declaracio-de-limpost-sobre-la-renda-de-les-persones-fisiques-irpf/p/tr-irpf"
  end

  def andorra_irpf_payment_reference_url
    "https://www.e-tramits.ad/tramits/ca/impostos/tr-irpf-320"
  end

  def andorra_igi_reference_url
    "https://www.e-tramits.ad/tramits/ca/impost-general-indirecte-igi/p/tr-igi"
  end

  def andorra_is_reference_url
    "https://www.e-tramits.ad/tramits/ca/declaracio-de-limpost-sobre-societats-is/p/tr-isu"
  end

  def andorra_is_payment_reference_url
    "https://www.e-tramits.ad/tramits/ca/declaracio-de-limpost-sobre-societats-is/p/tr-isu"
  end
end
