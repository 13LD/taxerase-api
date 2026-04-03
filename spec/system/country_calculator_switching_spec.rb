require "rails_helper"

RSpec.describe "Country calculator switching", type: :system, js: true do
  it "switches from Spain to Netherlands and loads country-specific fields" do
    visit root_path
    page.execute_script("window.__country_switch_marker = 'keep'")

    within(".calculator-card") do
      expect(page).to have_select("Country", selected: "Spain")
      expect(page).to have_text("Resident employee - Andalusia")
      select "Netherlands", from: "Country"
    end

    within(".calculator-card") do
      expect(page).to have_text("Resident employee - Netherlands")
      expect(page).to have_select("Country", selected: "Netherlands")
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
      click_button "Self-employed"
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

    within(".calculator-card") do
      select "Poland", from: "Country"
      expect(page).to have_select("Country", selected: "Poland")
      expect(page).to have_select("Input currency", options: [ "PLN", "EUR" ])
      expect(page).to have_text("Contract of employment - Poland")
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
      fill_in "Gross salary", with: "450000"
      expect(page).to have_field("Gross salary", with: "450000")

      select "2025", from: "Tax year"

      expect(page).to have_field("Gross salary", with: "450000")
    end
  end

  it "switches to the Czech Republic and loads child and disability credits with CZK output" do
    visit root_path

    within(".calculator-card") do
      select "Czech Republic", from: "Country"
      expect(page).to have_select("Country", selected: "Czech Republic")
      expect(page).to have_select("Input currency", options: [ "CZK", "EUR" ])
      expect(page).to have_text("Resident employee - Czech Republic")
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
      click_button "Self-employed"

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

      click_button "Simplified self-employed"

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
      expect(page).not_to have_field("Children under 3")
      expect(page).not_to have_field("Taxpayer age")

      click_button "Self-employed activity"

      expect(page).to have_text("Standard self-employed - Andorra")
      expect(page).to have_field("Deductible expenses")
    end

    within(".results-card") do
      expect(page).to have_text(/Documented business expenses|Deductible expenses/)
      expect(page).to have_text("Earned-income bonus")
      expect(page).to have_text("Andorran IRPF")
      expect(page).to have_text("Total tax")
    end
  end
end
