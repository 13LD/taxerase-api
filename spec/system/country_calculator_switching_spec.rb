require "rails_helper"

RSpec.describe "Country calculator switching", type: :system, js: true do
  it "switches from Spain to Netherlands and loads country-specific fields" do
    visit root_path

    within(".calculator-card") do
      expect(page).to have_select("Country", selected: "Spain")
      expect(page).to have_text("Resident employee - Andalusia")
      select "Netherlands", from: "Country"
    end

    within(".calculator-card") do
      expect(page).to have_select("Country", selected: "Netherlands")
      expect(page).to have_text("Resident employee - Netherlands")
      expect(page).to have_select(
        "Taxpayer age",
        options: [ "Below AOW age (under 67)", "AOW age or older (67+)" ]
      )
      expect(page).to have_text("For the supported Netherlands tax years 2024 and 2025, AOW age is 67.")
      expect(page).not_to have_select("Region")
      expect(page).not_to have_field("Children")
      expect(page).not_to have_field("Children under 3")
      expect(page).not_to have_field("Taxpayer disability")
    end

    within(".results-card") do
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
      click_button "Recalculate"
    end

    within(".results-card") do
      expect(page).to have_text("Zvw contribution")
      expect(page).to have_text("Self-employed deduction")
      expect(page).to have_text("SME profit exemption")
    end
  end
end
