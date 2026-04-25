require "rails_helper"

RSpec.describe "Api::V1::ReportCalendars", type: :request do
  describe "GET /api/v1/countries/:country_code/report_calendar" do
    it "returns Spain report deadlines with workflows and typed events" do
      get api_v1_country_report_calendar_path(country_code: "ES"), params: { tax_year: 2026 }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      reports = json.fetch("reports")
      modelo_130 = reports.find { |report| report["key"] == "modelo_130" }
      modelo_303 = reports.find { |report| report["key"] == "modelo_303" }
      modelo_390 = reports.find { |report| report["key"] == "modelo_390" }
      modelo_349 = reports.find { |report| report["key"] == "modelo_349" }
      modelo_100 = reports.find { |report| report["key"] == "modelo_100" }

      expect(json.dig("country", "code")).to eq("ES")
      expect(json["tax_year"]).to eq(2026)
      expect(reports.map { |report| report["name"] }).to include("Modelo 100", "Modelo 130", "Modelo 303", "Modelo 390", "Modelo 349")
      expect(modelo_130["workflows"].first["description"]).to include("submit Modelo 130")
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
      expect(modelo_100["workflows"].first["description"]).to include("60/40 split payment")
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
end
