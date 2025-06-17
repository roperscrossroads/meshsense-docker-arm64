#!/usr/bin/bash
set -e

export ADDRESS=${ADDRESS}
export PORT=${PORT}
export ACCESS_KEY=${ACCESS_KEY}
export DEV_UI_URL=${DEV_UI_URL}

export APPDIR="/meshsense"

# AppRun expects to find files relative to its location
cd /meshsense

exec ./AppRun --headless \
    --disable-gpu --in-process-gpu --disable-software-rasterizer