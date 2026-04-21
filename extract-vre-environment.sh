#!/bin/bash
set -e

# VRE Environment Extractor
# Extracts the conda environment from VRE Docker container to miniforge3 envs

ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

: "${VRE_TAG:?VRE_TAG must be set in .env}"

IMAGE="registry.gitlab.eox.at/esa/vires_vre_ops/vre-swarm-notebook"
TAG="${VRE_TAG}"
ENVS_DIR="${HOME}/miniforge3/envs"
ENV_NAME="vre"
ENV_PATH="${ENVS_DIR}/${ENV_NAME}"

echo "========================================"
echo "VRE Environment Extractor"
echo "========================================"
echo "Image: ${IMAGE}:${TAG}"
echo "Target: ${ENV_PATH}"
echo ""

# Verify miniforge3 envs directory exists
if [ ! -d "${ENVS_DIR}" ]; then
    echo "❌ Error: Miniforge3 envs directory not found: ${ENVS_DIR}"
    echo "Please ensure miniforge3 is installed or update ENVS_DIR in this script."
    exit 1
fi

# Check if environment already exists
if [ -d "${ENV_PATH}" ]; then
    echo "⚠ Environment already exists at ${ENV_PATH}"
    echo ""
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting."
        exit 0
    fi
    echo "Removing existing environment..."
    rm -rf "${ENV_PATH}"
fi

# Determine container runtime
if command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
elif command -v docker &> /dev/null; then
    CONTAINER_CMD="docker"
else
    echo "❌ Error: Neither podman nor docker found"
    exit 1
fi

echo "Using container runtime: ${CONTAINER_CMD}"
echo ""

# Method 1: Try podman/docker cp first (fastest)
echo "Method 1: Attempting direct copy..."
echo "Creating temporary container..."
CONTAINER_ID=$($CONTAINER_CMD create "${IMAGE}:${TAG}")

if [ $? -eq 0 ]; then
    echo "Copying /opt/conda from container (this may take a few minutes)..."
    if $CONTAINER_CMD cp "${CONTAINER_ID}:/opt/conda" "${ENV_PATH}"; then
        echo "Cleaning up temporary container..."
        $CONTAINER_CMD rm "${CONTAINER_ID}" > /dev/null
        
        echo "Fixing permissions..."
        chmod -R u+rwX "${ENV_PATH}" 2>/dev/null || true
        
        echo ""
        echo "✓ Environment extracted successfully using direct copy!"
    else
        echo "❌ Direct copy failed, trying tar method..."
        $CONTAINER_CMD rm "${CONTAINER_ID}" > /dev/null
        
        # Method 2: Use tar through volume mount (more reliable)
        echo ""
        echo "Method 2: Using tar extraction..."
        TEMP_TAR="${CACHE_DIR}/${ENV_NAME}.tar.gz"
        
        echo "Creating tar archive in container..."
        $CONTAINER_CMD run --rm \
            -v "${ENVS_DIR}:/output:Z" \
            --user $(id -u):$(id -g) \
            "${IMAGE}:${TAG}" \
            bash -c "cd /opt && tar czf /output/$(basename ${TEMP_TAR}) conda"
        
        echo "Extracting tar archive..."
        cd "${ENVS_DIR}"
        tar xzf "$(basename ${TEMP_TAR})"
        mv conda "${ENV_NAME}"
        rm "$(basename ${TEMP_TAR})"
        
        echo ""
        echo "✓ Environment extracted successfully using tar!"
    fi
else
    echo "❌ Failed to create container"
    exit 1
fi

# Verify extraction
echo ""
echo "Verifying extraction..."
if [ -f "${ENV_PATH}/bin/python" ]; then
    PYTHON_VERSION=$("${ENV_PATH}/bin/python" --version 2>&1)
    echo "✓ Python found: ${PYTHON_VERSION}"
else
    echo "❌ Python not found in extracted environment"
    exit 1
fi

# Report size
ENV_SIZE=$(du -sh "${ENV_PATH}" | cut -f1)
echo "✓ Environment size: ${ENV_SIZE}"

# Fix OpenSSL issues (common when extracting from containers)
echo ""
echo "Fixing OpenSSL..."
mamba install --prefix "${ENV_PATH}" --force-reinstall --yes openssl
echo "✓ OpenSSL reinstalled"

echo ""
echo "========================================"
echo "✓ EXTRACTION COMPLETE"
echo "========================================"
echo "Location: ${ENV_PATH}"
echo "Python: ${ENV_PATH}/bin/python"
echo ""
echo "  1. Launch JupyterLab:"
echo "     pixi run jlab"
echo ""
echo "  2. Or activate manually:"
echo "     source ${ENV_PATH}/bin/activate"
echo ""
echo "  Note: nb_conda_kernels will auto-detect this as"
echo "        'Python [conda env:${ENV_NAME}]'"
echo ""
