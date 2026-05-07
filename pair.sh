#!/usr/bin/env bash
set -euo pipefail

PS5_HOST="${1:?Usage: ./pair.sh <PS5_IP>}"

cd "$(dirname "$0")"

mkdir -p daemon/.pyremoteplay

docker run --rm -it \
  --network host \
  -v "$(pwd)/daemon:/data" \
  -v "$(pwd)/daemon/.pyremoteplay:/root/.pyremoteplay" \
  -w /data \
  python:3.12-slim \
  bash -lc '
    apt-get update
    apt-get install -y --no-install-recommends build-essential
    python -m pip install --upgrade pip
    python -m pip install pyremoteplay "pyee<12" av async_timeout
    pyremoteplay "'"$PS5_HOST"'" --register
    echo
    echo "Saved pyremoteplay files:"
    find /root/.pyremoteplay -maxdepth 3 -type f -print
  '
