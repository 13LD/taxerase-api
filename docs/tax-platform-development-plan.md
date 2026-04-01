# Taxerase Development Plan

## Goal

Build a multi-country tax calculation platform that:

- calculates net income and tax breakdown for a selected country and tax year
- supports multiple years such as `2024`, `2025`, and future releases
- compares two countries side by side, for example `Spain vs Portugal` or `Spain vs Netherlands`
- serves both mobile apps through an API and the web product through a monolith application

The product should behave like a modern salary tax calculator, similar to the Spain example you shared, but with broader country coverage, explicit tax-year selection, and comparison workflows.

## Recommended Product Scope

### MVP Scope

- employment income only
- resident individual tax calculations
- yearly and monthly views
- tax year selector
- special regime support where clearly defined, starting with country-specific flags such as Spain's Beckham Law
- country comparison between two calculation results
- public web calculator
- mobile-ready API
- admin/backoffice for tax rule releases and content management

### Initial Countries

- Spain
- Portugal
- Netherlands

These three are enough to validate cross-country modeling and comparison without over-expanding the first release.

### Initial Tax Years

- 2024
- 2025

The system should be designed so adding `2026` is a data and rules release, not a redesign.

### Out of Scope for MVP

- self-employment and company payroll
- capital gains, dividends, crypto, rental income, wealth tax, and inheritance tax
- full personal tax filing workflows
- tax advice or legal document generation
- all municipality-level or rare edge-case deductions unless required for the first target countries

## Product Requirements

### Core User Flows

1. A user selects country, tax year, income amount, salary period, and optional special regime.
2. The system returns taxable income, income tax, social contributions, total tax, net annual income, and net monthly income.
3. A user compares two countries using the same baseline input set.
4. A user can switch tax year and immediately see the delta for the same country.
5. An admin can publish a new country-year rule set without changing application architecture.

### Output Requirements

Each calculation result should include:

- gross income
- normalized annual gross income
- income tax amount
- employee social security amount
- total tax amount
- annual net income
- monthly net income
- effective tax rate
- tax-year metadata
- calculation assumptions and disclaimers
- calculation trace for audit and debugging

## Architecture Recommendation

Use a single Rails modular monolith first, with clear internal boundaries:

- `TaxCore`: tax domain, rule engine, calculators, comparison logic
- `Public API`: JSON API for mobile apps and future partners
- `Web`: public calculator, comparison pages, landing pages, SEO content
- `Backoffice`: admin UI for tax rule management, validation, and publishing

This is the fastest way to ship because:

- one codebase owns tax logic
- no duplication between API and web
- lower operational overhead
- easier testing and release management
- future extraction remains possible if scale demands it

### Phase 2 Extraction Path

If the platform later needs separate deployables, extract in this order:

- shared `tax_core` gem or internal engine
- standalone API app
- standalone web app

The tax engine should never live separately from its tests, fixtures, and audit traces.

## Domain Model

### Core Entities

- `Country`
- `TaxYear`
- `RuleSet`
- `SpecialRegime`
- `CalculationRequest`
- `CalculationResult`
- `ComparisonRequest`
- `ComparisonResult`
- `RuleSourceReference`
- `RuleRelease`

### Important Design Rule

Tax logic must be versioned by `country + tax_year + rule_release_version`.

That allows:

- historical reproducibility
- corrections without silent result drift
- rollback if a rule release is wrong
- support for future legal updates during the same tax year

## Tax Engine Design

### Principles

- keep tax rules as structured data where possible
- use Ruby strategy objects for complex country-specific logic
- separate input normalization from calculation logic
- produce deterministic outputs for the same inputs and rules version
- return a calculation trace for transparency and support

### Suggested Structure

- `TaxCore::Inputs`
- `TaxCore::Normalizers`
- `TaxCore::Rules`
- `TaxCore::Calculators`
- `TaxCore::Comparisons`
- `TaxCore::Presenters`

### Country-Year Implementation Standard

Each supported country-year should have:

- input schema
- validation rules
- rule data
- calculator implementation
- fixture examples
- regression tests
- legal or accountant reference notes

## API Plan

### API Style

- REST JSON API
- versioned under `/api/v1`
- public calculation endpoints can be unauthenticated with rate limiting
- authenticated endpoints can support saved scenarios, history, and user preferences later

### MVP Endpoints

- `GET /api/v1/countries`
- `GET /api/v1/countries/:code/tax_years`
- `GET /api/v1/countries/:code/special_regimes`
- `POST /api/v1/calculations`
- `POST /api/v1/comparisons`
- `GET /api/v1/health`

### Example Calculation Request

```json
{
  "country": "ES",
  "tax_year": 2025,
  "income_amount": 60000,
  "salary_period": "YEAR",
  "special_regime": "beckham_law",
  "residency_status": "resident",
  "filing_status": "single"
}
```

### Example Comparison Request

```json
{
  "left": {
    "country": "ES",
    "tax_year": 2025,
    "income_amount": 60000,
    "salary_period": "YEAR",
    "special_regime": null
  },
  "right": {
    "country": "PT",
    "tax_year": 2025,
    "income_amount": 60000,
    "salary_period": "YEAR",
    "special_regime": null
  }
}
```

### API Response Expectations

- normalized request payload
- result breakdown
- comparison deltas when applicable
- metadata for country, year, and rule version
- disclaimer text
- trace identifiers for support

## Web Monolith Plan

### Public Web Features

- country calculator pages
- country comparison pages
- tax year switcher
- country-specific explanations and disclaimers
- SEO landing pages for high-intent searches such as "Spain salary tax calculator 2025"
- localization support from day one

### Backoffice Features

- manage country availability
- manage tax-year publication status
- upload or edit rule data
- preview calculations before publishing
- compare old and new outputs
- maintain legal notes and release notes

### Rendering Approach

Use server-rendered Rails pages first with progressive enhancement where needed. This keeps SEO strong, complexity low, and delivery speed high.

## Data and Release Strategy

### Rule Source Workflow

For every country-year release:

1. collect official brackets, contribution rates, thresholds, and special-regime rules
2. model them in rule data and calculator code
3. validate against worked examples
4. review with tax/legal domain expert
5. publish as a versioned rule release

### Reusable Country Rollout Standard

Every new country must follow the same implementation track so the platform stays maintainable as coverage expands.

Required rollout units per country:

- one `Country` record in the database
- one dedicated country seed service under `lib/taxerase/seeds`
- one country calculator definition in the registry used by the web app
- one country calculation router under `app/services/taxerase/<country>`
- one or more country-specific calculator services, split by tax profile or regime
- official source records mapped to each live tax year and regime
- a web config for labels, visible inputs, and API endpoint selection
- request, service, and browser coverage for the live public flows

Required rollout checks per country:

- all `tax_regimes` must belong to the correct `countries` row
- all `official_tax_sources` linked to a regime must match the regime country
- all public selectors must expose only supported years and regimes
- all results must return the same output contract: annual net income, monthly net income, effective tax rate, detailed breakdown, assumptions, and official sources
- country switching in the web monolith must load the correct country definition and API endpoint

### Current Multi-Country Implementation Track

The current monolith should be treated as the reference pattern for future countries:

- Spain remains the first full reference country with multi-year resident employee and self-employed coverage
- Netherlands is the second live country and validates that the same shared tables, page shell, and internal API contract can support a different tax model
- future countries such as Portugal should reuse the same delivery steps:
  1. source research
  2. database seed service
  3. country router and calculators
  4. country definition registration
  5. country-specific web config
  6. API endpoint
  7. regression coverage

### Seed Data Architecture

Seed data should be orchestrated through one shared seed runner that invokes country-specific seed services.

This runner must:

- load all live country seed services
- re-seed idempotently
- verify country-to-regime integrity after seeding
- verify source-to-country integrity after seeding

This is important because once multiple countries share the same `tax_regimes`, `tax_parameters`, `tax_brackets`, and `official_tax_sources` tables, any missing country scoping creates silent cross-country bugs.

### Data Storage

Store:

- country metadata
- tax year metadata
- rule releases
- calculator fixtures
- legal references
- release notes

Do not rely on opaque hardcoded values with no traceability.

## Testing Strategy

### Required Test Layers

- unit tests for low-level formulas and thresholds
- country-year regression tests with fixed fixtures
- golden test cases from official or accountant-reviewed examples
- API contract tests
- comparison tests to ensure both sides use the same normalization rules
- backoffice publish-flow tests

### Minimum Quality Gate

A new country-year release should not ship unless:

- fixtures pass
- previous releases remain unchanged
- trace output is generated
- review is completed by product and tax reviewer

## Delivery Phases

### Phase 0: Discovery and Domain Design

- confirm countries for MVP
- confirm supported input set
- define disclaimer and legal review process
- design canonical calculation request schema
- design rule-release lifecycle

### Phase 1: Platform Foundation

- create Rails monolith skeleton
- add API and web boundaries
- build `TaxCore`
- add authentication, rate limiting, audit logging, and admin roles
- create country-year-rule data model

### Phase 2: First Country Vertical Slice

- implement Spain for one tax year
- support Beckham Law as the first special regime
- build calculation endpoint
- build web calculator page
- add regression fixtures and audit trace

### Phase 3: Multi-Year Support

- add Spain 2024 and 2025 rule sets
- prove that historical calculations are reproducible
- add year switch UX in API and web

### Phase 4: Multi-Country Expansion

- add Portugal
- add Netherlands
- normalize cross-country comparison output
- expand content and disclaimers by country

### Phase 5: Comparison Experience

- build comparison endpoint
- build side-by-side web comparison page
- add result delta summaries such as net gain and effective tax difference

### Phase 6: Hardening and Launch

- performance tuning
- caching strategy
- analytics
- monitoring and alerting
- legal review
- launch readiness checklist

## Suggested Team Split

- Backend/API engineer: tax engine, API, data model, rule releases
- Full-stack or web engineer: public calculator, comparison UI, backoffice
- Product owner: scope, country priority, requirements
- Tax/legal reviewer: rule validation and sign-off

## Key Risks

- tax laws change frequently and sometimes mid-year
- country-specific exceptions can break a generic model if modeled too early
- public calculators can create legal exposure if disclaimers and assumptions are weak
- comparison is only trustworthy if inputs are normalized consistently
- social contribution rules can differ materially from income tax rules

## Open Decisions

- whether anonymous users can save scenarios
- whether monthly input should be primary or only normalized to yearly
- whether comparison should allow different tax years on each side
- whether the first public release is mobile-first or web-first
- whether content management should live inside the monolith or a separate CMS

## Recommendation

Start with one Rails modular monolith that ships:

- public web calculator
- mobile API
- backoffice
- shared tax engine

Ship one country end to end first, then prove multi-year support, then add the second and third countries, then release comparison. That sequence reduces tax-model risk and avoids building a comparison product on unstable calculation foundations.
