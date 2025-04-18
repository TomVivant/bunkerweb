#!/bin/bash

# Check if supervisord is running with proper configuration
pgrep supervisord >/dev/null || { echo "Supervisord not running"; exit 1; }

# Check BunkerWeb service status (always required)
status=$(supervisorctl status "bunkerweb" 2>/dev/null)
if ! echo "$status" | grep -q "RUNNING"; then
  echo "Service bunkerweb is not running: $status"
  exit 1
fi

# Check BunkerWeb PID file exists
if [ ! -f /var/run/bunkerweb/nginx.pid ]; then
  echo "BunkerWeb PID file not found"
  exit 1
fi

# Check BunkerWeb health endpoint
check="$(curl -s -H "Host: healthcheck.bunkerweb.io" http://127.0.0.1:6000/healthz 2>&1)"
# shellcheck disable=SC2181
if [ $? -ne 0 ] || [ "$check" != "ok" ]; then
  echo "BunkerWeb health check failed: $check"
  exit 1
fi

# Check UI service status only if enabled
if [ "${USE_UI:-yes}" = "yes" ]; then
  status=$(supervisorctl status "ui" 2>/dev/null)
  if ! echo "$status" | grep -q "RUNNING"; then
    echo "Service ui is not running: $status"
    exit 1
  fi

  # Check UI PID file exists
  if [ ! -f /var/run/bunkerweb/ui.pid ]; then
    echo "UI PID file not found"
    exit 1
  fi

  # Check UI health marker file
  if [ ! -f /var/tmp/bunkerweb/ui.healthy ]; then
    echo "UI health marker file not found"
    exit 1
  fi
else
  echo "UI service check skipped (disabled by USE_UI setting)"
fi

# Check scheduler service status only if enabled
if [ "${USE_SCHEDULER:-yes}" = "yes" ]; then
  status=$(supervisorctl status "scheduler" 2>/dev/null)
  if ! echo "$status" | grep -q "RUNNING"; then
    echo "Service scheduler is not running: $status"
    exit 1
  fi

  # Check scheduler PID file exists
  if [ ! -f /var/run/bunkerweb/scheduler.pid ]; then
    echo "Scheduler PID file not found"
    exit 1
  fi

  # Check scheduler health marker file
  if [ ! -f /var/tmp/bunkerweb/scheduler.healthy ]; then
    echo "Scheduler health marker file not found"
    exit 1
  fi
else
  echo "Scheduler service check skipped (disabled by USE_SCHEDULER setting)"
fi

# Everything is fine
echo "All enabled services are healthy"
exit 0
