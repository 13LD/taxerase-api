# Taxerase

[![CI (main)](https://github.com/13LD/taxerase-api/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/13LD/taxerase-api/actions/workflows/ci.yml?query=branch%3Amain)

Taxerase is a Rails 8 monolith for source-backed Spain 2025 tax calculations. The current app includes a web UI at `/` and a JSON API for salary and self-employed calculation flows.

## Stack

- Ruby `4.0.2`
- Rails `8.1`
- PostgreSQL
- Node.js `20.19.0`
- Yarn `1.x`
- esbuild + React

## Local Setup

### Prerequisites

- PostgreSQL running locally
- Redis running locally
- Ruby matching [.ruby-version](/Users/dmytrolysohor/Dev/taxera-api/.ruby-version)
- Node matching [.node-version](/Users/dmytrolysohor/Dev/taxera-api/.node-version)
- Yarn installed

The app reads database settings from these environment variables:

```sh
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
POSTGRES_USER=$USER
POSTGRES_PASSWORD=
POSTGRES_DB=taxerase_development
POSTGRES_TEST_DB=taxerase_test
REDIS_URL=redis://127.0.0.1:6379/0
```

If your local PostgreSQL user is not your shell user, export `POSTGRES_USER` and `POSTGRES_PASSWORD` before setup.

### Bootstrap

```sh
bin/setup --skip-server
```

`bin/setup` installs Ruby gems, installs Yarn packages, prepares the database, and seeds the initial tax rules.

### Run The App

```sh
bin/dev
```

This starts:

- Redis
- the Rails server
- the JavaScript watcher that builds `app/assets/builds/application.js`
- the Resque worker
- the Resque scheduler

Open `http://127.0.0.1:3000`.

## Tests And CI

Build the frontend bundle before request specs so Propshaft can serve `application.js`.

```sh
yarn build
RAILS_ENV=test bin/rails db:prepare
RAILS_ENV=test bundle exec rspec
```

For Ruby linting:

```sh
RUBOCOP_CACHE_ROOT=tmp/rubocop_cache bundle exec rubocop --no-server
```

For JavaScript linting:

```sh
yarn lint:js
```

The main GitHub Actions workflow lives in [.github/workflows/ci.yml](/Users/dmytrolysohor/Dev/taxera-api/.github/workflows/ci.yml) and runs against the `main` branch badge shown above.

## Exchange Rates

Mixed-currency conversion uses persisted EUR-based reference rates stored in the database.

- Initial seeded rates keep local and test environments deterministic.
- A weekly Resque scheduler task refreshes configured quotes from Frankfurter:
  `https://api.frankfurter.dev/v2/rates?base=EUR&quotes=GBP,CHF,NOK,SEK,DKK,PLN,CZK,HUF,RON,ISK`

### Run Background Jobs Locally

If you already use `bin/dev`, the Resque worker and scheduler are started for you.

If you want to run them manually in separate terminals:

```sh
redis-server
QUEUE=* bundle exec rake resque:work
LOAD_RESQUE_SCHEDULE=true bundle exec rake resque:scheduler
```

What each process does:

- `redis-server`: queue backend
- `resque:work`: executes queued jobs
- `resque:scheduler`: enqueues the weekly exchange-rate sync according to `config/resque_schedule.yml`

### Trigger The Exchange Rate Sync Manually

To enqueue the job manually:

```sh
bundle exec rails runner 'Resque.enqueue(ExchangeRatesSyncJob)'
```

To run the sync service directly without queueing:

```sh
bundle exec rails runner 'Taxerase::ExchangeRates::SyncRates.call'
```

## API

Interactive UI:

- `GET /`

JSON API:

- `POST /api/v1/spain/salary_calculation`

Example request:

```json
{
  "calculation": {
    "gross_income": 60000,
    "salary_period": "YEAR",
    "tax_regime_key": "employee_madrid"
  }
}
```
