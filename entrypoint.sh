#!/bin/sh
set -e

mkdir -p /var/run/dbus

dbus-daemon --system --fork --nopidfile 2>/dev/null \
  || echo "[warn] DBus daemon could not start; Bluetooth scanning disabled"

exec su -s /bin/sh -c 'exec "$@"' -- node "$@"
