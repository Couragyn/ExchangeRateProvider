require "test_helper"

class ScheduleConfigTest < ActiveSupport::TestCase
  test "schedule.rb contains cron entry to refresh exchange rates on weekdays at 2:35pm" do
    schedule_path = Rails.root.join("config", "schedule.rb")
    assert File.exist?(schedule_path), "Expected config/schedule.rb to exist"

    content = File.read(schedule_path)

    # Check job_template is set
    assert_match(/set\s+:job_template/, content)

    # Check output path is set
    assert_match(/set\s+:output,\s*["'].*cron.log["']/, content)

    # Check there's a weekday schedule and the runner calls the RefreshExchangeRatesJob
    assert_match(/every\s+:weekday,\s*at:\s*["']2:35 pm["']/, content)
    assert_match(/runner\s+["']RefreshExchangeRatesJob\.perform_later["']/, content)
  end
end
