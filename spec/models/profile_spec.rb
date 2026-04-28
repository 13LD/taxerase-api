require "rails_helper"

RSpec.describe Profile, type: :model do
  it "normalizes country codes before validation" do
    profile = described_class.new(
      user: User.new(email: "profile@example.com", password: "password123"),
      country_code: "pt",
      profile_type: "self_employed"
    )

    expect(profile).to be_valid
    expect(profile.country_code).to eq("PT")
  end

  it "rejects unsupported country codes" do
    profile = described_class.new(
      user: User.new(email: "unsupported@example.com", password: "password123"),
      country_code: "XX",
      profile_type: "employee"
    )

    expect(profile).not_to be_valid
    expect(profile.errors[:country_code]).to include("is not included in the list")
  end

  it "normalizes legacy employed profile type values" do
    profile = described_class.new(
      user: User.new(email: "legacy-profile@example.com", password: "password123"),
      country_code: "ES",
      profile_type: "employed"
    )

    expect(profile).to be_valid
    expect(profile.profile_type).to eq("employee")
  end

  it "rejects unsupported profile types" do
    profile = described_class.new(
      user: User.new(email: "type@example.com", password: "password123"),
      country_code: "ES",
      profile_type: "contractor"
    )

    expect(profile).not_to be_valid
    expect(profile.errors[:profile_type]).to include("is not included in the list")
  end
end
