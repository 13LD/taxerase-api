require "rails_helper"

RSpec.describe "Spain calculator selectors", type: :system, js: true do
  def within_calculator_card(&)
    within(".calculator-card", &)
  end

  def within_results_card(&)
    within(".results-card", &)
  end

  def expect_metric_card(label, value)
    within_results_card do
      card = find(".metric-card", text: label, match: :first)

      expect(card).to have_css(".metric-value", text: value)
    end
  end

  it "keeps a tax breakdown visible when switching to the self-employed profile" do
    visit root_path

    within_results_card do
      expect(page).to have_text("Annual net income")
      expect(page).to have_text("Monthly net income")
      expect(page).to have_text("Effective tax rate")
      expect(page).to have_text("Employee social security")
    end

    within(".assumptions-card") do
      expect(page).to have_text("Needs review")
      expect(page).to have_text("Regional deductions")
    end

    expect_metric_card("Annual net income", /€\d[\d,]*\.\d{2}/)
    expect_metric_card("Monthly net income", /€\d[\d,]*\.\d{2}/)
    expect_metric_card("Effective tax rate", /\d+\.\d{2}%/)

    within_calculator_card do
      click_button "B2B contract"
    end

    within_calculator_card do
      expect(page).to have_field("Gross income", with: "60000")
      expect(page).to have_field("Deductible expenses", with: "0")
    end

    within_results_card do
      expect(page).to have_text("Annual net income")
      expect(page).to have_text("Monthly net income")
      expect(page).to have_text("Effective tax rate")
      expect(page).to have_text("Deductible expenses")
      expect(page).to have_text("Self-employed social security")
      expect(page).to have_text("Estimated monthly RETA base")
      expect(page).not_to have_text("Awaiting recalculate")
      expect(page).not_to have_text("Coverage status")
      expect(page).not_to have_text("Official sources")
      expect(page).not_to have_text("Regime key")
      expect(page).not_to have_text("Calculation flow")
    end

    expect(page).to have_text("Resident self-employed - Andalusia")

    within_calculator_card do
      fill_in "Deductible expenses", with: "10000"
      click_button "Recalculate"
    end

    within_results_card do
      expect(page).to have_text("Self-employed social security")
      expect(page).not_to have_text("Awaiting recalculate")
    end

    expect_metric_card("Annual net income", /€\d[\d,]*\.\d{2}/)
    expect_metric_card("Monthly net income", /€\d[\d,]*\.\d{2}/)
    expect_metric_card("Effective tax rate", /\d+\.\d{2}%/)
    expect_metric_card("Deductible expenses", "€10,000.00")
  end

  it "recalculates automatically when the region dropdown changes for a supported flow" do
    visit root_path

    within_calculator_card do
      page.execute_script(<<~JS)
        window.__salaryCalcFetchCalls = [];
        const originalFetch = window.fetch.bind(window);
        window.fetch = (...args) => {
          if (String(args[0]).includes("/salary_calculation")) {
            window.__salaryCalcFetchCalls.push(String(args[0]));
          }
          return originalFetch(...args);
        };
      JS

      select "Madrid", from: "Region"
    end

    expect(page).to have_text("Resident employee - Madrid")
    expect(page.evaluate_script("window.__salaryCalcFetchCalls.length")).to eq(1)

    within_results_card do
      expect(page).to have_text("Income tax")
      expect(page).to have_text("Employee social security")
      expect(page).to have_text("Madrid minimum relief")
      expect(page).not_to have_text("Awaiting recalculate")
    end

    expect_metric_card("Annual net income", /€\d[\d,]*\.\d{2}/)
    expect_metric_card("Monthly net income", /€\d[\d,]*\.\d{2}/)
    expect_metric_card("Effective tax rate", /\d+\.\d{2}%/)
  end

  it "restores the prior result instead of staying stuck calculating when selectors revert" do
    visit root_path

    page.execute_script(<<~JS)
      window.__salaryCalcFetchCalls = [];
      const originalFetch = window.fetch.bind(window);
      window.fetch = (...args) => {
        if (String(args[0]).includes("/salary_calculation")) {
          const payload = JSON.parse(args[1]?.body || "{}");
          window.__salaryCalcFetchCalls.push(payload.calculation.tax_regime_key);

          if (payload.calculation.tax_regime_key === "employee_madrid") {
            return new Promise(() => {});
          }
        }

        return originalFetch(...args);
      };
    JS

    within_calculator_card do
      select "Madrid", from: "Region"
      select "Andalusia", from: "Region"
    end

    within_results_card do
      expect(page).to have_no_text("Calculating...", wait: 20)
      expect(page).to have_text("€41,545.15")
    end

    expect(page.evaluate_script("window.__salaryCalcFetchCalls")).to eq([ "employee_madrid" ])
  end

  it "recalculates automatically when the year dropdown changes to 2024" do
    visit root_path

    within_calculator_card do
      select "Madrid", from: "Region"
      select "2024", from: "Tax year"
    end

    expect(page).to have_text("Resident employee - Madrid")

    within_results_card do
      expect(page).to have_text("Income tax")
      expect(page).to have_text("Employee social security")
      expect(page).to have_text("Madrid minimum relief")
      expect(page).not_to have_text("Research pending")
    end

    expect_metric_card("Annual net income", /€\d[\d,]*\.\d{2}/)
    expect_metric_card("Monthly net income", /€\d[\d,]*\.\d{2}/)
    expect_metric_card("Effective tax rate", /\d+\.\d{2}%/)
  end

  it "recalculates automatically when age, children, and disability selectors change" do
    visit root_path

    within_calculator_card do
      select "Madrid", from: "Region"
      select "75+", from: "Taxpayer age"
      select "2", from: "Children", exact: true
      select "1", from: "Children under 3"
      select "65% or more", from: "Taxpayer disability"
    end

    within_results_card do
      expect(page).to have_text("State personal and family minimum")
      expect(page).to have_text("Madrid personal and family minimum")
    end

    expect_metric_card("State personal and family minimum", "€28,000.00")
    expect_metric_card("Madrid personal and family minimum", "€28,406.65")
    expect(page).to have_text("Profile inputs: 75 or older, 2 children (1 under 3), no ascendants, taxpayer disability 65% or more")
  end

  it "recalculates when expanded Spain family and employee deduction controls change" do
    visit root_path

    within_calculator_card do
      select "Madrid", from: "Region"
      select "1", from: "Dependent ascendants", exact: true
      select "1", from: "Ascendants over 75"
      select "1", from: "Ascendants disability 65%+"
      select "Married family unit", from: "Joint filing"
      fill_in "Union dues", with: "240"
      fill_in "Compulsory professional fees", with: "800"
      fill_in "Labor legal-defense costs", with: "500"
      select "65%+ or support needs", from: "Disabled worker expense"
      check "Apply geographic mobility expense"
      select "General category", from: "Large-family deduction"
      select "12", from: "Maternity deduction months"
      fill_in "Nursery expenses paid", with: "1500"
    end

    within_results_card do
      expect(page).to have_text("Additional employee expenses", wait: 20)
      expect(page).to have_text("Joint filing reduction")
      expect(page).to have_text("National family deductions")
      expect(page).to have_no_text("Calculating...", wait: 20)
    end
  end

  it "recalculates automatically when gross income and salary period change" do
    visit root_path

    within_results_card do
      expect(page).to have_text("€41,545.15")
    end

    within_calculator_card do
      fill_in "Gross income", with: "7000"
      expect(page).to have_field("Gross income", with: "7000")
      click_button "Monthly"
    end

    within_results_card do
      expect(page).to have_text("€55,089.92", wait: 20)
      expect(page).not_to have_text("€41,545.15")
    end
  end

  it "does not get stuck calculating for decimal gross income inputs" do
    visit root_path

    within_calculator_card do
      fill_in "Gross income", with: "7000.00"
    end

    within_results_card do
      expect(page).to have_no_text("Calculating...", wait: 20)
      expect(page).to have_text("€5,925.98")
    end

    within_calculator_card do
      fill_in "Gross income", with: "7000.50"
    end

    within_results_card do
      expect(page).to have_no_text("Calculating...", wait: 20)
      expect(page).to have_text("€5,926.48")
    end

    within_calculator_card do
      fill_in "Gross income", with: "7000.0000"
    end

    within_results_card do
      expect(page).to have_no_text("Calculating...", wait: 20)
      expect(page).to have_text("€5,925.98")
    end
  end

  it "shows only fully supported public options" do
    visit root_path

    tax_year_options = nil
    region_options = nil

    within_calculator_card do
      tax_year_options = find_field("Tax year").all("option").map(&:text)
      region_options = find_field("Region").all("option").map(&:text)
    end

    expect(tax_year_options).to eq([ "2024", "2025" ])
    expect(region_options).to include("Madrid")
    expect(region_options).not_to include("Navarre")
    expect(region_options).not_to include("Bizkaia")
    expect(page).not_to have_text("Research pending")
  end
end
