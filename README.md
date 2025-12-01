# Mews backend developer task (Ruby on Rails)

## Assignment instructions

The task is to implement an ExchangeRateProvider for Czech National Bank. The linked example is written in .NET, but it serves only as a reference. Find the data source on their web - part of the task is to find the source of the exchange rate data and a way how to extract it from there.

It is up to you to decide which Ruby gems to use and whether to implement it as a Rails application. Any code design changes/decisions to the provided skeleton are also completely up to you.

The application should expose a simple REST API (ideally JSON). Adding some UI (e.g. via server-rendered pages or a SPA) is a benefit for full-stack applications.

The solution has to be buildable, runnable and the test program should output the obtained exchange rates.

Goal is to implement a fully functional provider based on real world public data source of the assigned bank.

To submit your solution, just open a new pull request to this repository. Alternatively, you can share your repo with Mews interviewers.

Please write the code like you would if you needed this to run on production environment and had to take care of it long-term.

Should return exchange rates among the specified currencies that are defined by the source. But only those defined by the source, do not return calculated exchange rates. E.g. if the source contains "CZK/USD" but not "USD/CZK", do not return exchange rate "USD/CZK" with value calculated as 1 / "CZK/USD". If the source does not provide some of the currencies, ignore them.

## Developer Notes

- CNB Endpoint Swagger: https://api.cnb.cz/cnbapi/swagger-ui.html
- Endpoints for currency exchange rates
  - Endpoint for frequently updated currency exchange rates
    - https://api.cnb.cz/cnbapi/exrates/daily
    - Documentation states that CNB updates these rates weekdays at 2:30pm CEST
  - Endpoint for less frequently updated currency exchange rates
    - https://api.cnb.cz/cnbapi/fxrates/daily-month
    - Documentation states that CNB updates these rates on the last working day of the month
  - Both have language params (EN, CZ) and date params
- CNB only provides endpoints for converting other currencies into CZK
  - As the exchange rates are one way, this app only accepts 1 currency code provides the exchange rate and other relevant data
- Data from endpoint is cached by the app
  - If there are no cache entries, it queries the endpoint and sets the cache
  - A cronjob runs weekdays at 2:35pm CEST to ensure the exchange rate data is as up to date as possible


## Setup instructions

Prerequisites
- Docker & Docker-compose  

OR

- Ruby (match .ruby-version), Bundler

Recommended: run with Docker, these instructions will walk you through Docker setup

1) Build and start services
```bash
docker-compose build
```

2) Create .env file based on .env.sample and set variables

3) Run tests
```bash
docker-compose run --rm app bundle exec rake test
```

4) Start server
```bash
docker-compose up -d app cron
```

5) Test the API Endpoint

URL: `http://localhost/api/v1/exchange_rates?currency_code=CAD`

Sample Output:
```json
{"amount":1.0,"rate":13.635,"valid_for":"2025-12-01","rate_string":"1.0 AUD exchanges to 13.635 CZK, set on 2025-12-01 by CNB"}
```