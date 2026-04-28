require "securerandom"
require "warden/test/helpers"

module SystemAuthHelpers
  def sign_in_calculator_user(country_code: "ES", profile_type: "employee")
    user = User.create!(
      email: "system-user-#{SecureRandom.hex(6)}@example.com",
      password: "password123",
      confirmed_at: Time.current
    )
    user.create_profile!(country_code:, profile_type:)

    login_as(user, scope: :user)
    user
  end
end

RSpec.configure do |config|
  config.include Warden::Test::Helpers, type: :system
  config.include SystemAuthHelpers, type: :system

  config.after(:each, type: :system) do
    Warden.test_reset!
  end
end
