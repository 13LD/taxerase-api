require "rails_helper"

RSpec.describe "Api::V1::ReportCalendars", type: :request do
  describe "GET /api/v1/countries/:country_code/report_calendar" do
    it "returns Spain report deadlines with workflows and typed events" do
      get api_v1_country_report_calendar_path(country_code: "ES"), params: { tax_year: 2026 }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      reports = json.fetch("reports")
      modelo_130 = report_by_key(reports, "modelo_130")
      modelo_303 = report_by_key(reports, "modelo_303")
      modelo_390 = report_by_key(reports, "modelo_390")
      modelo_349 = report_by_key(reports, "modelo_349")
      modelo_100 = report_by_key(reports, "modelo_100")

      expect(json.dig("country", "code")).to eq("ES")
      expect(json["tax_year"]).to eq(2026)
      expect(reports.map { |report| report["name"] }).to include("Modelo 100", "Modelo 130", "Modelo 303", "Modelo 390", "Modelo 349")
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

    it "returns an empty report list for countries without compliance report data" do
      get api_v1_country_report_calendar_path(country_code: "AD"), params: { tax_year: 2026 }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json.dig("country", "code")).to eq("AD")
      expect(json["reports"]).to eq([])
    end
  end

  def report_by_key(reports, key)
    reports.find { |report| report["key"] == key }
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
end
