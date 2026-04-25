require "uri"

class ReportWorkflow < ApplicationRecord
  belongs_to :tax_report

  validates :key, presence: true, uniqueness: { scope: :tax_report_id }
  validates :name, presence: true
  validates :description, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :reference_url_must_be_http_url

  scope :ordered, -> { order(:position, :name) }

  private

  def reference_url_must_be_http_url
    return if reference_url.blank?

    uri = URI.parse(reference_url)
    return if uri.is_a?(URI::HTTP) && uri.host.present? && uri.to_s == reference_url

    errors.add(:reference_url, "must be a valid HTTP or HTTPS URL")
  rescue URI::InvalidURIError
    errors.add(:reference_url, "must be a valid HTTP or HTTPS URL")
  end
end
