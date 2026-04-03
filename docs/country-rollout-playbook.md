# Taxerase Country Rollout Playbook

## Purpose

This document is the reusable implementation standard for adding a new country to Taxerase.

It is based on the live Spain and Netherlands implementations already in this repository. Every future country should follow the same pattern:

- research official sources first
- model country-year rules in seed data
- keep calculators traceable to source records
- expose only fully implemented country-year-regime combinations
- validate that new country data does not break existing countries

As of April 2, 2026, the next recommended rollout order is:

1. Poland
2. Czech Republic

Follow-up notes for completed rollouts should live in dedicated docs. The current Andorra deferred-work tracker is:

- [Andorra calculator follow-ups](./andorra-calculator-followups.md)

## Current Reference Pattern

The current live countries define the reference architecture:

- Spain:
  - multi-year resident employee
  - multi-year resident self-employed
  - employee-only Beckham Law modifier
  - region-specific common-regime coverage
- Netherlands:
  - multi-year resident employee
  - multi-year resident self-employed
  - employee-only 30% ruling modifier
  - one national region

These two countries already prove the intended shared platform model:

- one country definition in the registry
- one country calculation router
- one country seed service
- shared tables for `countries`, `tax_regimes`, `tax_parameters`, `tax_brackets`, `official_tax_sources`, and `tax_source_usages`
- country-specific frontend config layered on top of a generic calculator engine

## Repository Touch Points

Every new country should be added through the same repository entry points.

### Backend

- add one seed service under `lib/taxerase/seeds`
- register that seeder in `lib/taxerase/seeds/tax_data.rb`
- add one country definition under `app/services/taxerase/country_calculators`
- register that definition in `app/services/taxerase/country_calculators/registry.rb`
- add one country router under `app/services/taxerase/<country>`
- add one or more calculator services under `app/services/taxerase/<country>`
- add one API controller under `app/controllers/api/v1/<country>`
- add the route in `config/routes.rb`

### Frontend

- add one country config under `app/javascript/components/taxCalculator/countries`
- keep country-specific regime toggles in `regimeControls`, not in the shared form engine
- keep comparison eligibility limited to shared profile semantics unless a new comparison model is explicitly introduced

### Specs

- seeding integrity spec updates in `spec/services/taxerase/seeds/tax_data_spec.rb`
- country definition spec
- router/service specs
- request spec for the country calculation endpoint
- system coverage for country switching and comparison behavior if the country is public

## General Delivery Standard

### 1. Research before code

Do not start by copying an existing country and changing numbers.

For each country-year candidate, first collect official sources for:

- personal income tax rates or scales
- social security rules for employees
- social and health contribution rules for self-employed
- tax credits, deductions, exemptions, and child/disability reliefs
- special regimes for inbound workers, pensioners, young workers, or entrepreneurs
- tax forms or filing guides that clarify eligibility and interaction rules

Required source quality:

- national tax authority
- national social security institution
- official public health insurance authority or government ministry when health contributions are separate
- government legal publication when rates depend on statute or decree text

Avoid basing seed data on private calculators, accounting blogs, or aggregator summaries.

### 2. Decide public scope before implementation

Every researched regime should be classified into one of these buckets:

- live now:
  - officially sourced
  - fully implemented end to end
  - tested
  - safe to expose publicly
- seeded but hidden:
  - source-backed
  - not yet fully implemented
  - kept out of the public selector
- research only:
  - identified in documentation
  - not yet modeled in DB

The public calculator should expose only the `live now` set.

### 3. Model the country in database-backed rules

For each supported tax year:

- create or update the `Country` row
- create `TaxRegime` rows per public or planned regime
- store rate tables in `tax_brackets`
- store constants and thresholds in `tax_parameters`
- store every official source in `official_tax_sources`
- attach source usage to regimes through `tax_source_usages`

Suggested naming rules:

- country code:
  - `PL` for Poland
  - `CZ` for Czech Republic
- tax regime keys:
  - stable, ASCII, year-independent
  - examples:
    - `employee_poland`
    - `self_employed_scale_poland`
    - `self_employed_linear_poland`
    - `employee_czech_republic`
    - `self_employed_czech_republic`
    - `flat_tax_czech_republic`
- use tax year on the record, not inside the key name

### 4. Keep country-specific logic behind a router

Follow the existing pattern:

- `Taxerase::<Country>::CalculationRouter`
- calculator service objects split by profile or regime
- helper services for repeated formulas

The router should:

- expose public year options
- expose public regime options
- choose the correct calculator by regime and year
- reject unsupported combinations clearly

### 5. Register the country in the web shell

Add:

- one backend definition class
- one frontend calculator config
- one internal API endpoint

The country definition should provide:

- country code and name
- default input
- calculation router
- any normalization needed for cross-country comparison defaults

The frontend config should provide:

- endpoint URL
- fallback title
- visible fields
- age options if needed
- regime controls such as checkboxes or selects

### 6. Seed idempotently and verify ownership

Every country seeder must inherit from `Taxerase::Seeds::BaseCountryTaxRules`.

That gives two important integrity checks:

- all expected `tax_regimes` for the country-year must belong to the correct `Country`
- all linked `official_tax_sources` must have the correct `country_code`

Do not skip these checks. They are the main defense against cross-country contamination in shared tables.

### 7. Test at four layers

Minimum required coverage:

- unit/service specs for formulas
- request spec for the country API endpoint
- country definition spec
- seed integrity coverage

If the country is public, also add:

- system coverage for country switching
- comparison coverage if the country participates in comparison mode

### 8. Validate against existing countries

A new country rollout is not complete until Spain and Netherlands still behave correctly.

Required regression checks:

- `Taxerase::Seeds::TaxData.call` still passes integrity expectations for all countries
- existing `ES` and `NL` regime-country links still match
- existing `ES` and `NL` source-country links still match
- country switch UI still changes in place without full page reload
- comparison still works across at least:
  - Spain vs Netherlands
  - Spain vs Spain
  - new country vs Spain

## Implementation Checklist

### Seed layer

1. Create `lib/taxerase/seeds/<country>_tax_rules.rb`
2. Add the seeder to `Taxerase::Seeds::TaxData::SEEDERS`
3. Define:
   - `SOURCE_DEFINITIONS`
   - expected regime keys by year
   - bracket replacement calls
   - parameter replacement calls
   - source usage replacement calls
4. Run:
   - `unset ASDF_RUBY_VERSION && bundle exec rails db:seed`

### Service layer

1. Create `app/services/taxerase/<country>/calculation_router.rb`
2. Add calculator services under `app/services/taxerase/<country>`
3. Keep formula helpers separate when reused across regimes
4. Make unsupported regimes explicit, not silent fallbacks

### Web/API layer

1. Add `app/services/taxerase/country_calculators/<country>_definition.rb`
2. Register it in the country registry
3. Add `app/controllers/api/v1/<country>/salary_calculations_controller.rb`
4. Add routes
5. Add frontend config under `app/javascript/components/taxCalculator/countries`

### Spec layer

1. Extend `spec/services/taxerase/seeds/tax_data_spec.rb`
2. Add country definition spec
3. Add router/service specs
4. Add request spec for `/api/v1/<country>/salary_calculation`
5. Add or extend system specs if the country is public

## Validation Commands

Use these commands after adding or changing a country:

```bash
yarn lint:js
yarn build
unset ASDF_RUBY_VERSION && RUBOCOP_CACHE_ROOT=tmp/rubocop_cache bundle exec rubocop --no-server
unset ASDF_RUBY_VERSION && bundle exec rails db:seed
unset ASDF_RUBY_VERSION && bundle exec rspec
```

If the rollout is large, also run a focused country-specific sequence before the full suite:

```bash
unset ASDF_RUBY_VERSION && bundle exec rspec spec/services/taxerase/seeds/tax_data_spec.rb
unset ASDF_RUBY_VERSION && bundle exec rspec spec/requests/pages_spec.rb spec/system/country_calculator_switching_spec.rb spec/system/tax_comparison_spec.rb
```

## Comparison Constraints

The current public comparison UI is intentionally narrow:

- shared `employee` profile
- shared `self_employed` profile
- same baseline income input semantics on both sides

That means country-specific variants should only be exposed in comparison if they still fit the shared profile contract.

Examples:

- Spain Beckham Law:
  - calculator-only modifier for employee mode
  - not currently part of comparison mode
- Netherlands 30% ruling:
  - calculator-only modifier for employee mode
  - not currently part of comparison mode
- Poland linear tax or ryczałt:
  - should not be added to public comparison until the comparison model explicitly supports those semantics
- Czech paušální daň:
  - same rule as above

## Poland Rollout Start

### Recommended first public scope

Build Poland in this order:

1. `2025` resident employee
2. `2025` self-employed on general tax scale
3. `2025` self-employed linear tax
4. backfill `2024` for the same regimes
5. evaluate `ryczałt` as a separate later regime because its rates depend on activity class

This keeps the first live Poland slice aligned with the existing comparison model while still respecting Poland's real regime variety.

### Regime inventory to research and classify

- employee on general tax scale
- self-employed on general tax scale
- self-employed 19% linear tax
- self-employed lump-sum on recorded revenue (`ryczałt`)
- IP Box overlay for qualifying activity
- startup social-contribution reliefs:
  - `ulga na start`
  - preferential social contribution base
  - `mały ZUS plus`

Recommended public v1:

- `employee_poland`
- `self_employed_scale_poland`

Recommended seeded-but-hidden next:

- `self_employed_linear_poland`
- `self_employed_ryczalt_poland`

### Deduction and relief inventory

Employee and general PIT reliefs to model or explicitly defer:

- tax-free amount and tax-reducing amount within the scale
- employee social insurance deduction handling
- employee standard deductible costs if in scope
- child relief
- disability rehabilitation relief
- social insurance deduction
- relief for young people under 26
- return relief
- relief for families with 4+ children
- relief for working seniors

Self-employed-specific items to model or defer:

- health contribution interaction by tax form
- social insurance deduction
- IP Box eligibility
- startup and small-business ZUS reliefs

### Official source shortlist

National tax authority and business tax guidance:

- Poland tax scale for business income:
  - https://www.podatki.gov.pl/podatki-firmowe/pit/informacje-podstawowe/co-jest-opodatkowane/rozliczenie-dochodow-opodatkowanych-skala-podatkowa/
- Poland linear tax:
  - https://www.podatki.gov.pl/podatki-firmowe/pit/informacje-podstawowe/co-jest-opodatkowane/rozliczenie-dochodow-opodatkowanych-podatkiem-liniowym/
- Poland lump-sum revenue tax:
  - https://www.podatki.gov.pl/pit/abc-pit/ryczalt-od-przychodow-ewidencjonowanych/?altTemplate=ArticlePdf&download=True
- social insurance deduction:
  - https://www.podatki.gov.pl/ulgi/odliczenie-skladek-na-ubezpieczenie-spoleczne-pit/
- child relief:
  - https://www.podatki.gov.pl/ulgi-i-odliczenia/ulga-na-dziecko-pit/
- disability rehabilitation relief:
  - https://www.podatki.gov.pl/ulgi/ulga-rehabilitacyjna-pit/
- relief for young:
  - https://www.podatki.gov.pl/ulgi/ulga-dla-mlodych-pit/
- return relief:
  - https://www.podatki.gov.pl/ulgi/ulga-na-powrot-pit/
- working senior relief:
  - https://www.podatki.gov.pl/ulgi-i-odliczenia/ulga-dla-pracujacych-seniorow-pit/
- 4+ family relief:
  - https://www.podatki.gov.pl/ulgi/ulga-dla-rodzin-4plus-pit/

Social insurance and entrepreneur relief sources:

- startup relief and preferential base:
  - https://www.zus.pl/en/-/ulga-na-start-preferencyjna-podstawa-dzialalnosc-nieewidencjonowana-jakie-sa-warunki-uprawnienia-i-skutk-1
- preferential contributions:
  - https://www.zus.pl/en/firmy/rozliczenia-z-zus/skladki-preferencyjne
- `mały ZUS plus` changes:
  - https://www.zus.pl/en/-/%E2%80%9Ema%C5%82y-zus-plus-nowe-zasady-od-2026-r.

### Poland implementation notes

- Poland will likely need more than one self-employed regime exposed eventually.
- Do not try to hide that variety behind one calculator with silent assumptions.
- The safest first public path is:
  - employee
  - self-employed on general scale
- linear tax and `ryczałt` should be added only after their own source-backed formula paths are implemented and tested.

### Poland file plan

- `lib/taxerase/seeds/poland_tax_rules.rb`
- `app/services/taxerase/poland/calculation_router.rb`
- `app/services/taxerase/poland/employee_calculator.rb`
- `app/services/taxerase/poland/self_employed_scale_calculator.rb`
- `app/services/taxerase/country_calculators/poland_definition.rb`
- `app/controllers/api/v1/poland/salary_calculations_controller.rb`
- `app/javascript/components/taxCalculator/countries/poland.js`

## Czech Republic Rollout Start

### Recommended first public scope

Build Czech Republic in this order:

1. `2025` resident employee
2. `2025` self-employed with standard income-tax flow and actual or percentage expenses
3. backfill `2024`
4. evaluate `paušální daň` as a later separate regime

### Regime inventory to research and classify

- employee
- self-employed under standard personal income tax rules
- self-employed using percentage expense deductions (`paušální výdaje`)
- flat-tax regime (`paušální daň`) for OSVČ
- pensioner contribution discount from 2025

Recommended public v1:

- `employee_czech_republic`
- `self_employed_czech_republic`

Recommended seeded-but-hidden next:

- `flat_tax_czech_republic`

### Deduction and relief inventory

Tax credits and household modifiers to model or defer:

- basic taxpayer credit
- spouse credit
- disability credits
- ZTP/P credit
- child tax credit or bonus
- non-taxable base deductions such as:
  - gifts
  - mortgage interest for housing needs
  - retirement and long-term savings contributions

Contribution-related items to model or defer:

- employee public health insurance
- employee social insurance
- self-employed pension contributions
- self-employed health insurance
- minimum wage and average wage references that affect thresholds
- pensioner social-contribution discount from 2025

### Official source shortlist

Tax authority:

- current personal income tax guidance for 2025:
  - https://financnisprava.gov.cz/cs/dane/dane/dan-z-prijmu/dotazy-a-odpovedi/dan-z-prijmu-fyzickych-osob/aktualne-k-dani-z-prijmu-fyzickych-osob-2025
- entrepreneur tax page:
  - https://financnisprava.gov.cz/cs/dane/dane/dan-z-prijmu/fyzicke-osoby/podnikatel-osvc
- flat-tax regime update for 2025:
  - https://financnisprava.gov.cz/cs/financni-sprava/media-a-verejnost/tiskove-zpravy-gfr/tiskove-zpravy-2024/pausalni-dan-2025-dulezite-zmeny

Social security and health insurance:

- self-employed pension contribution advances:
  - https://www.cssz.cz/web/cz/zalohy-na-pojistne-na-duchodove-pojisteni
- self-employed pensioner contribution discount:
  - https://www.cssz.cz/sleva-na-pojistnem-pro-osvc-ktera-je-pozivatelem-starobniho-duchodu?lang=en
- employee pensioner discount from 2025:
  - https://www.cssz.cz/-/sleva-na-pojistnem-pro-pracujici-duchodce-od-ledna-2025
- self-employed health insurance calculation:
  - https://www.vzp.cz/platci/informace/osvc/vymerovaci-zaklad-a-vypocet-pojistneho
- self-employed health advance calculation:
  - https://www.vzp.cz/platci/informace/osvc/zalohy-na-pojistne/vypocet-zaloh-na-pojistne
- employee health insurance calculation:
  - https://www.vzp.cz/platci/informace/zamestnavatel/vymerovaci-zaklad-a-vypocet-pojistneho

Economic thresholds:

- 2025 social insurance overview:
  - https://mpsv.gov.cz/socialni-pojisteni-v-roce-2025
- minimum wage updates:
  - https://mpsv.gov.cz/minimalni-mzda-od-ledna-2026-vzroste-o-1-600-korun-na-22-400-korun-mesicne

### Czech Republic implementation notes

- Czech employee and self-employed flows both depend on non-tax income thresholds that are influenced by minimum or average wage references.
- `paušální daň` should be modeled as a separate regime, not a checkbox inside the standard self-employed path.
- If self-employed v1 starts with percentage expenses, the chosen expense category must be an explicit selector because the percentage depends on activity type.

### Czech Republic file plan

- `lib/taxerase/seeds/czech_republic_tax_rules.rb`
- `app/services/taxerase/czech_republic/calculation_router.rb`
- `app/services/taxerase/czech_republic/employee_calculator.rb`
- `app/services/taxerase/czech_republic/self_employed_calculator.rb`
- `app/services/taxerase/country_calculators/czech_republic_definition.rb`
- `app/controllers/api/v1/czech_republic/salary_calculations_controller.rb`
- `app/javascript/components/taxCalculator/countries/czech_republic.js`

## Release Gate For Any New Country

A country is ready for public exposure only when all of the following are true:

- source inventory is captured in code and docs
- seed data is idempotent
- regime-country ownership passes integrity checks
- source-country ownership passes integrity checks
- API request spec passes
- country definition spec passes
- country switch UI works without full page refresh
- comparison still works for already public countries
- unsupported regimes remain hidden until implemented

If one of these is missing, keep the country or regime out of the public selector.
