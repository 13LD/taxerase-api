require "rails_helper"

RSpec.describe "Tax comparison", type: :system, js: true do
  def wait_for_comparison_results
    within(".comparison-card") do
      expect(page).to have_no_text("Refreshing comparison...", wait: 20)
      expect(page).to have_css(".comparison-table__row", text: "Annual net income", wait: 20)
    end
  end

  it "shows comparison metrics for Spain vs Netherlands" do
    visit root_path
    wait_for_comparison_results

    expect(first(".liquid-card")[:class]).to include("comparison-card")

    within(".comparison-card") do
      expect(page).to have_text("Compare two jurisdictions")
      expect(page).to have_text("Tax profile")
      expect(page).to have_field("Annual income", with: "60000")
      expect(page).to have_text("Gross income vs tax load")
      expect(page).to have_text("Based on annual income €60,000.00.")
      expect(page).to have_text("Annual net income")
      expect(page).to have_text("Monthly net income")
      expect(page).to have_text("Effective tax rate")
      expect(page).to have_text("Total tax")
      expect(page).to have_text(/Spain · Andalusia/i)
      expect(page).to have_text("Netherlands")
      expect(page).to have_text("-3.60%")
    end

    comparison_sides = all(".comparison-side")

    within(comparison_sides[1]) do
      expect(page).to have_select("Country", selected: "Netherlands")
      expect(page).to have_css("option", text: "Andorra")
      expect(page).to have_css("option", text: "Poland")
      expect(page).to have_css("option", text: "Czech Republic")
      expect(page).to have_css("option", text: "Portugal")
      expect(page).to have_select("Region", selected: "Netherlands", disabled: true)
    end

    annual_net_income_row = find(".comparison-table__row", text: "Annual net income")
    effective_tax_rate_row = find(".comparison-table__row", text: "Effective tax rate")
    total_tax_row = find(".comparison-table__row", text: "Total tax")

    expect(annual_net_income_row.find(".comparison-delta")[:class]).to include("comparison-delta--positive")
    expect(effective_tax_rate_row.find(".comparison-delta")[:class]).to include("comparison-delta--positive")
    expect(total_tax_row.find(".comparison-delta")[:class]).to include("comparison-delta--positive")
  end

  it "allows comparing Spain against Andorra" do
    visit root_path

    comparison_sides = all(".comparison-side")

    within(comparison_sides[1]) do
      select "Andorra", from: "Country"
      expect(page).to have_select("Region", selected: "Andorra", disabled: true)
    end

    wait_for_comparison_results

    within(".comparison-card") do
      expect(page).to have_text("Andorra")
      expect(page).to have_text("Annual net income")
      expect(page).to have_text("Total tax")
    end
  end

  it "allows comparing Spain against Spain with different regions" do
    visit root_path

    comparison_sides = all(".comparison-side")

    within(comparison_sides[1]) do
      select "Spain", from: "Country"
      select "Madrid", from: "Region"
    end

    wait_for_comparison_results

    within(".comparison-card") do
      expect(page).to have_text(/Spain · Andalusia/i)
      expect(page).to have_text(/Spain · Madrid/i)
      expect(page).to have_text("Annual net income")
      expect(page).to have_text("Total tax")
    end
  end

  it "keeps the comparison on the same profile when switching to self-employed" do
    visit root_path

    within(".comparison-card") do
      click_button "B2B contract"
      fill_in "Annual revenue before expenses", with: "70000"
      fill_in "Annual deductible expenses", with: "12000"
    end

    wait_for_comparison_results

    within(".comparison-card") do
      expect(page).to have_text("Comparing self-employed tax outcomes using the latest shared supported tax year: 2025.")
      expect(page).to have_text("Revenue vs tax load")
      expect(page).to have_text(
        "Based on annual revenue before expenses €70,000.00 and annual deductible expenses €12,000.00."
      )
      expect(page).to have_text("Total tax")
      expect(page).to have_text("Annual net income")
    end
  end

  it "keeps the selected tax profile when changing a comparison country" do
    visit root_path

    within(".comparison-card") do
      click_button "B2B contract"
      fill_in "Annual revenue before expenses", with: "70000"
      fill_in "Annual deductible expenses", with: "12000"
    end

    comparison_sides = all(".comparison-side")

    within(comparison_sides[1]) do
      select "Poland", from: "Country"
    end

    wait_for_comparison_results

    within(".comparison-card") do
      expect(page).to have_button("B2B contract", class: /is-active/)
      expect(page).to have_field("Annual revenue before expenses", with: "70000")
      expect(page).to have_field("Annual deductible expenses", with: "12000")
      expect(page).to have_text("Comparing self-employed tax outcomes")
    end
  end

  it "keeps comparison currency inputs stable after refreshes" do
    visit root_path

    within(".comparison-card") do
      fill_in "Annual income", with: "450000"
      expect(page).to have_field("Annual income", with: "450000")

      click_button "B2B contract"
      fill_in "Annual revenue before expenses", with: "450000"
      fill_in "Annual deductible expenses", with: "12000"

      expect(page).to have_field("Annual revenue before expenses", with: "450000")
      expect(page).to have_field("Annual deductible expenses", with: "12000")
    end

    wait_for_comparison_results

    within(".comparison-card") do
      expect(page).to have_field("Annual revenue before expenses", with: "450000")
      expect(page).to have_field("Annual deductible expenses", with: "12000")
    end
  end

  it "marks unfavorable deltas in red" do
    visit root_path

    comparison_sides = all(".comparison-side")

    within(comparison_sides[0]) do
      select "Spain", from: "Country"
      select "Madrid", from: "Region"
    end

    within(comparison_sides[1]) do
      select "Spain", from: "Country"
      select "Andalusia", from: "Region"
    end

    wait_for_comparison_results

    annual_net_income_row = find(".comparison-table__row", text: "Annual net income")
    total_tax_row = find(".comparison-table__row", text: "Total tax")

    expect(annual_net_income_row).to have_text("-")
    expect(total_tax_row).to have_text("+")
    expect(annual_net_income_row.find(".comparison-delta")[:class]).to include("comparison-delta--negative")
    expect(total_tax_row.find(".comparison-delta")[:class]).to include("comparison-delta--negative")
  end

  it "shows ECB-normalized EUR values with local notes for Poland comparisons" do
    visit root_path

    comparison_sides = all(".comparison-side")

    within(comparison_sides[1]) do
      select "Poland", from: "Country"
      expect(page).to have_select("Region", selected: "Poland", disabled: true)
    end

    wait_for_comparison_results

    within(".comparison-card") do
      expect(page).to have_text("Shared income inputs are interpreted in EUR.")
      expect(page).to have_text("Mixed-currency comparison table metrics are normalized to EUR using exchange rates from 2026-03-11.")
      expect(page).to have_text("Poland")
    end

    annual_net_income_row = find(".comparison-table__row", text: "Annual net income")

    expect(annual_net_income_row).to have_text("€")
    expect(annual_net_income_row).to have_text("Local PLN")
  end

  it "allows switching the mixed-country comparison input currency to Czech koruna" do
    visit root_path

    comparison_sides = all(".comparison-side")

    within(comparison_sides[1]) do
      select "Czech Republic", from: "Country"
      expect(page).to have_select("Region", selected: "Czech Republic", disabled: true)
    end

    within(".comparison-card") do
      expect(page).to have_select("Input currency", options: [ "EUR", "CZK" ])
      select "CZK", from: "Input currency"
      click_button "B2B contract"
      fill_in "Annual revenue before expenses", with: "600000"
    end

    wait_for_comparison_results

    within(".comparison-card") do
      expect(page).to have_select("Input currency", selected: "CZK")
      expect(page).to have_text("Shared income inputs are interpreted in CZK.")
      expect(page).to have_text("Local CZK")
    end

    within(all(".comparison-graphic__panel")[1]) do
      expect(page).to have_text("CZK")
      expect(page).to have_text("€")
    end
  end
end
