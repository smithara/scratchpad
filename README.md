## Environment setup

Create JupyterLab environment (conda):
```
mamba env create -n jlab --file jlab-environment.yml
```

Create scratchpad uv config (creates `pyproject.toml`, `uv.lock`, `.venv`):
```
uv init
uv add ipykernel sunpy hapiclient matplotlib pycdfpp
uv add --editable ../SwarmPAL ../VirES-Python-Client
```

Install the kernel (for the scratchpad environment) in userspace so that jupyter will find it:
```
uv run python -m ipykernel install --user --name scratchpad
```
(the config is located in `~/.local/share/jupyter/kernels/`)

Recreate `uv.lock`:
```
uv lock
```
Recreate `.venv`:
```
uv sync
```

## Trying JupyterLab Desktop

- Use the "Manage Python environments" tool to point to the jlab conda environment
- It doesn't see the same `.local/share/jupyter` path to get kernels (because it is in Flatpak?)
  - (you can observe this by running `jupyter --paths` from a terminal in the JupyterLab)
  - (`nb_conda_kernels` is still working and the conda kernels are there)
  - To fix, open the JupyterLab Desktop Settings, and set the environment variable: `JUPYTER_PATH= "/home/ash/.local/share/jupyter"`

## Jupyter AI

 - Get a key from, e.g. https://platform.openai.com/settings/organization/api-keys
