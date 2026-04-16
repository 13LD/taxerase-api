require "rails_helper"

RSpec.describe "Tax workspace tabs", type: :system, js: true do
  def open_compare_tab
    within(".calculator-tabs") do
      click_button "Compare 2 countries or regions"
    end

    expect(page).to have_css(".comparison-card", visible: true)
  end

  def open_calculator_tab
    within(".calculator-tabs") do
      click_button "Calculator"
    end

    expect(page).to have_css(".calculator-card", visible: true)
  end

  it "defaults to the calculator tab and syncs the tab query param" do
    visit root_path

    expect(page).to have_css(".calculator-card", visible: true)
    expect(page).to have_no_css(".comparison-card", visible: true)

    open_compare_tab
    expect(page).to have_current_path(/tab=comparison/, url: true)

    open_calculator_tab
    expect(page).to have_current_path(/tab=calculator/, url: true)
  end

  it "respects the comparison tab query param on first load" do
    visit root_path(tab: "comparison")

    expect(page).to have_css(".comparison-card", visible: true)
    expect(page).to have_no_css(".calculator-card", visible: true)
  end

  it "does not request comparison data while opening in calculator mode" do
    page.driver.browser.execute_cdp(
      "Page.addScriptToEvaluateOnNewDocument",
      source: <<~JS
        window.__codexFetchCalls = [];
        const originalFetch = window.fetch.bind(window);
        window.fetch = (...args) => {
          window.__codexFetchCalls.push(String(args[0]));
          return originalFetch(...args);
        };
      JS
    )

    visit root_path

    expect(page).to have_css(".calculator-card", visible: true)
    expect(page.evaluate_script("window.__codexFetchCalls")).to be_empty
  end

  it "preserves calculator and comparison state when switching tabs" do
    visit root_path

    within(".calculator-card") do
      fill_in "Gross income", with: "65000"
    end

    open_compare_tab

    within(".comparison-card") do
      fill_in "Annual income", with: "72000"
    end

    comparison_sides = all(".comparison-side")

    within(comparison_sides[1]) do
      select "Poland", from: "Country"
    end

    open_calculator_tab

    within(".calculator-card") do
      expect(page).to have_field("Gross income", with: "65000")
    end

    open_compare_tab

    within(".comparison-card") do
      expect(page).to have_field("Annual income", with: "72000")
    end

    comparison_sides = all(".comparison-side")

    within(comparison_sides[1]) do
      expect(page).to have_select("Country", selected: "Poland")
    end
  end

  it "does not trigger extra network requests when switching tabs" do
    visit root_path(tab: "comparison")

    within(".comparison-card") do
      expect(page).to have_no_text("Refreshing comparison...", wait: 20)
      expect(page).to have_css(".comparison-table__row", text: "Annual net income", wait: 20)
    end

    page.execute_script(<<~JS)
      window.__codexFetchCalls = [];
      const originalFetch = window.fetch.bind(window);
      window.fetch = (...args) => {
        window.__codexFetchCalls.push(String(args[0]));
        return originalFetch(...args);
      };
    JS

    open_calculator_tab
    open_compare_tab

    expect(page.evaluate_script("window.__codexFetchCalls.length")).to eq(0)
  end
end
