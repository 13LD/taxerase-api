# Portugal Calculator Completion Steps

## Active Task

Add Portugal to the calculator stack with employed and self-employed calculations, research deductible categories that can be exposed on the page, and verify the rollout end to end.

## Planned Completion Steps

1. Ground the Portugal tax model in current official sources.
2. Choose a bounded first-release Portugal scope that fits the existing architecture.
3. Add Portugal seed data, calculators, router, registry entry, controller, and route.
4. Add Portugal frontend config and page wiring.
5. Add or update specs that cover registry, page payloads, API calculations, and country switching.
6. Seed and run the targeted verification suite.
7. Document implemented deductions, deferred deduction categories, and verification evidence.

## Execution Log

- `2026-04-03`: Created initial rollout tracker and task context snapshot.
- `2026-04-03`: Implemented Portugal across the registry, routes, seed data, API controller, calculators, frontend config, and specs.
- `2026-04-03`: Extended Portugal support to tax years `2024`, `2025`, and `2026`.
- `2026-04-03`: Ran the post-completion ai-slop-cleaner pass and extracted reusable Portugal calculator support helpers.

## Implemented Scope

- Added Portugal (`PT`) to the public country registry, page payloads, and comparison catalog.
- Added Portugal calculator routes and API controller under `/api/v1/portugal/salary_calculation`.
- Added Portugal employee calculation support for `2024`, `2025`, and `2026`.
- Added Portugal self-employed calculation support for the simplified category B regime for `2024`, `2025`, and `2026`.
- Added Portugal frontend country config and country-switching coverage.

## Implemented Portugal Deductions

- Dependents.
- Dependents under 3.
- Ascendants in the household.
- Taxpayer disability at 60% or more.
- General family expenses.
- Health expenses.
- Education expenses.
- Eligible housing rent.
- Court-ordered alimony paid.
- Care home expenses.
- Domestic work remuneration.

## Implemented Portugal Self-Employed Inputs

- Activity type selector for:
  - Professional services.
  - Other services.
  - Goods, hospitality, food, or beverage.
- Documented business expenses input used for:
  - The simplified-regime documentation-gap adjustment.
  - Annual net-income cash-expense treatment.

## Researched But Deferred

- VAT / invoice-based deductions under article `78.º-F`.
- Union dues and professional-order dues in the article `25.º` specific-deduction path.
- Additional disability deductions for rehabilitation and eligible insurance or mutualist contributions.
- The second-and-later dependent bonus for children up to age 6.
- Legacy mortgage-interest deductions tied to pre-2011 contracts.
- IRS Jovem, joint filing, and other household-status variants.
- Organized accounting and start-of-activity reductions for self-employed taxpayers.
- Minimum-existence adjustments.

## Cleanup Notes

- Extracted shared Portugal calculator parsing, validation, and input-payload helpers into `app/services/taxerase/portugal/calculator_support.rb`.
- Replaced repeated source-selection branching in the Portugal seeder with reusable helper methods.
- Replaced repetitive Portugal frontend deduction-control objects with a shared descriptor-to-control builder.

## Verification

- `npm run build`
- `npm run lint:js`
- `bundle exec rspec spec/services/taxerase/country_calculators/registry_spec.rb spec/services/taxerase/country_calculators/portugal_definition_spec.rb spec/services/taxerase/seeds/tax_data_spec.rb spec/requests/pages_spec.rb spec/requests/api/v1/portugal/salary_calculations_spec.rb`
- `bundle exec rspec spec/system/country_calculator_switching_spec.rb spec/system/tax_comparison_spec.rb`

## Evidence Summary

- Request and service slice: `27 examples, 0 failures`
- System slice: `17 examples, 0 failures`
