class ReportWorkflow < ApplicationRecord
  belongs_to :tax_report

  validates :key, presence: true, uniqueness: { scope: :tax_report_id }
  validates :name, presence: true
  validates :description, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :ordered, -> { order(:position, :name) }
end
