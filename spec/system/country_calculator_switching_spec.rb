require "rails_helper"

RSpec.describe "Country calculator switching", type: :system, js: true do
  def switch_country(country_name, heading:)
    within(".calculator-card") do
      select country_name, from: "Country"
    end

    within(".calculator-card") do
      expect(page).to have_text(heading, wait: 20)
      expect(page).to have_select("Country", selected: country_name, wait: 20)
    end
  end

  it "switches from Spain to Netherlands and loads country-specific fields" do
    visit root_path
    page.execute_script("window.__country_switch_marker = 'keep'")

    within(".calculator-card") do
      expect(page).to have_select("Country", selected: "Spain")
      expect(page).to have_text("Resident employee - Andalusia")
    end

    switch_country("Netherlands", heading: "Resident employee - Netherlands")

    within(".calculator-card") do
      expect(page).to have_select(
        "Taxpayer age",
        options: [ "Below AOW age (under 67)", "AOW age or older (67+)" ]
      )
      expect(page).not_to have_select("Input currency")
      expect(page).to have_text("For the supported Netherlands tax years 2024 and 2025, AOW age is 67.")
      expect(page).to have_unchecked_field("Apply 30% ruling")
      check "Apply 30% ruling"
      expect(page).to have_select(
        "30% ruling basis",
        options: [
          "Standard salary threshold",
          "Under 30 with master's degree",
          "Scientific research or doctor specialist training"
        ]
      )
      expect(page).to have_text("2025 thresholds: €46,660 standard or €35,468 if you are under 30 with a master's degree.")
      expect(page).not_to have_select("Region")
      expect(page).not_to have_field("Children")
      expect(page).not_to have_field("Children under 3")
      expect(page).not_to have_field("Taxpayer disability")
    end

    expect(page.evaluate_script("window.__country_switch_marker")).to eq("keep")

    within(".results-card") do
      expect(page).to have_text("30% ruling untaxed allowance")
      expect(page).to have_text("Box 1 tax before credits")
      expect(page).to have_text("General tax credit")
      expect(page).to have_text("Labour tax credit")
    end
  end

  it "recalculates the Netherlands self-employed profile" do
    visit root_path(country: "NL")

    within(".calculator-card") do
      click_button "B2B contract"
      fill_in "Deductible expenses", with: "10000"
      expect(page).not_to have_field("Apply 30% ruling")
      click_button "Recalculate"
    end

    within(".results-card") do
      expect(page).to have_text("Zvw contribution")
      expect(page).to have_text("Self-employed deduction")
      expect(page).to have_text("SME profit exemption")
    end
  end

  it "shows the Spain Beckham Law profile with its own description and breakdown" do
    visit root_path(country: "ES")

    within(".calculator-card") do
      expect(page).to have_unchecked_field("Apply Beckham Law")
      check "Apply Beckham Law"
      select "Madrid", from: "Region"

      expect(page).to have_text("Article 93 special regime for eligible inbound workers.")
      expect(page).not_to have_field("Children")
      expect(page).not_to have_field("Children under 3")
      expect(page).not_to have_field("Taxpayer disability")
    end

    within(".results-card") do
      expect(page).to have_text("Beckham Law income tax")
      expect(page).to have_text("Employee social security")
      expect(page).to have_text("Taxable employment income")
    end
  end

  it "switches to Poland and loads Poland-specific controls and PLN output" do
    visit root_path

    switch_country("Poland", heading: "Contract of employment - Poland")

    within(".calculator-card") do
      expect(page).to have_select("Input currency", options: [ "PLN", "EUR" ])
      expect(page).to have_select(
        "Taxpayer age",
        options: [ "Under 26", "26 to retirement age", "Retirement age or older" ]
      )
      expect(page).to have_unchecked_field("Apply return relief")
      expect(page).to have_unchecked_field("Apply family 4+ relief")
      expect(page).to have_unchecked_field("Apply working senior relief")
      expect(page).not_to have_field("Children under 3")
      expect(page).not_to have_field("Taxpayer disability")

      click_button "B2B contract"

      expect(page).to have_text("B2B contract - Poland")
      expect(page).to have_field("Deductible expenses")
      expect(page).to have_select("Taxation form")
      expect(page).not_to have_field("VAT rate")
    end

    within(".results-card") do
      expect(page).to have_text("PLN")
      expect(page).to have_text("Health contribution")
      expect(page).to have_text("Deductible expenses")
    end
  end

  it "keeps Poland calculator currency inputs stable after recalculation" do
    visit root_path(country: "PL")

    within(".calculator-card") do
      fill_in "Gross income", with: "450000"
      expect(page).to have_field("Gross income", with: "450000")

      select "2025", from: "Tax year"

      expect(page).to have_field("Gross income", with: "450000")
    end
  end

  it "recalculates Poland automatically when gross salary and salary period change" do
    visit root_path(country: "PL")

    within(".results-card") do
      expect(page).to have_text("PLN 120,199.98")
    end

    within(".calculator-card") do
      fill_in "Gross income", with: "7000"
      expect(page).to have_field("Gross income", with: "7000")
      click_button "Monthly"
    end

    within(".results-card") do
      expect(page).to have_text("PLN 61,222.04", wait: 20)
      expect(page).not_to have_text("PLN 120,199.98")
    end
  end

  it "switches to the Czech Republic and loads child and disability credits with CZK output" do
    visit root_path

    switch_country("Czech Republic", heading: "Resident employee - Czech Republic")

    within(".calculator-card") do
      expect(page).to have_select("Input currency", options: [ "CZK", "EUR" ])
      expect(page).to have_field("Children")
      expect(page).to have_select(
        "Taxpayer disability",
        options: [ "None", "Invalidity degree 1 or 2", "Invalidity degree 3", "ZTP/P card holder" ]
      )
      expect(page).not_to have_field("Children under 3")
      expect(page).not_to have_field("Taxpayer age")
    end

    within(".results-card") do
      expect(page).to have_text("CZK")
      expect(page).to have_text("Basic taxpayer credit")
      expect(page).to have_text("Child tax bonus")
    end
  end

  it "defaults Czech self-employed to the 60% flat expense method" do
    visit root_path(country: "CZ")

    within(".calculator-card") do
      click_button "B2B contract"

      expect(page).to have_select("Expense method", selected: "60% flat expenses")
      expect(page).not_to have_field("Deductible expenses")
      expect(page).to have_text("caps flat expenses at CZK 1,200,000 a year")
    end

    within(".results-card") do
      expect(page).to have_text("Deemed tax expenses (60%)")
      expect(page).to have_text("Business profit")
    end
  end

  it "displays Czech calculator result amounts in EUR when EUR input currency is selected" do
    visit root_path(country: "CZ")

    within(".calculator-card") do
      select "EUR", from: "Input currency"
    end

    within(".results-card") do
      expect(page).to have_text("€")
      expect(page).to have_no_text("Kč", wait: 10)
    end
  end

  it "switches to Portugal and loads Portugal-specific deduction controls" do
    visit root_path

    within(".calculator-card") do
      select "Portugal", from: "Country"
      expect(page).to have_select("Country", selected: "Portugal")
      expect(page).not_to have_select("Input currency")
      expect(page).to have_text("Resident employee - Portugal")
      expect(page).to have_field("Children")
      expect(page).to have_select("Children under 3", selected: "0", disabled: true)
      expect(page).to have_select(
        "Taxpayer disability",
        options: [ "None", "60% disability or more" ]
      )
      expect(page).to have_select("Ascendants in household")
      expect(page).to have_field("General family expenses")
      expect(page).to have_field("Health expenses")
      expect(page).to have_field("Education expenses")
      expect(page).to have_field("Eligible housing rent")
      expect(page).to have_field("Court-ordered alimony paid")
      expect(page).to have_field("Care home expenses")
      expect(page).to have_field("Domestic work remuneration")

      click_button "B2B contract"

      expect(page).to have_text("Simplified self-employed - Portugal")
      expect(page).to have_select("Activity type")
      expect(page).to have_field("Deductible expenses")
    end

    within(".results-card") do
      expect(page).to have_text("Documented business expenses")
      expect(page).to have_text("Social security contribution")
      expect(page).to have_text("Portuguese IRS")
    end
  end

  it "switches to Andorra and loads Andorra-specific deduction controls" do
    visit root_path

    within(".calculator-card") do
      select "Andorra", from: "Country"
      expect(page).to have_select("Country", selected: "Andorra")
      expect(page).not_to have_select("Input currency")
      expect(page).to have_text("Resident employee - Andorra")
      expect(page).to have_field("Children")
      expect(page).to have_select(
        "Taxpayer disability",
        options: [ "None", "Recognized disability" ]
      )
      expect(page).to have_select("Dependent ascendants")
      expect(page).to have_select("Disabled dependants")
      expect(page).to have_unchecked_field("Include spouse or stable partner")
      expect(page).to have_unchecked_field("Estimate housing rent support")
      expect(page).not_to have_field("Children under 3")
      expect(page).not_to have_field("Taxpayer age")

      check "Include spouse or stable partner"
      expect(page).to have_unchecked_field("Spouse/partner has no general-base income")
      expect(page).to have_field("Spouse/partner annual general-base income")

      check "Estimate housing rent support"
      expect(page).to have_unchecked_field("Priority-group housing support")
      expect(page).to have_field("Annual housing rent")

      fill_in "Spouse/partner annual general-base income", with: "10980"
      fill_in "Annual housing rent", with: "12000"
      click_button "Recalculate"

      click_button "B2B contract"

      expect(page).to have_text("Standard self-employed - Andorra")
      expect(page).to have_field("Deductible expenses")
      expect(page).to have_select("Self-employed CASS regime")
    end

    within(".results-card") do
      expect(page).to have_text("Spouse phase-in increment", wait: 20)
      expect(page).to have_text("Housing rent support estimate (non-tax)", wait: 20)
    end

    within(".assumptions-card") do
      expect(page).to have_text("outside IRPF and CASS totals", wait: 20)
    end

    within(".results-card") do
      expect(page).to have_text(/Documented business expenses|Deductible expenses/)
      expect(page).to have_text("Earned-income bonus")
      expect(page).to have_text("Andorran IRPF")
      expect(page).to have_text("Total tax")
    end
  end

  it "recalculates Andorra self-employed with the under-35 CASS regime" do
    visit root_path(country: "AD")

    within(".calculator-card") do
      click_button "B2B contract"
      fill_in "Deductible expenses", with: "4000"
      select "Under 35: months 1 to 12", from: "Self-employed CASS regime"
      click_button "Recalculate"
    end

    within(".results-card") do
      expect(page).to have_text("Monthly CASS contribution base", wait: 20)
      expect(page).to have_text("Self-employed CASS contribution", wait: 20)
      expect(page).to have_text("Andorran IRPF", wait: 20)
    end

    within(".assumptions-card") do
      expect(page).to have_text("under-35 special CASS regime is applied for the first 12 months", wait: 20)
    end
  end
end
