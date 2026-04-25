require "json"

module Taxerase
  module Seeds
    class ComplianceReports
      def self.call
        new.call
      end

      def call
        Dir.glob(File.join(__dir__, "countries", "*", "compliance_rules.json")).each do |path|
          seed_country_reports(JSON.parse(File.read(path)))
        end
      end

      private

      def seed_country_reports(data)
        country = Country.find_by!(code: data.fetch("country_code"))
        live_report_ids = data.fetch("reports", []).map do |report_data|
          seed_report(country, report_data)
        end

        TaxReport.where(country:).where.not(id: live_report_ids).find_each(&:destroy!)
      end

      def seed_report(country, report_data)
        report = TaxReport.find_or_initialize_by(
          country:,
          tax_year: report_data.fetch("tax_year"),
          key: report_data.fetch("key")
        )
        report.update!(
          name: report_data.fetch("name"),
          description: report_data["description"],
          active: report_data.fetch("active", true)
        )

        replace_workflows!(report, report_data.fetch("workflows", []))
        replace_events!(report, report_data.fetch("events", []))

        report.id
      end

      def replace_workflows!(report, workflows)
        report.report_workflows.delete_all
        report.association(:report_workflows).reset
        timestamp = Time.current

        return if workflows.empty?

        ReportWorkflow.upsert_all(
          workflows.each_with_index.map do |workflow, index|
            {
              tax_report_id: report.id,
              key: workflow.fetch("key"),
              name: workflow.fetch("name"),
              description: workflow.fetch("description"),
              reference_url: workflow["reference_url"],
              position: workflow.fetch("position", index + 1),
              created_at: timestamp,
              updated_at: timestamp
            }
          end,
          unique_by: :index_report_workflows_on_tax_report_id_and_key
        )
      end

      def replace_events!(report, events)
        report.report_events.delete_all
        report.association(:report_events).reset
        timestamp = Time.current

        return if events.empty?

        ReportEvent.upsert_all(
          events.each_with_index.map do |event, index|
            {
              tax_report_id: report.id,
              key: event.fetch("key"),
              title: event.fetch("title"),
              event_type: event.fetch("event_type"),
              event_date: Date.iso8601(event.fetch("event_date")),
              window_start_date: optional_date(event["window_start_date"]),
              window_end_date: optional_date(event["window_end_date"]),
              description: event["description"],
              position: event.fetch("position", index + 1),
              created_at: timestamp,
              updated_at: timestamp
            }
          end,
          unique_by: :index_report_events_on_tax_report_id_and_key
        )
      end

      def optional_date(value)
        return nil if value.blank?

        Date.iso8601(value)
      end
    end
  end
end
