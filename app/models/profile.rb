class Profile < ApplicationRecord
  COUNTRY_CODES = Taxerase::CountryCalculators::Registry::DEFINITIONS.keys.freeze
  DEFAULT_COUNTRY_CODE = Taxerase::CountryCalculators::Registry::DEFAULT_COUNTRY_CODE
  DEFAULT_PROFILE_TYPE = "employee"
  PROFILE_TYPE_ALIASES = {
    "employed" => "employee",
    "self-employed" => "self_employed"
  }.freeze
  PROFILE_TYPES = {
    "employee" => "Employed",
    "self_employed" => "Self-employed"
  }.freeze

  belongs_to :user

  before_validation :normalize_country_code
  before_validation :normalize_profile_type

  validates :user_id, uniqueness: true
  validates :country_code, presence: true, inclusion: { in: COUNTRY_CODES }
  validates :profile_type, presence: true, inclusion: { in: PROFILE_TYPES.keys }

  def country_name
    Taxerase::CountryCalculators::Registry.fetch(country_code).country.fetch(:name)
  end

  def profile_type_label
    PROFILE_TYPES.fetch(profile_type)
  end

  def self.normalize_profile_type(value)
    normalized_value = value.to_s.strip.downcase.tr(" ", "_")
    return if normalized_value.blank?

    PROFILE_TYPE_ALIASES.fetch(normalized_value, normalized_value)
  end

  private

  def normalize_country_code
    self.country_code = country_code.to_s.upcase.presence || DEFAULT_COUNTRY_CODE
  end

  def normalize_profile_type
    self.profile_type = self.class.normalize_profile_type(profile_type) || DEFAULT_PROFILE_TYPE
  end
end
