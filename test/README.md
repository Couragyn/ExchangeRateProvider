## Test helpers and guidelines

This project includes a few small, shared test helpers and conventions used by the Minitest suite. This document explains the helpers, how to use them, and how to run tests locally.

### Shared helpers

- `with_stub(klass, method_name, return_value)`
  - Location: `test/test_helper.rb`
  - Purpose: temporarily replaces a class singleton method with a simple stub that returns `return_value` for the duration of the provided block, and restores the original method afterward. This is useful for stubbing private class methods on services (for example, `ExchangeRateCacheService.fetch_fresh_daily_rates`).
  - Signature: `with_stub(klass, method_name, return_value) { ... }`

  Example:

  ```ruby
  with_stub(ExchangeRateCacheService, :fetch_fresh_daily_rates, daily_rates) do
    with_stub(ExchangeRateCacheService, :fetch_fresh_monthly_rates, monthly_rates) do
      rates = ExchangeRateCacheService.get_rates
      # assertions...
    end
  end
  ```

  Notes:
  - The helper preserves the original method when present and restores it after the block.
  - If the method didn't exist before, it will be removed after the block.

### WebMock

- WebMock is included for stubbing external HTTP requests in tests.
  - Gem: `webmock` (required in `test/test_helper.rb` via `require "webmock/minitest"`).
  - Use `stub_request` to intercept external calls made by `HTTParty` in `CnbExchangeRateService` tests.

  Example:

  ```ruby
  stub_request(:get, %r{api.cnb.cz/cnbapi/exrates/daily}).to_return(status: 200, body: { rates: [...] }.to_json)
  ```

### Test environment caching

- Tests are run with caching enabled and a `:memory_store` cache in `config/environments/test.rb` so cache behavior can be asserted.
  - This allows tests such as those in `test/services/exchange_rate_cache_service_test.rb` to verify that `Rails.cache` contains expected values after `get_rates` runs.

### Time helpers

- Use `ActiveSupport::Testing::TimeHelpers` (available in service tests) to advance time in tests, e.g.:

  ```ruby
  travel_to(Time.now + ExchangeRateCacheService::RATE_CACHE_DURATION + 1.second) do
    # assert cache expired and was refreshed
  end
  ```

### Running tests

Run the full suite:

```bash
bin/rails test
```

Run a single test file:

```bash
bin/rails test test/services/cnb_exchange_rate_service_test.rb -v
```

Run a single test method (Minitest `-n` uses a regex):

```bash
bin/rails test -n /falls_back_to_yesterday/
```