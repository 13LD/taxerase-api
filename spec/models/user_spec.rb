require "rails_helper"

RSpec.describe User, type: :model do
  it "is active immediately after registration while confirmation is disabled" do
    user = described_class.new(
      email: "confirmable@example.com",
      password: "password123"
    )
    user.save!

    expect(user).to be_active_for_authentication
  end

  it "delegates country and type defaults to the profile layer" do
    user = described_class.new(email: "profile-default@example.com")

    expect(user.selected_country_code).to eq(Profile::DEFAULT_COUNTRY_CODE)
    expect(user.profile_type).to eq(Profile::DEFAULT_PROFILE_TYPE)
  end
end
