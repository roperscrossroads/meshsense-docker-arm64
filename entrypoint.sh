#!/usr/bin/bash
set -e

export ADDRESS=${ADDRESS}
export PORT=${PORT}
export ACCESS_KEY=${ACCESS_KEY}

/home/mesh/meshsense-app/AppRun --headless \
    --disable-gpu --in-process-gpu --disable-software-rasterizer