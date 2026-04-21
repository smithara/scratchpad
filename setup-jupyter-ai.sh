#!/bin/bash
# Setup script for Jupyter AI with Anthropic Claude

set -e

echo "🤖 Setting up Jupyter AI with Anthropic Claude..."
echo

# Load environment variables from .env if it exists
if [ -f .env ]; then
    echo "✓ Loading ANTHROPIC_API_KEY from .env..."
    export $(grep -v '^#' .env | grep ANTHROPIC_API_KEY | xargs)
else
    echo "⚠ Warning: .env file not found"
    echo "  Please create a .env file with your ANTHROPIC_API_KEY"
    exit 1
fi

# Check if API key is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ Error: ANTHROPIC_API_KEY not found in .env file"
    echo "   Please add your Anthropic API key to .env:"
    echo "   ANTHROPIC_API_KEY=sk-ant-api03-..."
    exit 1
fi

# Get Jupyter config directory
JUPYTER_CONFIG_DIR=$(jupyter --config-dir 2>/dev/null || echo "$HOME/.jupyter")
echo "✓ Jupyter config directory: $JUPYTER_CONFIG_DIR"

# Create config directory if it doesn't exist
mkdir -p "$JUPYTER_CONFIG_DIR"

# Copy Jupyter AI config file
CONFIG_FILE="$JUPYTER_CONFIG_DIR/jupyter_jupyter_ai_config.json"
echo "✓ Installing Jupyter AI config to: $CONFIG_FILE"

# Create the config with API key from environment
cat > "$CONFIG_FILE" << EOF
{
  "embeddings_provider_id": null,
  "api_keys": {
    "ANTHROPIC_API_KEY": "$ANTHROPIC_API_KEY"
  },
  "send_with_shift_enter": false
}
EOF

# Replace $ANTHROPIC_API_KEY with actual value
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/\$ANTHROPIC_API_KEY/$ANTHROPIC_API_KEY/g" "$CONFIG_FILE"
else
    # Linux
    sed -i "s/\$ANTHROPIC_API_KEY/$ANTHROPIC_API_KEY/g" "$CONFIG_FILE"
fi

echo "✓ Configuration file created successfully"
echo

# Verify langchain-anthropic is installed
if pixi run python -c "import langchain_anthropic" 2>/dev/null; then
    echo "✓ langchain-anthropic is installed"
else
    echo "⚠ Warning: langchain-anthropic not found"
    echo "  Installing langchain-anthropic..."
    pixi run pip install langchain-anthropic
fi

echo
echo "✅ Setup complete!"
echo
echo "📋 Configuration Summary:"
echo "  - API key: ${ANTHROPIC_API_KEY:0:20}... (from .env)"
echo "  - Config file: $CONFIG_FILE"
echo
echo "🚀 Next steps:"
echo "  1. Start JupyterLab: pixi run jlab"
echo "  2. Open the Jupyter AI chat panel (left sidebar)"
echo "  3. Select a model from the dropdown"
echo
