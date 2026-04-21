#!/bin/bash

# JupyterLab Launcher
# Starts JupyterLab and opens browser with cleanup on exit
# Usage: bash start-jupyter.sh [directory]

set -e

# Load environment variables from .env if it exists
if [ -f .env ]; then
    echo "Loading environment variables from .env..."
    export $(grep -v '^#' .env | xargs)
fi

# Parse arguments
WORKDIR="${1:-.}"

if [ ! -d "$WORKDIR" ]; then
    echo "Error: Directory does not exist: $WORKDIR" >&2
    exit 1
fi

# Cleanup function to kill JupyterLab
cleanup() {
    echo "Shutting down..."
    if [ -n "$JLAB_PID" ] && kill -0 "$JLAB_PID" 2>/dev/null; then
        kill "$JLAB_PID" 2>/dev/null || true
    fi
}

# Set trap to run cleanup on exit
trap cleanup EXIT INT TERM

# Configure SSL certificates for extracted environments
# (common issue when extracting conda envs from containers)
export SSL_CERT_FILE=${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}
export REQUESTS_CA_BUNDLE=${REQUESTS_CA_BUNDLE:-/etc/ssl/certs/ca-certificates.crt}
export CURL_CA_BUNDLE=${CURL_CA_BUNDLE:-/etc/ssl/certs/ca-certificates.crt}

# Start JupyterLab server
echo "Starting JupyterLab..."
echo "Working directory: $(cd "$WORKDIR" && pwd)"
jupyter lab --no-browser "$WORKDIR" &
JLAB_PID=$!
sleep 3

# Launch Chromium in app mode
echo "Launching browser..."
chromium-browser --app=http://localhost:8888 --user-data-dir=/home/ash/.config/chromium-jupyter

# Chromium has closed, cleanup will run automatically via trap
