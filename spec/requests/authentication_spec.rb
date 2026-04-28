require "rails_helper"

RSpec.describe "Authentication", type: :request do
  before do
    ActionMailer::Base.deliveries.clear
  end

  it "registers a user without profile settings and sends them to profile editing" do
    expect do
      post user_registration_path, params: {
        user: {
          email: "new-user@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end.to change(User, :count).by(1)

    user = User.find_by!(email: "new-user@example.com")

    expect(response).to redirect_to(edit_profile_path(return_to: root_path))
    expect(ActionMailer::Base.deliveries).to be_empty
    expect(user).not_to have_attribute(:selected_country_code)
    expect(user.profile).to be_nil
    expect(user).to be_active_for_authentication
  end

  it "redirects back to the originating calculator URL after sign in" do
    user = User.create!(
      email: "confirmed@example.com",
      password: "password123",
      confirmed_at: Time.current
    )
    user.create_profile!(country_code: "NL", profile_type: "employee")

    get new_user_session_path(return_to: "/?country=PT&tab=calendar")
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    expect(response).to redirect_to("/?country=PT&tab=calendar")
  end

  it "preserves stale auth return paths when return_to is absent" do
    user = User.create!(
      email: "stale-return-absent@example.com",
      password: "password123",
      confirmed_at: Time.current
    )
    user.create_profile!(country_code: "CZ", profile_type: "employee")

    get new_user_session_path(return_to: "/?country=PT&tab=calendar")
    get new_user_session_path
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    expect(response).to redirect_to("/?country=PT&tab=calendar")
  end

  [
    [ "blank", { return_to: "" } ],
    [ "unsafe", { return_to: "https://example.net/phish" } ]
  ].each_with_index do |(case_name, params), index|
    it "clears stale auth return paths when the current return_to is #{case_name}" do
      user = User.create!(
        email: "stale-return-#{index}@example.com",
        password: "password123",
        confirmed_at: Time.current
      )
      user.create_profile!(country_code: "CZ", profile_type: "employee")

      get new_user_session_path(return_to: "/?country=PT&tab=calendar")
      get new_user_session_path(params)
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }

      expect(response).to redirect_to(root_path)
    end
  end

  it "does not store external return URLs" do
    user = User.create!(
      email: "safe-redirect@example.com",
      password: "password123",
      confirmed_at: Time.current
    )
    user.create_profile!(country_code: "CZ", profile_type: "employee")

    get new_user_session_path(return_to: "https://example.net/phish")
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    expect(response).to redirect_to(root_path)
  end

  [
    [ "backslash-prefixed", "/\\evil.com" ],
    [ "encoded-backslash-prefixed", "/%5C%5Cevil.com" ],
    [ "encoded-network-path", "/%2F%2Fevil.com" ],
    [ "encoded-control-character", "/%0A/dashboard" ]
  ].each_with_index do |(case_name, return_to), index|
    it "does not store #{case_name} return paths" do
      user = User.create!(
        email: "safe-redirect-#{index}@example.com",
        password: "password123",
        confirmed_at: Time.current
      )
      user.create_profile!(country_code: "CZ", profile_type: "employee")

      get new_user_session_path(return_to: return_to)
      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }

      expect(response).to redirect_to(root_path)
    end
  end

  it "sends first-time signed-in users without a profile to profile editing" do
    user = User.create!(
      email: "needs-profile@example.com",
      password: "password123",
      confirmed_at: Time.current
    )

    get new_user_session_path(return_to: "/?country=PT&tab=calendar")
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    expect(response).to redirect_to(edit_profile_path(return_to: "/?country=PT&tab=calendar"))
  end

  it "creates a profile with country and type from the profile edit page" do
    user = User.create!(
      email: "profile-editor@example.com",
      password: "password123",
      confirmed_at: Time.current
    )

    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    expect do
      patch profile_path, params: {
        return_to: "/?country=NL&tab=calculator",
        profile: {
          country_code: "pt",
          profile_type: "self_employed"
        }
      }
    end.to change(Profile, :count).by(1)

    expect(response).to redirect_to("/?country=NL&tab=calculator")
    expect(user.reload.profile).to have_attributes(
      country_code: "PT",
      profile_type: "self_employed"
    )
  end
end
