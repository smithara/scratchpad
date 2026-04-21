#!/bin/bash
set -e

# VRE Kernel Registration (OPTIONAL)
# Manually registers extracted VRE conda environment as a Jupyter kernel
#
# NOTE: If you have nb_conda_kernels installed (recommended), this script
#       is NOT needed - conda environments are automatically detected!
#
# Use this only if:
#   - nb_conda_kernels is not installed
#   - You want a custom kernel display name
#   - For compatibility with older Jupyter setups

ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
fi

: "${VRE_TAG:?VRE_TAG must be set in .env}"

TAG="${1:-${VRE_TAG}}"
ENVS_DIR="${HOME}/miniforge3/envs"
ENV_NAME="vre"
ENV_PATH="${ENVS_DIR}/${ENV_NAME}"
DISPLAY_NAME="VRE Python ${TAG}"

echo "========================================"
echo "VRE Kernel Registration (Manual)"
echo "========================================"
echo ""
echo "⚠ Note: This is optional if you have nb_conda_kernels installed."
echo "  With nb_conda_kernels, conda environments are auto-detected."
echo ""
echo "Kernel name: ${ENV_NAME}"
echo "Display name: ${DISPLAY_NAME}"
echo "Environment: ${ENV_PATH}"
echo ""

# Verify environment exists
if [ ! -d "${ENV_PATH}" ]; then
    echo "❌ Error: Environment not found at ${ENV_PATH}"
    echo ""
    echo "Available conda environments:"
    ls -1 "${ENVS_DIR}" 2>/dev/null || echo "  (none)"
    echo ""
    echo "Run extract-vre-environment.sh first to extract the environment."
    exit 1
fi

# Verify Python exists
if [ ! -f "${ENV_PATH}/bin/python" ]; then
    echo "❌ Error: Python not found at ${ENV_PATH}/bin/python"
    echo "The environment may be corrupted. Try extracting again."
    exit 1
fi

# Check if ipykernel is installed
echo "Checking for ipykernel..."
if ! "${ENV_PATH}/bin/python" -c "import ipykernel" 2>/dev/null; then
    echo "⚠ ipykernel not found, installing..."
    "${ENV_PATH}/bin/pip" install ipykernel
fi

# Check if kernel already exists
KERNEL_SPEC_DIR="${HOME}/.local/share/jupyter/kernels/${ENV_NAME}"
if [ -d "${KERNEL_SPEC_DIR}" ]; then
    echo "⚠ Kernel already registered at ${KERNEL_SPEC_DIR}"
    echo ""
    read -p "Re-register? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting."
        exit 0
    fi
    echo "Removing existing kernel spec..."
    rm -rf "${KERNEL_SPEC_DIR}"
fi

# Register kernel
echo "Registering kernel..."
"${ENV_PATH}/bin/python" -m ipykernel install \
    --user \
    --name="${ENV_NAME}" \
    --display-name="${DISPLAY_NAME}"

# Verify registration
if [ -d "${KERNEL_SPEC_DIR}" ]; then
    echo ""
    echo "✓ Kernel registered successfully!"
    echo ""
    echo "Kernel spec location: ${KERNEL_SPEC_DIR}"
    echo ""
    echo "Contents of kernel.json:"
    echo "----------------------------------------"
    cat "${KERNEL_SPEC_DIR}/kernel.json"
    echo "----------------------------------------"
else
    echo ""
    echo "❌ Kernel registration failed"
    exit 1
fi

echo ""
echo "========================================"
echo "✓ REGISTRATION COMPLETE"
echo "========================================"
echo ""
echo "The kernel '${DISPLAY_NAME}' should now appear in JupyterLab."
echo ""
echo "To list all kernels:"
echo "  pixi run jupyter kernelspec list"
echo ""
echo "To remove this kernel later:"
echo "  rm -rf ~/.local/share/jupyter/kernels/${ENV_NAME}"
echo ""
