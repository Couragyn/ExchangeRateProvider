# Generated file that allows the cron container to run the scheduling logic defined in config/schedule.rb

#!/usr/bin/env bash
set -euo pipefail

# Entrypoint for a cron container that uses `whenever` to install crontab
#
# Behavior:
#  - cd to the app path (assumes repo is mounted at /app inside the container)
#  - run `bundle exec whenever --update-crontab` to write crontab from config/schedule.rb
#  - start the system cron daemon in foreground (supports Debian `cron` and Alpine `crond`)

APP_PATH=${APP_PATH:-/app}
RAILS_ENV=${RAILS_ENV:-production}

# Ensure timezone is set for the container/cron daemon. Honor TZ env var if provided,
# otherwise default will be picked up from the image (Dockerfile sets TZ=Europe/Prague).
export TZ=${TZ:-Europe/Prague}
if [ -f "/usr/share/zoneinfo/$TZ" ]; then
  ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime || true
  echo "$TZ" > /etc/timezone || true
fi

echo "[cron-entrypoint] starting in $APP_PATH (RAILS_ENV=$RAILS_ENV, TZ=$TZ)"
cd "$APP_PATH"

if ! command -v bundle >/dev/null 2>&1; then
  echo "[cron-entrypoint] warning: bundle not found in PATH. Ensure Bundler is installed in the image." >&2
fi

echo "[cron-entrypoint] updating crontab from config/schedule.rb (whenever)"
# Use --set to pass environment and path so the generated crontab contains correct commands
bundle exec whenever --update-crontab --set "environment=${RAILS_ENV}&path=$(pwd)" || {
  echo "[cron-entrypoint] whenever failed to update crontab" >&2
}

echo "[cron-entrypoint] installed crontab:" 
crontab -l || true

# Start cron in foreground. Support both Debian/Ubuntu cron and BusyBox/Alpine crond
if command -v crond >/dev/null 2>&1; then
  echo "[cron-entrypoint] starting crond (BusyBox/Alpine) in foreground"
  exec crond -f -l 8
elif command -v cron >/dev/null 2>&1; then
  echo "[cron-entrypoint] starting cron (Debian/Ubuntu) in foreground"
  exec cron -f
else
  echo "[cron-entrypoint] no cron binary found. Install 'cron' (Debian) or 'crond' (BusyBox) in the image." >&2
  exit 1
fi
