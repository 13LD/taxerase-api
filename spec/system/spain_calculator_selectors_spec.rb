require "rails_helper"

RSpec.describe "Spain calculator selectors", type: :system, js: true do
  def expect_metric_card(label, value)
    card = find(".metric-card", text: label, match: :first)

    expect(card).to have_css(".metric-value", text: value)
  end

  it "keeps a tax breakdown visible when switching to the self-employed profile" do
    visit root_path

    within(".results-card") do
      expect(page).to have_text("Annual net income")
      expect(page).to have_text("Monthly net income")
      expect(page).to have_text("Effective tax rate")
      expect(page).to have_text("Employee social security")
    end

    expect_metric_card("Annual net income", /€\d[\d,]*\.\d{2}/)
    expect_metric_card("Monthly net income", /€\d[\d,]*\.\d{2}/)
    expect_metric_card("Effective tax rate", /\d+\.\d{2}%/)

    click_button "Self-employed"

    expect(page).to have_field("Revenue before expenses", with: "60000")
    expect(page).to have_field("Deductible expenses", with: "0")

    within(".results-card") do
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

    fill_in "Deductible expenses", with: "10000"
    click_button "Recalculate"

    within(".results-card") do
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

    select "Madrid", from: "Region"

    expect(page).to have_text("Resident employee - Madrid")

    within(".results-card") do
      expect(page).to have_text("Income tax")
      expect(page).to have_text("Employee social security")
      expect(page).to have_text("Madrid minimum relief")
      expect(page).not_to have_text("Awaiting recalculate")
    end

    expect_metric_card("Annual net income", /€\d[\d,]*\.\d{2}/)
    expect_metric_card("Monthly net income", /€\d[\d,]*\.\d{2}/)
    expect_metric_card("Effective tax rate", /\d+\.\d{2}%/)
  end

  it "shows research-pending tax breakdown values for unsupported year and region selections" do
    visit root_path

    select "2024", from: "Tax year"
    select "Navarre", from: "Region"

    within(".results-card") do
      expect(page).to have_text("Annual net income")
      expect(page).to have_text("Monthly net income")
      expect(page).to have_text("Effective tax rate")
      expect(page).to have_text("Research pending")
      expect(page).to have_text("Income tax")
      expect(page).to have_text("Employee social security")
      expect(page).not_to have_text("Coverage status")
      expect(page).not_to have_text("Official sources")
      expect(page).not_to have_text("Regime key")
      expect(page).not_to have_text("Calculation flow")
    end

    expect(page).to have_button("Recalculate", disabled: true)
  end
end
