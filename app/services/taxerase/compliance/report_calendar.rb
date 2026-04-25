module Taxerase
  module Compliance
    class ReportCalendar
      DEFAULT_TAX_YEAR = 2026
      YEAR_WINDOW_RADIUS = 1

      def self.call(...)
        new(...).call
      end

      def initialize(country_code:, tax_year: nil)
        @country_code = country_code
        @tax_year = tax_year.presence || DEFAULT_TAX_YEAR
      end

      def call
        reports = TaxReport
          .active
          .for_country_year(country:, tax_year: tax_year_range)
          .includes(:report_workflows, :report_events)
          .ordered_for_calendar

        {
          country: country_payload,
          tax_year: tax_year,
          start_year: tax_year_range.begin,
          end_year: tax_year_range.end,
          tax_years: tax_year_range.to_a,
          reports: reports.map { |report| report_payload(report) }
        }
      end

      private

      attr_reader :country_code

      def country
        @country ||= Country.find_by!(code: country_code.to_s.upcase)
      end

      def tax_year
        @tax_year.to_i
      end

      def tax_year_range
        @tax_year_range ||= ((tax_year - YEAR_WINDOW_RADIUS)..(tax_year + YEAR_WINDOW_RADIUS))
      end

      def country_payload
        {
          code: country.code,
          name: country.name,
          currency_code: country.currency_code
        }
      end

      def report_payload(report)
        {
          key: report.key,
          name: report.name,
          tax_year: report.tax_year,
          description: report.description,
          workflows: ordered_workflows(report).map { |workflow| workflow_payload(workflow) },
          events: ordered_events(report).map { |event| event_payload(event) }
        }
      end

      def ordered_workflows(report)
        report.report_workflows.sort_by { |workflow| [ workflow.position, workflow.name ] }
      end

      def ordered_events(report)
        report.report_events.sort_by { |event| [ event.event_date, event.position, event.title ] }
      end

      def workflow_payload(workflow)
        {
          key: workflow.key,
          name: workflow.name,
          description: workflow.description,
          reference_url: workflow.reference_url
        }
      end

      def event_payload(event)
        {
          key: event.key,
          title: event.title,
          event_type: event.event_type,
          event_date: event.event_date.iso8601,
          window_start_date: event.window_start_date&.iso8601,
          window_end_date: event.window_end_date&.iso8601,
          description: event.description
        }
      end
    end
  end
end
