require "selenium/webdriver"

Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 5

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  chrome_binary = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

  options.binary = chrome_binary if File.exist?(chrome_binary)
  options.add_argument("--headless=new")
  options.add_argument("--disable-gpu")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=1440,1800")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :headless_chrome
  end
end
