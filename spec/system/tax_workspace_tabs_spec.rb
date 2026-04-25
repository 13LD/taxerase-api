require "rails_helper"
require "timeout"

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

  def freeze_browser_date(value)
    page.driver.browser.execute_cdp(
      "Page.addScriptToEvaluateOnNewDocument",
      source: <<~JS
        (() => {
          const fixedTimestamp = new Date("#{value}").getTime();
          const RealDate = Date;

          function FixedDate(...args) {
            if (this instanceof FixedDate) {
              return args.length === 0 ? new RealDate(fixedTimestamp) : new RealDate(...args);
            }

            return new RealDate(fixedTimestamp).toString();
          }

          FixedDate.now = () => fixedTimestamp;
          FixedDate.parse = RealDate.parse;
          FixedDate.UTC = RealDate.UTC;
          FixedDate.prototype = RealDate.prototype;
          window.Date = FixedDate;
        })();
      JS
    )
  end

  def workflow_card_height(report_name, tax_year)
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll(".report-calendar-workflow"))
        .find((element) => (
          element.querySelector(".report-calendar-workflow__summary strong")?.textContent === "#{report_name}" &&
          element.textContent.includes("#{tax_year}")
        ))
        .getBoundingClientRect().height
    JS
  end

  def workflow_card(report_name, tax_year)
    all(".report-calendar-workflow").find do |card|
      card.find(".report-calendar-workflow__summary strong").text == report_name &&
        card.text.include?(tax_year.to_s)
    end
  end

  def calendar_scrolled_to_current_month?
    page.evaluate_script(<<~JS)
      (() => {
        const chart = document.querySelector(".report-calendar-chart");
        const currentMonth = document.querySelector(".report-calendar-period--current");
        const today = new Date();
        const expectedMonthKey = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}`;

        return Boolean(
          chart &&
          currentMonth &&
          currentMonth.dataset.monthKey === expectedMonthKey &&
          chart.scrollLeft > 0
        );
      })()
    JS
  end

  def wait_for_calendar_current_month_position
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.05 until calendar_scrolled_to_current_month?
    end
  end

  def modelo_130_reference_url
    "https://sede.agenciatributaria.gob.es/Sede/procedimientoini/G601.shtml"
  end

  def btw_deadline_reference_url
    "https://www.belastingdienst.nl/wps/wcm/connect/nl/btw/content/uiterste-aangifte-en-betaaldatums"
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
    freeze_browser_date("2026-04-25T12:00:00Z")

    visit root_path

    within(".calculator-tabs") do
      click_button "Calendar"
    end

    expect(page).to have_current_path(/tab=calendar/, url: true)
    expect(page).to have_css("#calendar-panel", visible: true)
    expect(page).to have_text("Modelo 130", wait: 20)
    expect(page).to have_text("Modelo 100")
    expect(page).to have_css(".report-calendar-period", count: 37)
    expect(page).to have_css('[data-month-key="2025-01"]')
    expect(page).to have_css('[data-month-key="2027-12"]')
    expect(page).to have_css('[data-month-key="2028-01"]')
    expect(page).to have_no_css('[data-month-key="2028-02"]')
    wait_for_calendar_current_month_position
    expect(page).to have_css(".report-calendar-period__head", text: "Apr")
    expect(page).to have_css(".report-calendar-period__head", text: "Nov")
    expect(page).to have_css(".report-calendar-period__head", text: "Jan")
    expect(page).to have_css(".report-calendar-period__head", text: "2025")
    expect(page).to have_css(".report-calendar-period__head", text: "2027")
    expect(page).to have_css(".report-calendar-period__head", text: "2028")
    expect(page).to have_text("Apr 1 - Apr 20, 2025")
    expect(page).to have_text("Apr 8 - Jun 30, 2026")
    expect(page).to have_text("Nov 5, 2026")
    expect(page).to have_text("Apr 1 - Apr 20, 2026")
    expect(page).to have_text("Apr 1 - Apr 20, 2027")
    expect(page).to have_text("Jan 1 - Jan 30, 2027")
    expect(page).to have_text("Jan 1 - Jan 30, 2028")
    expect(page).to have_text("Report submission", count: 1)
    expect(page).to have_text("Tax payment", count: 1)
    expect(find(".report-calendar-chart__item", text: "Modelo 130", match: :first)["title"]).to include(
      "Submission window runs from 1 to 20 April"
    )
    expect(page).to have_css(".report-calendar-workflow", count: 5)
    within(".report-calendar-workflows") do
      expect(all(".report-calendar-workflow .mini-label").map(&:text)).to eq(Array.new(5, "2026"))
    end
    expect(page).to have_css(".report-calendar-workflow", text: "Modelo 130")
    expect(page).to have_no_text("Collect quarterly revenue")
    modelo_130_workflow = workflow_card("Modelo 130", 2026)
    modelo_303_height_before = workflow_card_height("Modelo 303", 2026)

    modelo_130_workflow.find(".report-calendar-workflow__summary").click

    expect(page).to have_text("Prepare quarterly IRPF inputs")
    expect(page).to have_text("Collect quarterly revenue")
    modelo_303_height_after = workflow_card_height("Modelo 303", 2026)
    expect(modelo_303_height_after).to be_within(1).of(modelo_303_height_before)

    within(modelo_130_workflow) do
      expect(page).to have_link(
        "Official tax agency reference",
        href: modelo_130_reference_url
      )
    end

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

  it "shows the Netherlands tax calendar with workflow cards and spillover deadlines" do
    freeze_browser_date("2026-04-25T12:00:00Z")

    visit root_path(country: "NL")

    within(".calculator-tabs") do
      click_button "Calendar"
    end

    expect(page).to have_current_path(/tab=calendar/, url: true)
    expect(page).to have_css("#calendar-panel", visible: true)
    expect(page).to have_text("NETHERLANDS", wait: 20)
    expect(page).to have_text("BTW aangifte")
    expect(page).to have_text("Annual BTW aangifte")
    expect(page).to have_text("Opgaaf ICP")
    expect(page).to have_text("OSS BTW melding")
    expect(page).to have_text("Inkomstenbelasting")
    expect(page).to have_css(".report-calendar-period", count: 38)
    expect(page).to have_css('[data-month-key="2025-01"]')
    expect(page).to have_css('[data-month-key="2027-12"]')
    expect(page).to have_css('[data-month-key="2028-01"]')
    expect(page).to have_css('[data-month-key="2028-03"]')
    expect(page).to have_no_css('[data-month-key="2028-02"]')
    expect(page).to have_no_css('[data-month-key="2028-04"]')
    wait_for_calendar_current_month_position
    expect(page).to have_text("Apr 1 - Apr 30, 2026")
    expect(page).to have_text("Jan 1 - Jan 31, 2028")
    expect(page).to have_text("Jan 1 - Feb 28, 2028")
    expect(page).to have_text("Mar 1 - May 1, 2028")
    expect(page).to have_text("Report submission", count: 1)
    expect(page).to have_text("Tax payment", count: 1)
    expect(find(".report-calendar-chart__item", text: "BTW aangifte", match: :first)["title"]).to include(
      "Quarterly BTW return for Q1"
    )
    expect(page).to have_css(".report-calendar-workflow", count: 5)
    within(".report-calendar-workflows") do
      expect(all(".report-calendar-workflow .mini-label").map(&:text)).to eq(Array.new(5, "2026"))
    end
    expect(page).to have_no_text("Reconcile output BTW")

    btw_workflow = workflow_card("BTW aangifte", 2026)
    annual_btw_height_before = workflow_card_height("Annual BTW aangifte", 2026)
    btw_workflow.find(".report-calendar-workflow__summary").click

    expect(page).to have_text("Reconcile quarterly BTW")
    expect(page).to have_text("Reconcile output BTW")
    annual_btw_height_after = workflow_card_height("Annual BTW aangifte", 2026)
    expect(annual_btw_height_after).to be_within(1).of(annual_btw_height_before)

    within(btw_workflow) do
      expect(page).to have_link(
        "Official tax agency reference",
        href: btw_deadline_reference_url
      )
    end
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
