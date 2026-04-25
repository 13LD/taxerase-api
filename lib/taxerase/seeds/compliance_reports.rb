require "json"
require "uri"

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
        live_report_ids = data.fetch("reports", []).flat_map do |report_data|
          report_years(report_data).map do |tax_year|
            seed_report(country, materialize_report_for_year(report_data, tax_year))
          end
        end

        TaxReport.where(country:).where.not(id: live_report_ids).find_each(&:destroy!)
      end

      def report_years(report_data)
        report_data.fetch("tax_years", [ report_data.fetch("tax_year") ])
      end

      def materialize_report_for_year(report_data, tax_year)
        source_year = report_data.fetch("tax_year")
        year_offset = tax_year - source_year
        materialized_report = deep_copy(report_data)
        materialized_report["tax_year"] = tax_year

        shift_report_text!(materialized_report, year_offset)
        shift_event_dates!(materialized_report, year_offset)
        apply_workflow_reference_urls!(materialized_report, tax_year)

        materialized_report
      end

      def deep_copy(value)
        JSON.parse(JSON.generate(value))
      end

      def shift_report_text!(report_data, year_offset)
        shift_years_in!(report_data, "description", year_offset)

        report_data.fetch("events", []).each do |event|
          shift_years_in!(event, "title", year_offset)
          shift_years_in!(event, "description", year_offset)
        end
      end

      def shift_event_dates!(report_data, year_offset)
        report_data.fetch("events", []).each do |event|
          %w[event_date window_start_date window_end_date].each do |date_key|
            event[date_key] = shifted_date(event[date_key], year_offset) if event[date_key].present?
          end
        end
      end

      def shift_years_in!(data, key, year_offset)
        return if year_offset.zero? || data[key].blank?

        data[key] = data[key].gsub(/\b\d{4}\b/) { |year| (year.to_i + year_offset).to_s }
      end

      def shifted_date(value, year_offset)
        (Date.iso8601(value) >> (year_offset * 12)).iso8601
      end

      def apply_workflow_reference_urls!(report_data, tax_year)
        report_data.fetch("workflows", []).each do |workflow|
          reference_urls_by_tax_year = workflow.delete("reference_urls_by_tax_year")
          next if reference_urls_by_tax_year.blank?

          workflow["reference_url"] = reference_urls_by_tax_year[tax_year.to_s]
        end
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
              reference_url: validated_reference_url!(
                workflow["reference_url"],
                report_key: report.key,
                workflow_key: workflow.fetch("key")
              ),
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

      def validated_reference_url!(value, report_key:, workflow_key:)
        return nil if value.blank?

        uri = URI.parse(value)
        return value if uri.is_a?(URI::HTTP) && uri.host.present? && uri.to_s == value

        raise_invalid_reference_url!(report_key:, workflow_key:, value:)
      rescue URI::InvalidURIError
        raise_invalid_reference_url!(report_key:, workflow_key:, value:)
      end

      def raise_invalid_reference_url!(report_key:, workflow_key:, value:)
        raise ArgumentError,
              "Invalid reference_url for report #{report_key} workflow #{workflow_key}: #{value.inspect}"
      end
    end
  end
end
