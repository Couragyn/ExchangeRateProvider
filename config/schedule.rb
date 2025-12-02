set :job_template, "bash -lc 'export PATH=/usr/local/bundle/bin:$PATH; export BUNDLE_PATH=/usr/local/bundle; export GEM_HOME=/usr/local/bundle; export GEM_PATH=/usr/local/bundle; export BUNDLE_GEMFILE=/app/Gemfile; export BUNDLE_WITHOUT=development; :job'"
set :output, "/app/log/cron.log"

every :weekday, at: "2:35 pm" do
  runner "RefreshExchangeRatesJob.perform_later"
end
