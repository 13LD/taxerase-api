class AddSubmissionWindowsToReportEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :report_events, :window_start_date, :date
    add_column :report_events, :window_end_date, :date
  end
end
