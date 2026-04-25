require "rails_helper"

RSpec.describe "Tax workspace tabs", type: :system, js: true do
  def open_compare_tab
    within(".calculator-tabs") do
      click_button "Comparison"
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

    within(".workspace-sidebar") do
      expect(page).to have_text("Taxerase")
      expect(page).to have_button("Calculator")
      expect(page).to have_button("Comparison")
      expect(page).to have_button("Calendar")
      expect(page).to have_button("Invoice")
      expect(page).to have_button("Expenses")
      expect(page).to have_button("Reports")
      expect(page).to have_text("User profile")
    end

    expect(page).to have_css(".calculator-card", visible: true)
    expect(page).to have_no_css(".comparison-card", visible: true)

    open_compare_tab
    expect(page).to have_current_path(/tab=comparison/, url: true)

    open_calculator_tab
    expect(page).to have_current_path(/tab=calculator/, url: true)
  end

  it "shows the report calendar and placeholder invoice, expenses, and reports workspaces from the sidebar" do
    visit root_path

    within(".calculator-tabs") do
      click_button "Calendar"
    end

    expect(page).to have_current_path(/tab=calendar/, url: true)
    expect(page).to have_css("#calendar-panel", visible: true)
    expect(page).to have_text("Modelo 130", wait: 20)
    expect(page).to have_text("Modelo 100")
    expect(page).to have_css(".report-calendar-period", count: 13)
    expect(page).to have_css(".report-calendar-period__head", text: "Apr")
    expect(page).to have_css(".report-calendar-period__head", text: "Nov")
    expect(page).to have_css(".report-calendar-period__head", text: "Jan")
    expect(page).to have_no_css(".report-calendar-period__head", text: "2025")
    expect(page).to have_text("Apr 8 - Jun 30, 2026")
    expect(page).to have_text("Nov 5, 2026")
    expect(page).to have_text("Apr 1 - Apr 20, 2026")
    expect(page).to have_text("Jan 1 - Jan 30, 2027")
    expect(page).to have_text("Report submission", count: 1)
    expect(page).to have_text("Tax payment", count: 1)
    expect(find(".report-calendar-chart__item", text: "Modelo 130", match: :first)["title"]).to include(
      "Submission window runs from 1 to 20 April"
    )

    within(".calculator-tabs") do
      click_button "Invoice"
    end

    expect(page).to have_current_path(/tab=invoice/, url: true)
    expect(page).to have_css("#invoice-panel", visible: true)
    expect(page).to have_text("Invoice workflows will live here.")

    within(".calculator-tabs") do
      click_button "Expenses"
    end

    expect(page).to have_current_path(/tab=expenses/, url: true)
    expect(page).to have_css("#expenses-panel", visible: true)
    expect(page).to have_text("Expense workflows will live here.")

    within(".calculator-tabs") do
      click_button "Reports"
    end

    expect(page).to have_current_path(/tab=reports/, url: true)
    expect(page).to have_css("#reports-panel", visible: true)
    expect(page).to have_text("Tax report workflows will live here.")
  end

  it "collapses and expands the sidebar navigation on mobile" do
    page.driver.browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width: 390,
      height: 844,
      deviceScaleFactor: 1,
      mobile: true
    )
    visit root_path

    expect(page.evaluate_script("window.innerWidth")).to be <= 720

    within(".workspace-sidebar") do
      expect(page).to have_text("Taxerase")
      toggle = find(".workspace-sidebar__toggle", visible: true)
      expect(toggle["aria-label"]).to eq("Toggle workspace navigation")
      expect(toggle["aria-expanded"]).to eq("false")
      expect(page).to have_no_button("Reports", visible: true)

      toggle.click
      expect(toggle["aria-expanded"]).to eq("true")
      expect(page).to have_button("Reports", visible: true)

      click_button "Reports"
      expect(page).to have_no_button("Reports", visible: true)
    end

    expect(page).to have_current_path(/tab=reports/, url: true)
    expect(page).to have_css("#reports-panel", visible: true)
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  it "maps the old invoice expenses tab query param to invoice" do
    visit root_path(tab: "invoice_expenses")

    expect(page).to have_css("#invoice-panel", visible: true)
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
