#!/bin/bash
echo "================= Running create DB ========================"
python /create_db.py
echo "============================================================"

echo "================= Running sentry upgrade ==================="
sentry upgrade --noinput
echo "============================================================"

echo "================= Running sentry custom bootstrap =========="
echo "execfile('bootstrap.py')" | sentry django shell
echo "============================================================"

export C_FORCE_ROOT=true
sentry run cron &
sentry run worker &
sentry run web
