require "securerandom"

module RequestAuthHelpers
  def sign_in_api_user(country_code: "ES", profile_type: "employee")
    user = User.create!(
      email: "request-user-#{SecureRandom.hex(6)}@example.com",
      password: "password123",
      confirmed_at: Time.current
    )
    user.create_profile!(country_code:, profile_type:)

    sign_in user
    user
  end
end

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include RequestAuthHelpers, type: :request

  config.before(:each, type: :request) do |example|
    next if example.metadata[:guest]

    file_path = example.metadata[:file_path].to_s
    next unless file_path.include?("spec/requests/api/v1/") &&
      file_path.end_with?("salary_calculations_spec.rb")

    sign_in_api_user
  end
end
