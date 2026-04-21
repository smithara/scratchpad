#!/bin/bash

# VRE Container - Full Jupyter Inside Container
# This is for running Jupyter entirely inside the VRE container (not just kernels)

set -e

IMAGE="registry.gitlab.eox.at/esa/vires_vre_ops/vre-swarm-notebook"
WORKDIR="/home/ash/code"

echo "=========================================="
echo "Starting JupyterLab inside VRE container"
echo "=========================================="
echo ""
echo "This runs the ENTIRE Jupyter stack inside the container,"
echo "not just kernels. Use this for exact environment reproduction."
echo ""
echo "For daily work, use: pixi run jlab"
echo "(with cached VRE kernel)"
echo ""

# Load credentials if available
ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    if [ -n "$VRE_REGISTRY_USERNAME" ] && [ -n "$VRE_REGISTRY_PASSWORD" ]; then
        echo "Logging in to registry..."
        echo "$VRE_REGISTRY_PASSWORD" | podman login --username "$VRE_REGISTRY_USERNAME" --password-stdin registry.gitlab.eox.at 2>/dev/null || true
    fi
fi

: "${VRE_TAG:?VRE_TAG must be set in .env}"
TAG="${VRE_TAG}"

echo "Starting container..."
echo "Access at: http://localhost:10000"
echo "Press Ctrl+C to stop"
echo ""

podman run -it --rm \
    -p 10000:8888 \
    -v "$WORKDIR:/home/jovyan/workspace:Z" \
    --user $(id -u):$(id -g) \
    --userns=keep-id \
    --env JUPYTER_ENABLE_LAB=yes \
    "$IMAGE:$TAG"
