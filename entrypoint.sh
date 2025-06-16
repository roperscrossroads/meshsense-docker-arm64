#!/usr/bin/bash
set -e

export ADDRESS=${ADDRESS}
export PORT=${PORT}
export ACCESS_KEY=${ACCESS_KEY}

exec /home/mesh/meshsense-beta-arm64.AppImage --headless \
  --disable-gpu --in-process-gpu --disable-software-rasterizer
