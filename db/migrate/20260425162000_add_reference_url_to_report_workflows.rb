class AddReferenceUrlToReportWorkflows < ActiveRecord::Migration[8.1]
  def change
    add_column :report_workflows, :reference_url, :string
  end
end
