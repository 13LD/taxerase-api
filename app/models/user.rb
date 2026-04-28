class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :profile, dependent: :destroy

  def selected_country_code
    profile&.country_code || Profile::DEFAULT_COUNTRY_CODE
  end

  def selected_country_name
    Country.find_by(code: selected_country_code)&.name
  end

  def profile_type
    Profile.normalize_profile_type(profile&.profile_type) || Profile::DEFAULT_PROFILE_TYPE
  end

  def profile_type_label
    Profile::PROFILE_TYPES.fetch(profile_type)
  end
end
