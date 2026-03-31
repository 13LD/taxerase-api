require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "renders the home page" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Taxerase")
      expect(response.body).to include("country-calculator-app")
      expect(response.body).to include("employee_madrid")
      expect(response.body).to include("self_employed_madrid")
      expect(response.body).to include("2024")
      expect(response.body).to include("2025")
      expect(response.body).not_to include("employee_navarre")
      expect(response.body).not_to include("2026")
    end
  end
end
