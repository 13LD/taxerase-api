require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "renders the home page" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase")
      expect(response.body).to include("country-calculator-app")
      expect(response.body).to include("Spain")
      expect(response.body).to include("Netherlands")
      expect(response.body).to include("Poland")
      expect(response.body).to include("Czech Republic")
      expect(response.body).to include("employee_madrid")
      expect(response.body).to include("self_employed_madrid")
      expect(response.body).to include("beckham_madrid")
      expect(response.body).to include("2024")
      expect(response.body).to include("2025")
      expect(response.body).to include("2026")
      expect(response.body).not_to include("employee_navarre")
    end

    it "renders the Netherlands calculator page when requested" do
      get root_path, params: { country: "NL" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Netherlands Tax Calculator")
      expect(response.body).to include("employee_netherlands")
      expect(response.body).to include("self_employed_netherlands")
      expect(response.body).to include("&quot;code&quot;:&quot;NL&quot;")
    end

    it "renders the Poland calculator page when requested" do
      get root_path, params: { country: "PL" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Poland Tax Calculator")
      expect(response.body).to include("employee_poland")
      expect(response.body).to include("&quot;code&quot;:&quot;PL&quot;")
      expect(response.body).to include("&quot;currency_code&quot;:&quot;PLN&quot;")
    end

    it "renders the Czech Republic calculator page when requested" do
      get root_path, params: { country: "CZ" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase | Czech Republic Tax Calculator")
      expect(response.body).to include("employee_czech_republic")
      expect(response.body).to include("&quot;code&quot;:&quot;CZ&quot;")
      expect(response.body).to include("&quot;currency_code&quot;:&quot;CZK&quot;")
    end
  end

  describe "GET /api/v1/countries/:country_code/calculator" do
    it "returns calculator props for a country without rendering the full page" do
      get api_v1_country_calculator_path(country_code: "NL")

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)

      expect(json["page_title"]).to eq("Taxerase | Netherlands Tax Calculator")
      expect(json.dig("calculator_props", "country", "code")).to eq("NL")
      expect(json.dig("calculator_props", "regime_options").map { |entry| entry["key"] })
        .to include("employee_netherlands", "self_employed_netherlands")
    end

    it "returns not found for an unknown country code" do
      get api_v1_country_calculator_path(country_code: "PT")

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)["errors"]).to include('No country calculator is registered for "PT".')
    end
  end
end
