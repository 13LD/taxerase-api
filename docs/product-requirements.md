# Taxerase Product Requirements

## Document Status

- Status: Draft v1
- Product: Taxerase
- Platform direction: Rails + React monolith first, public API next

## Product Summary

Taxerase is a multi-country tax calculator that helps users estimate net salary and total tax burden for a selected country and tax year, then compare results across countries.

The first release should behave like a fast, trustworthy salary tax calculator for web users, while the application architecture should allow the same calculation flows to be exposed as API endpoints for mobile apps without rewriting the business logic.

## Problem Statement

Users evaluating relocation or employment options across countries do not have a simple way to compare net salary outcomes across jurisdictions and tax years.

Current calculators are often:

- limited to one country
- limited to one tax year
- unclear about assumptions
- hard to compare side by side
- not designed as reusable calculation platforms for both web and mobile products

Taxerase should solve this by providing a single product and calculation engine that supports:

- multiple countries
- multiple tax years
- country-specific special regimes
- transparent result breakdowns
- direct country comparison

## Vision

Create the most reliable and understandable web-first tax comparison experience for salaried individuals relocating across European countries, with a product foundation that can power both web and mobile applications.

## Product Goals

### MVP Goals

- calculate annual and monthly net salary for a selected country and tax year
- show a transparent tax breakdown including income tax and employee social contributions
- support side-by-side comparison between two countries
- support more than one tax year, starting with `2024` and `2025`
- support country-specific options such as Spain's Beckham Law
- deliver a web-first experience inside a Rails + React monolith
- expose the same calculation flows through JSON endpoints inside the monolith so they can later become the public mobile API

### Business Goals

- validate market demand for tax comparison across relocation scenarios
- create SEO entry points around high-intent salary calculator searches
- establish one source of truth for tax calculations across web and mobile
- reduce future platform duplication by designing API contracts early

## Non-Goals

The MVP should not attempt to solve:

- full personal tax filing
- corporate payroll processing
- self-employment tax calculations
- investment, capital gains, crypto, rental, inheritance, or wealth tax
- immigration or legal services workflows
- personalized tax advice

## Target Users

### Primary Users

- employees comparing relocation options across countries
- expats evaluating net salary impact before moving
- remote workers comparing after-tax outcomes in multiple jurisdictions
- candidates reviewing compensation packages in another country

### Secondary Users

- internal content or operations team managing country and tax-year availability
- mobile app users consuming the same tax calculations through API endpoints

## MVP Scope

### Countries

- Spain
- Portugal
- Netherlands

### Tax Years

- 2024
- 2025

### Income Type

- employment income only

### Core Modes

- single-country calculation
- two-country comparison

### Country-Specific Options

- special tax regimes supported where clearly modeled
- first example: Spain Beckham Law

## Product Principles

- trust over cleverness
- transparent assumptions over black-box outputs
- deterministic calculations over flexible but ambiguous logic
- shared business logic across web and API
- country-year versioning as a first-class concept

## Key User Stories

1. As a visitor, I want to select a country, year, and salary so I can estimate my net income.
2. As a visitor, I want to see the breakdown between income tax and social security so I understand how the result was derived.
3. As a visitor, I want to switch between tax years such as `2024` and `2025` so I can compare outcomes over time.
4. As a visitor, I want to compare two countries side by side so I can evaluate relocation options.
5. As a visitor, I want to apply a country-specific regime such as Beckham Law when available so the result reflects my scenario.
6. As an admin, I want to publish new country-year rule sets so the product can support future tax years without changing core architecture.
7. As a mobile consumer, I want API responses to match the web calculation outputs so product behavior is consistent across clients.

## Core User Flows

### Flow 1: Single-Country Calculation

1. User lands on a calculator page.
2. User selects country.
3. User selects tax year.
4. User enters gross income and salary period.
5. User selects optional regime if available.
6. System normalizes the input and returns result breakdown.
7. User sees annual net, monthly net, effective tax rate, and assumptions.

### Flow 2: Country Comparison

1. User opens comparison page.
2. User selects left and right country.
3. User uses the same baseline income input for both sides.
4. User selects tax year and optional regimes where supported.
5. System returns both calculations and a delta summary.
6. User sees which country provides higher net income and by how much.

### Flow 3: Admin Rule Release

1. Admin adds or edits a country-year rule set.
2. Admin validates preview calculations against fixtures.
3. Admin reviews assumptions and disclaimers.
4. Admin publishes a new rule release version.
5. Public calculator starts using the published version for that country and year.

## Functional Requirements

### Calculation Inputs

The system must support:

- country
- tax year
- income amount
- salary period: `YEAR` and `MONTH`
- optional special regime
- filing assumptions required by the chosen country model

The system should normalize all calculation requests to an annual basis before applying country rules.

### Calculation Outputs

Each result must include:

- gross input amount
- normalized annual income
- income tax amount
- employee social contribution amount
- total tax amount
- annual net income
- monthly net income
- effective tax rate
- selected country
- selected tax year
- applied special regime
- disclaimer text
- calculation version metadata

### Comparison Outputs

Comparison responses must include:

- left calculation result
- right calculation result
- annual net delta
- monthly net delta
- total tax delta
- effective tax rate delta
- summary label indicating which country is more favorable for the provided inputs

### Tax Year Support

The product must:

- treat tax year as an explicit input
- support different rule sets for the same country across years
- preserve reproducibility of historical calculations
- allow future rule-release corrections without silent output changes

### Special Regime Support

The product must support country-specific options when relevant.

Examples:

- Spain: Beckham Law

This support should be configurable per country and tax year rather than hardcoded into the main UI flow.

### Admin and Content Requirements

The internal team must be able to:

- enable or disable countries
- enable or disable tax years
- manage rule-release versions
- preview calculations before publish
- maintain disclaimers and assumptions text
- store reference sources for legal or tax validation

## Web Product Requirements

### Experience

The first product release is web-first.

The web app should provide:

- public country calculator pages
- public comparison pages
- responsive mobile-friendly layout
- localization-ready structure
- SEO-friendly URLs and metadata
- clear legal disclaimers

### UI Direction

Use Rails for the monolith application and React for the interactive calculator and comparison experiences.

Recommended split:

- Rails handles routing, server rendering, page composition, authentication, and admin
- React handles calculator forms, dynamic result rendering, comparison interactions, and future shared client-side components

### SEO Requirements

The web product should support landing pages such as:

- `/spain-tax-calculator`
- `/portugal-tax-calculator`
- `/netherlands-tax-calculator`
- `/compare/spain-vs-portugal`

## API Product Requirements

### API Direction

The monolith should expose internal JSON endpoints from the start.

Those endpoints should serve two purposes:

- power the React frontend
- become the basis of the external mobile API

This avoids creating separate business logic later.

### API Requirements

- version endpoints under `/api/v1`
- return stable JSON contracts
- include country, tax year, and rule-release metadata
- return validation errors in structured form
- keep calculation logic identical to the web experience

### Required MVP Endpoints

- `GET /api/v1/countries`
- `GET /api/v1/countries/:code/tax_years`
- `GET /api/v1/countries/:code/special_regimes`
- `POST /api/v1/calculations`
- `POST /api/v1/comparisons`

## Data and Calculation Requirements

### Rule Versioning

Tax logic must be versioned by:

- country
- tax year
- rule release version

### Traceability

Each country-year implementation should have:

- source references
- fixtures
- calculation tests
- release notes

### Determinism

The same request payload and same rule-release version must always produce the same result.

## Non-Functional Requirements

### Performance

- calculator and comparison responses should feel immediate for normal user flows
- common requests should be cacheable where safe

### Reliability

- calculation failures must return structured errors
- unsupported country-year combinations must be explicit
- published rule releases must not break previous years

### Observability

- log requests and calculation identifiers
- keep trace IDs for support and debugging
- monitor endpoint latency and error rates

### Security

- rate-limit public calculation endpoints
- protect admin functionality
- avoid exposing internal implementation details in error responses

### Legal and Trust

- show disclaimers on all calculation results
- make assumptions explicit
- keep legal review or accountant validation in the release workflow

## Acceptance Criteria for MVP

The MVP is successful when:

1. A user can calculate salary tax for Spain, Portugal, or Netherlands for tax year `2024` or `2025`.
2. A user can compare two supported countries side by side for the same baseline income.
3. Results show annual net, monthly net, income tax, social contributions, total tax, and effective rate.
4. Spain supports a special regime flow for Beckham Law where applicable.
5. The same calculation flow is available through internal JSON endpoints in the Rails monolith.
6. Admin users can manage country-year publication and rule-release versions.
7. Calculation outputs are backed by regression tests and fixed fixtures.

## Delivery Recommendation

### Stage 1

- finalize product requirements
- lock MVP inputs and outputs
- define country-year domain model

### Stage 2

- create Rails + React monolith
- implement internal JSON endpoints
- build Spain vertical slice end to end

### Stage 3

- add multi-year support
- add Portugal and Netherlands
- launch comparison experience

### Stage 4

- expose stable API endpoints for mobile apps
- expand saved scenarios, user accounts, and richer input models if needed

## Technical Direction To Align Next Step

The next implementation step should be a Rails monolith that contains:

- public web pages
- React frontend entry points
- internal `/api/v1` JSON endpoints
- admin/backoffice
- shared tax engine modules

The API should not be a separate application yet. The correct first move is one monolith with one tax engine and one contract model, then later reuse those same endpoints for mobile clients.
