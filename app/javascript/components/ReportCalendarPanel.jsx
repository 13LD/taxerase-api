import React, { useEffect, useMemo, useRef, useState } from "react";
import { requestReportCalendar } from "./taxCalculator/api";

const dateFormatter = new Intl.DateTimeFormat("en", {
  day: "numeric",
  month: "short",
  year: "numeric"
});

const shortDateFormatter = new Intl.DateTimeFormat("en", {
  day: "numeric",
  month: "short"
});

const monthFormatter = new Intl.DateTimeFormat("en", {
  month: "short"
});

const CALENDAR_MONTH_COUNT = 12;

function parseDate(value) {
  return new Date(`${value}T00:00:00`);
}

function formatDate(value) {
  return dateFormatter.format(parseDate(value));
}

function formatDateRange(startValue, endValue) {
  const startDate = parseDate(startValue);

  return `${shortDateFormatter.format(startDate)} - ${formatDate(endValue)}`;
}

function monthKeyForDate(value) {
  const date = parseDate(value);

  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

function monthForDate(value) {
  const date = parseDate(value);

  return {
    key: monthKeyForDate(value),
    label: monthFormatter.format(date),
    year: date.getFullYear(),
    events: []
  };
}

function monthKeyForEvent(event) {
  return monthKeyForDate(event.window_start_date || event.event_date);
}

function monthDateForKey(key) {
  return parseDate(`${key}-01`);
}

function eventSortDate(event) {
  return event.window_start_date || event.event_date;
}

function currentMonthKey() {
  const today = new Date();

  return `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}`;
}

function itemDateText(event) {
  if (event.event_type === "submission" && event.window_start_date && event.window_end_date) {
    return formatDateRange(event.window_start_date, event.window_end_date);
  }

  return formatDate(event.event_date);
}

function tooltipText(report, event) {
  return `${report.name}: ${event.description || event.title}`;
}

function calendarYearBounds(calendar, fallbackYear) {
  return {
    startYear: calendar?.start_year || fallbackYear,
    endYear: calendar?.end_year || fallbackYear
  };
}

function centerMonthInChart(chartElement, monthElement) {
  const targetLeft = monthElement.offsetLeft - ((chartElement.clientWidth - monthElement.clientWidth) / 2);

  chartElement.scrollTo({
    left: Math.max(targetLeft, 0),
    behavior: "auto"
  });
}

function monthsForYearRange(startYear, endYear) {
  const monthCount = ((endYear - startYear) + 1) * CALENDAR_MONTH_COUNT;

  return new Map(
    Array.from({ length: monthCount }, (_, index) => {
      const year = startYear + Math.floor(index / CALENDAR_MONTH_COUNT);
      const monthValue = String((index % CALENDAR_MONTH_COUNT) + 1).padStart(2, "0");
      const month = monthForDate(`${year}-${monthValue}-01`);

      return [ month.key, month ];
    })
  );
}

export default function ReportCalendarPanel({ active, countryCode, taxYear }) {
  const [calendar, setCalendar] = useState(null);
  const [status, setStatus] = useState("idle");
  const [errors, setErrors] = useState([]);
  const chartRef = useRef(null);
  const requestAbortControllerRef = useRef(null);
  const year = useMemo(() => taxYear || 2026, [taxYear]);
  const browserCurrentMonthKey = useMemo(() => currentMonthKey(), []);

  useEffect(() => {
    if (!active || !countryCode) return undefined;

    requestAbortControllerRef.current?.abort();
    const abortController = new AbortController();
    requestAbortControllerRef.current = abortController;
    setStatus("loading");
    setCalendar(null);
    setErrors([]);

    requestReportCalendar({
      countryCode,
      taxYear: year,
      signal: abortController.signal
    })
      .then(async (response) => {
        const payload = await response.json();
        if (abortController.signal.aborted) return;

        if (!response.ok) {
          setCalendar(null);
          setErrors(payload.errors || [ "Report calendar is not available." ]);
          setStatus("error");
          return;
        }

        setCalendar(payload);
        setStatus("success");
      })
      .catch(() => {
        if (abortController.signal.aborted) return;

        setCalendar(null);
        setErrors([ "Network error while loading the report calendar." ]);
        setStatus("error");
      });

    return () => abortController.abort();
  }, [active, countryCode, year]);

  const reports = useMemo(() => calendar?.reports || [], [calendar]);
  const workflowReports = useMemo(() => {
    const workflowTaxYear = calendar?.tax_year || year;

    return reports.filter((report) => report.tax_year === workflowTaxYear);
  }, [calendar?.tax_year, reports, year]);
  const chartMonths = useMemo(() => {
    const { startYear, endYear } = calendarYearBounds(calendar, year);
    const months = monthsForYearRange(startYear, endYear);

    reports.forEach((report) => {
      report.events.forEach((event) => {
        const key = monthKeyForEvent(event);

        if (!months.has(key)) {
          months.set(key, monthForDate(eventSortDate(event)));
        }

        months.get(key).events.push({ report, event });
      });
    });

    const calendarMonths = Array.from(months.values()).sort((first, second) => (
      monthDateForKey(first.key) - monthDateForKey(second.key)
    ));

    calendarMonths.forEach((month) => {
      month.events.sort((first, second) => {
        const firstDate = eventSortDate(first.event);
        const secondDate = eventSortDate(second.event);

        if (firstDate !== secondDate) return firstDate.localeCompare(secondDate);
        if (first.event.event_type !== second.event.event_type) {
          return first.event.event_type === "submission" ? -1 : 1;
        }

        return first.report.name.localeCompare(second.report.name);
      });
    });

    return calendarMonths;
  }, [calendar, reports, year]);
  const focusedMonthKey = useMemo(() => {
    if (chartMonths.some((month) => month.key === browserCurrentMonthKey)) {
      return browserCurrentMonthKey;
    }

    return chartMonths[0]?.key || "";
  }, [browserCurrentMonthKey, chartMonths]);

  useEffect(() => {
    if (!active || status !== "success" || !focusedMonthKey) return;

    window.requestAnimationFrame(() => {
      const chartElement = chartRef.current;
      const monthElement = chartElement?.querySelector(`[data-month-key="${focusedMonthKey}"]`);

      if (chartElement && monthElement) centerMonthInChart(chartElement, monthElement);
    });
  }, [active, focusedMonthKey, status]);

  if (status === "idle" || status === "loading") return null;

  return (
    <section className="liquid-card report-calendar-card">
      <div className="section-head">
        <div>
          {calendar?.country?.name ? (
            <p className="section-kicker">{calendar.country.name}</p>
          ) : null}
          <h2>Tax calendar</h2>
        </div>
      </div>

      {status === "error" ? (
        <div className="error-panel">{errors.join(" ")}</div>
      ) : null}

      {status === "success" && reports.length === 0 ? (
        <div className="availability-note">
          <p>No report calendar is available for this country and tax year yet.</p>
        </div>
      ) : null}

      {reports.length > 0 ? (
        <>
          <div
            aria-label={`${calendar?.country?.name} tax calendar`}
            className="report-calendar-chart"
            ref={chartRef}
            style={{ "--calendar-month-count": chartMonths.length }}
          >
            {chartMonths.map((month) => (
              <section
                className={`report-calendar-period${month.events.length === 0 ? " report-calendar-period--empty" : ""}${month.key === focusedMonthKey ? " report-calendar-period--current" : ""}`}
                data-month-key={month.key}
                key={month.key}
              >
                <div className="report-calendar-period__head">
                  <strong>{month.label}</strong>
                  <span>{month.year}</span>
                </div>

                <div className="report-calendar-period__track">
                  {month.events.map(({ report, event }) => (
                    <button
                      aria-label={tooltipText(report, event)}
                      className={`report-calendar-chart__item report-calendar-chart__item--${event.event_type}`}
                      key={`${report.tax_year}-${report.key}-${event.key}`}
                      title={tooltipText(report, event)}
                      type="button"
                    >
                      <strong>{report.name}</strong>
                      <time dateTime={event.event_date}>{itemDateText(event)}</time>
                      <span className="report-calendar-tooltip" role="tooltip">
                        {event.description || event.title}
                      </span>
                    </button>
                  ))}
                </div>
              </section>
            ))}
          </div>

          <div className="report-calendar-legend" aria-label="Calendar legend">
            <span>
              <i className="report-calendar-legend__swatch report-calendar-legend__swatch--submission" />
              Report submission
            </span>
            <span>
              <i className="report-calendar-legend__swatch report-calendar-legend__swatch--payment" />
              Tax payment
            </span>
          </div>

          <div className="report-calendar-workflows" aria-label="Report workflows">
            {workflowReports.map((report) => (
              <details className="report-calendar-workflow" key={`${report.tax_year}-${report.key}`}>
                <summary className="report-calendar-workflow__summary">
                  <span>
                    <span className="mini-label">{report.tax_year}</span>
                    <strong>{report.name}</strong>
                    <small>{report.description}</small>
                  </span>
                  <span className="report-calendar-workflow__meta">
                    {report.workflows.length} steps
                  </span>
                </summary>

                <ol className="report-calendar-workflow__steps">
                  {report.workflows.map((workflow, index) => (
                    <li className="report-calendar-workflow__step" key={workflow.key}>
                      <span className="report-calendar-workflow__step-number">
                        {index + 1}
                      </span>
                      <span>
                        <strong>{workflow.name}</strong>
                        <p>{workflow.description}</p>
                        {workflow.reference_url ? (
                          <a
                            className="report-calendar-workflow__reference"
                            href={workflow.reference_url}
                            target="_blank"
                            rel="noreferrer"
                          >
                            Official tax agency reference
                          </a>
                        ) : null}
                      </span>
                    </li>
                  ))}
                </ol>
              </details>
            ))}
          </div>
        </>
      ) : null}
    </section>
  );
}
