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

  def workspace_sidebar_metrics
    page.evaluate_script(<<~JS)
      (() => {
        const sidebar = document.querySelector(".workspace-sidebar");
        const rect = sidebar.getBoundingClientRect();

        return {
          top: rect.top,
          bottom: rect.bottom,
          height: rect.height,
          viewport_height: window.innerHeight
        };
      })()
    JS
  end

  def workspace_sidebar_fit_metrics
    page.evaluate_script(<<~JS)
      (() => {
        const sidebar = document.querySelector(".workspace-sidebar");
        const tabs = document.querySelector(".calculator-tabs");

        return {
          account_top: sidebar.querySelector(".workspace-sidebar__account").getBoundingClientRect().top,
          brand_bottom: sidebar.querySelector(".workspace-sidebar__brand").getBoundingClientRect().bottom,
          sidebar_client_height: sidebar.clientHeight,
          sidebar_scroll_height: sidebar.scrollHeight,
          tabs_client_height: tabs.clientHeight,
          tabs_scroll_height: tabs.scrollHeight,
          tabs_bottom: tabs.getBoundingClientRect().bottom,
          tabs_top: tabs.getBoundingClientRect().top
        };
      })()
    JS
  end

  def page_shell_top
    page.evaluate_script("document.querySelector('.page-shell').getBoundingClientRect().top")
  end

  def current_calendar_month_metrics
    page.evaluate_script(<<~JS)
      (() => {
        const chart = document.querySelector(".report-calendar-chart");
        const currentMonth = document.querySelector(".report-calendar-period--current");
        const sidebar = document.querySelector(".workspace-sidebar");

        if (!chart || !currentMonth || !sidebar) return null;

        const chartRect = chart.getBoundingClientRect();
        const currentMonthRect = currentMonth.getBoundingClientRect();
        const sidebarRect = sidebar.getBoundingClientRect();
        const chartCenter = chartRect.left + (chartRect.width / 2);
        const monthCenter = currentMonthRect.left + (currentMonthRect.width / 2);

        return {
          chart_left: chartRect.left,
          chart_right: chartRect.right,
          chart_width: chartRect.width,
          month_left: currentMonthRect.left,
          month_right: currentMonthRect.right,
          month_width: currentMonthRect.width,
          center_delta: Math.abs(monthCenter - chartCenter),
          sidebar_right: sidebarRect.right
        };
      })()
    JS
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
      expect(page).to have_button("Invoices")
      expect(page).to have_button("Expenses")
      expect(page).to have_button("Reports")
      expect(page).to have_no_text("Country tax estimate.")
      expect(page).to have_no_text("Two-country workspace.")
      expect(page).to have_no_text("Filing dates workspace.")
      expect(page).to have_text("Guest")
      expect(page).to have_text("Limited workspace")
      expect(page).to have_link("Sign in", href: %r{/sign_in\?return_to=})
    end
    fit_metrics = workspace_sidebar_fit_metrics
    expect(fit_metrics.fetch("tabs_scroll_height")).to be <= fit_metrics.fetch("tabs_client_height") + 1
    expect(fit_metrics.fetch("sidebar_scroll_height")).to be <= fit_metrics.fetch("sidebar_client_height") + 1
    expect(fit_metrics.fetch("tabs_top") - fit_metrics.fetch("brand_bottom")).to be <= 28
    expect(fit_metrics.fetch("account_top")).to be > fit_metrics.fetch("tabs_bottom")

    expect(page).to have_css(".calculator-card", visible: true)
    expect(page).to have_no_css(".comparison-card", visible: true)

    open_compare_tab
    expect(page).to have_current_path(/tab=comparison/, url: true)

    open_calculator_tab
    expect(page).to have_current_path(/tab=calculator/, url: true)
  end

  it "uses the signed-in profile row as the edit profile link" do
    user = User.create!(
      email: "sidebar-profile@example.com",
      password: "password123",
      confirmed_at: Time.current
    )
    user.create_profile!(country_code: "NL", profile_type: "employee")

    visit new_user_session_path(return_to: root_path(country: "NL", tab: "calendar"))
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"

    expect(page).to have_current_path(/country=NL&tab=calendar/, url: true)

    within(".workspace-sidebar__account") do
      expect(page).to have_css("a.workspace-sidebar__profile", text: "Edit profile")
      profile_href = find("a.workspace-sidebar__profile")["href"]
      profile_uri = URI.parse(profile_href)
      profile_params = Rack::Utils.parse_nested_query(profile_uri.query)
      expect(profile_uri.path).to eq("/profile/edit")
      expect(profile_params.fetch("return_to")).to eq("/?country=NL&tab=calendar")
      expect(page).to have_css(".workspace-sidebar__avatar", text: "S")
      expect(page).to have_no_css(".workspace-sidebar__account-actions a", text: "Profile")
      expect(page).to have_button("Sign out")
    end
  end

  it "shows profile update notices without shifting the workspace content" do
    user = User.create!(
      email: "profile-notice@example.com",
      password: "password123",
      confirmed_at: Time.current
    )
    user.create_profile!(country_code: "ES", profile_type: "employee")

    visit new_user_session_path(return_to: root_path)
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"

    expect(page).to have_css(".calculator-card", visible: true)
    baseline_top = page_shell_top

    visit edit_profile_path(return_to: root_path)
    select "Portugal", from: "Country"
    select "Self-employed", from: "Type"
    click_button "Save profile"

    expect(page).to have_css(".flash-message--notice", text: "Profile updated.")
    expect(page).to have_css(".calculator-card", visible: true)
    expect(page_shell_top).to be_within(1).of(baseline_top)
  end

  it "uses the signed-in profile country for the calendar tab when no country param is present" do
    user = User.create!(
      email: "calendar-profile@example.com",
      password: "password123",
      confirmed_at: Time.current
    )
    user.create_profile!(country_code: "PT", profile_type: "self_employed")

    visit new_user_session_path(return_to: root_path(tab: "calendar"))
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Sign in"

    expect(page).to have_current_path(/tab=calendar/, url: true)
    expect(page).to have_css(".report-calendar-card .section-kicker", text: "PORTUGAL", wait: 20)
    expect(page).to have_text("Tax calendar")
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
      click_button "Invoices"
    end

    expect(page).to have_current_path(/tab=invoice/, url: true)
    expect(page).to have_css("#invoice-panel", visible: true)
    expect(page).to have_css("#invoice-panel .section-kicker", text: "INVOICES")
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

  it "keeps the workspace sidebar fixed and inside the viewport while desktop content scrolls" do
    page.driver.browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width: 1280,
      height: 720,
      deviceScaleFactor: 1,
      mobile: false
    )
    visit root_path(tab: "calendar")

    expect(page).to have_text("Modelo 130", wait: 20)
    main_top = page.evaluate_script(
      "document.querySelector('.report-calendar-card').getBoundingClientRect().top"
    )

    page.execute_script("window.scrollTo(0, 900)")
    expect(page.evaluate_script("window.scrollY")).to be > 0

    metrics = workspace_sidebar_metrics
    bottom_inset = metrics.fetch("viewport_height") - metrics.fetch("bottom")

    expect(metrics.fetch("top")).to be_within(2).of(main_top)
    expect(bottom_inset).to be_within(2).of(main_top)
    expect(metrics.fetch("bottom")).to be <= metrics.fetch("viewport_height") + 1
    expect(metrics.fetch("height")).to be <= metrics.fetch("viewport_height")
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
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
      expect(page).to have_no_css(".workspace-sidebar__brand-mark", visible: true)
      toggle = find(".workspace-sidebar__toggle", visible: true)
      expect(toggle["aria-label"]).to eq("Toggle workspace navigation")
      expect(toggle["aria-expanded"]).to eq("false")
      expect(page).to have_no_button("Reports", visible: true)

      toggle_top = page.evaluate_script(
        "document.querySelector('.workspace-sidebar__toggle').getBoundingClientRect().top"
      )
      section_kicker_top = page.evaluate_script(
        "document.querySelector('.workspace-main .section-kicker').getBoundingClientRect().top"
      )
      collapsed_sidebar_left = page.evaluate_script(
        "document.querySelector('.workspace-sidebar').getBoundingClientRect().left"
      )
      collapsed_sidebar_width = page.evaluate_script(
        "document.querySelector('.workspace-sidebar').getBoundingClientRect().width"
      )
      main_left = page.evaluate_script(
        "document.querySelector('.workspace-main').getBoundingClientRect().left"
      )
      expect(toggle_top).to be_within(2).of(section_kicker_top)
      expect(collapsed_sidebar_left).to be < main_left
      collapsed_metrics = workspace_sidebar_metrics
      expect(collapsed_metrics.fetch("bottom")).to be <= collapsed_metrics.fetch("viewport_height") + 1
      expect(collapsed_metrics.fetch("height")).to be <= collapsed_metrics.fetch("viewport_height")

      page.execute_script("window.scrollTo(0, document.documentElement.scrollHeight)")
      scrolled_metrics = workspace_sidebar_metrics
      expect(scrolled_metrics.fetch("top")).to be_within(1).of(collapsed_metrics.fetch("top"))
      expect(scrolled_metrics.fetch("bottom")).to be <= scrolled_metrics.fetch("viewport_height") + 1

      toggle.click
      expect(toggle["aria-expanded"]).to eq("true")
      expect(page).to have_text("Taxerase")
      expect(page).to have_button("Reports", visible: true)
      expect(page).to have_no_text("Tax report workspace.")
      expect(page).to have_no_css(".workspace-main", visible: true)
      expanded_sidebar_left = page.evaluate_script(
        "document.querySelector('.workspace-sidebar').getBoundingClientRect().left"
      )
      expanded_sidebar_width = page.evaluate_script(
        "document.querySelector('.workspace-sidebar').getBoundingClientRect().width"
      )
      expect(expanded_sidebar_left).to be_within(1).of(collapsed_sidebar_left)
      expect(expanded_sidebar_width).to be > collapsed_sidebar_width
      expanded_metrics = workspace_sidebar_metrics
      expect(expanded_metrics.fetch("bottom")).to be <= expanded_metrics.fetch("viewport_height") + 1
      expect(expanded_metrics.fetch("height")).to be <= expanded_metrics.fetch("viewport_height")
      expanded_fit_metrics = workspace_sidebar_fit_metrics
      expect(expanded_fit_metrics.fetch("tabs_scroll_height")).to be <= expanded_fit_metrics.fetch("tabs_client_height") + 1
      expect(expanded_fit_metrics.fetch("sidebar_scroll_height")).to be <= expanded_fit_metrics.fetch("sidebar_client_height") + 1
      expect(expanded_fit_metrics.fetch("tabs_top") - expanded_fit_metrics.fetch("brand_bottom")).to be <= 28
      expect(expanded_fit_metrics.fetch("account_top")).to be > expanded_fit_metrics.fetch("tabs_bottom")

      click_button "Reports"
      expect(page).to have_no_button("Reports", visible: true)
    end

    expect(page).to have_current_path(/tab=reports/, url: true)
    expect(page).to have_css(".workspace-main", visible: true)
    expect(page).to have_css("#reports-panel", visible: true)
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  it "keeps the mobile sidebar toggle aligned with the calendar screen" do
    page.driver.browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width: 430,
      height: 932,
      deviceScaleFactor: 1,
      mobile: true
    )
    visit root_path(tab: "calendar")

    expect(page.evaluate_script("window.innerWidth")).to be <= 720
    expect(page).to have_css(".report-calendar-card .section-kicker", wait: 20)

    toggle_top = page.evaluate_script(
      "document.querySelector('.workspace-sidebar__toggle').getBoundingClientRect().top"
    )
    section_kicker_top = page.evaluate_script(
      "document.querySelector('.report-calendar-card .section-kicker').getBoundingClientRect().top"
    )
    initial_metrics = workspace_sidebar_metrics

    expect(toggle_top).to be_within(2).of(section_kicker_top)
    expect(initial_metrics.fetch("bottom")).to be <= initial_metrics.fetch("viewport_height") + 1

    page.execute_script("window.scrollTo(0, document.documentElement.scrollHeight)")
    scrolled_metrics = workspace_sidebar_metrics
    expect(scrolled_metrics.fetch("top")).to be_within(1).of(initial_metrics.fetch("top"))
    expect(scrolled_metrics.fetch("bottom")).to be <= scrolled_metrics.fetch("viewport_height") + 1
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  it "keeps the current calendar month inside the mobile content lane" do
    freeze_browser_date("2026-04-25T12:00:00Z")
    page.driver.browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width: 390,
      height: 844,
      deviceScaleFactor: 1,
      mobile: true
    )
    visit root_path(tab: "calendar")

    expect(page).to have_text("Modelo 130", wait: 20)
    wait_for_calendar_current_month_position
    metrics = current_calendar_month_metrics

    expect(metrics.fetch("chart_left")).to be > metrics.fetch("sidebar_right")
    expect(metrics.fetch("month_left")).to be >= metrics.fetch("chart_left") - 1
    expect(metrics.fetch("month_right")).to be <= metrics.fetch("chart_right") + 1
    expect(metrics.fetch("month_width")).to be_within(3).of(metrics.fetch("chart_width"))
    expect(metrics.fetch("center_delta")).to be <= 1
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
