require "rails_helper"

RSpec.describe "Guest salary calculation access", type: :request do
  def json
    JSON.parse(response.body)
  end

  def expect_public_result_payload(payload)
    expect(payload.fetch("breakdown").keys).to contain_exactly(
      "annual_net_income",
      "monthly_net_income",
      "effective_tax_rate"
    )
    expect(payload.fetch("detail_cards")).to eq([])
    expect(payload.fetch("assumptions")).to eq([])
    expect(payload.fetch("sources")).to eq([])
    expect(payload.fetch("rule_statuses")).to eq([])
  end

  it "ignores hidden Spain inputs and returns only public result fields", :guest do
    post api_v1_spain_salary_calculation_path,
      params: {
        calculation: {
          gross_income: 60_000,
          input_currency_code: "EUR",
          salary_period: "MONTH",
          tax_year: 2025,
          tax_regime_key: "employee_madrid",
          ascendants_count: 1,
          children_count: 2,
          union_dues: 500
        }
      },
      as: :json

    expect(response).to have_http_status(:ok)

    expect_public_result_payload(json)
    expect(json.dig("input", "salary_period")).to eq("YEAR")
    expect(json.dig("input", "children_count")).to eq(0)
    expect(json.dig("input", "ascendants_count")).to eq(0)
    expect(json.dig("input", "union_dues")).to eq(0.0)
  end

  it "does not expose Spain special-regime calculation to guests", :guest do
    post api_v1_spain_salary_calculation_path,
      params: {
        calculation: {
          gross_income: 60_000,
          salary_period: "YEAR",
          tax_year: 2025,
          tax_regime_key: "beckham_madrid",
          apply_beckham_law: true
        }
      },
      as: :json

    expect(response).to have_http_status(:ok)

    expect_public_result_payload(json)
    expect(json.dig("metadata", "tax_regime_key")).not_to include("beckham")
    expect(json.dig("input", "apply_beckham_law")).to be_falsey
  end

  it "ignores hidden Netherlands optional inputs for guests", :guest do
    post api_v1_netherlands_salary_calculation_path,
      params: {
        calculation: {
          gross_income: 60_000,
          salary_period: "MONTH",
          tax_year: 2025,
          tax_regime_key: "employee_netherlands",
          apply_thirty_percent_ruling: true,
          fiscal_partner: true,
          children_under_12_count: 3
        }
      },
      as: :json

    expect(response).to have_http_status(:ok)

    expect_public_result_payload(json)
    expect(json.dig("input", "salary_period")).to eq("YEAR")
    expect(json.dig("input", "apply_thirty_percent_ruling")).to be(false)
    expect(json.dig("input", "fiscal_partner")).to be_falsey
    expect(json.dig("input", "children_under_12_count")).to eq(0)
  end
end
