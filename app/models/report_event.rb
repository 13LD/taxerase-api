class ReportEvent < ApplicationRecord
  EVENT_TYPES = %w[submission payment].freeze

  belongs_to :tax_report

  validates :key, presence: true, uniqueness: { scope: :tax_report_id }
  validates :title, presence: true
  validates :event_date, presence: true
  validates :event_type, inclusion: { in: EVENT_TYPES }
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :submission_window_dates

  scope :ordered, -> { order(:event_date, :position, :title) }

  private

  def submission_window_dates
    return unless event_type == "submission"

    if window_start_date.blank?
      errors.add(:window_start_date, "is required for submission events")
    end

    if window_end_date.blank?
      errors.add(:window_end_date, "is required for submission events")
    end

    return if window_start_date.blank? || window_end_date.blank?

    if window_start_date > window_end_date
      errors.add(:window_start_date, "must be on or before the window end date")
    end

    if event_date.present? && event_date != window_end_date
      errors.add(:event_date, "must match the submission window end date")
    end
  end
end
