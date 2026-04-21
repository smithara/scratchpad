## Environment setup

This project uses **two package managers**:
- **Pixi** manages the JupyterLab environment
- **UV** manages the scratchpad environment for analysis tools

### Quick setup

```bash
pixi run setup-all
```

This runs all setup tasks:
- Installs scratchpad dependencies (UV)
- Extracts VRE Docker environment
- Configures Jupyter AI with Claude

### Manual setup

If you prefer to set up individually:

```bash
pixi run setup-scratchpad   # Install UV packages
pixi run setup-vre          # Extract VRE Docker environment
pixi run setup-ai           # Configure Jupyter AI
```

## Launching JupyterLab

```bash
pixi run jlab
```

When you launch JupyterLab this way:
- **VRE container** (if podman/docker available): Automatically started in the background—ready for notebook kernels
- **JupyterLab server**: Started on localhost:8888
- **Browser**: Opens in Chromium app mode
- **Cleanup**: When you close the browser, both JupyterLab and the VRE container are automatically stopped

### Docker Registry Authentication

If you need to authenticate with the Docker registry (e.g., for private images):

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your credentials:
   ```bash
   VRE_REGISTRY_USERNAME=your_username
   VRE_REGISTRY_PASSWORD=your_password
   VRE_REGISTRY_URL=registry.gitlab.eox.at
   ```

3. The credentials will be automatically loaded and used when you run `pixi run jlab`

**Note**: The `.env` file is in `.gitignore` and will never be committed to git.

## Available Kernels

### Scratchpad Kernel
- **Name**: `scratchpad`
- **Python**: From UV environment in this workspace
- **Use case**: Local analysis with workspace packages

### VRE Docker Kernel
- **Name**: `vre-docker`
- **Container**: `registry.gitlab.eox.at/esa/vires_vre_ops/vre-swarm-notebook:1.0.11`
- **Use case**: Full VRE environment with additional scientific packages
- **Requirements**: podman or docker must be available
- **Note**: Notebooks run inside the Docker container; workspace files are mounted at `/home/jovyan/code`
- **How it works**: The kernel launcher automatically discovers the workspace location by looking for `pixi.toml`, making it portable across systems. Set `SCRATCHPAD_ROOT` environment variable if needed.

## Update dependencies

```bash
pixi run setup-scratchpad
```

Or manually:
```bash
uv lock && uv sync
``` 

## Jupyter AI with Anthropic Claude

This workspace includes Jupyter AI configured to work with Anthropic's Claude models.

1. Get an API key from the [Anthropic Console](https://console.anthropic.com/) and add it to `.env`:
   ```bash
   ANTHROPIC_API_KEY=sk-ant-api03-your-key-here
   ```
2. Run `pixi run setup-ai` — writes `~/.jupyter/jupyter_jupyter_ai_config.json` with your key.
3. Launch `pixi run jlab`, open the **chat panel** (left sidebar), and pick a model from the dropdown (provider: `anthropic-chat`).

To see which models your key can access:

```bash
curl -s https://api.anthropic.com/v1/models \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01"
```
