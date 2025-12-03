# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BeaverdownContainers is a suite of Docker containers for the Beaverdown2 bioinformatics workflow system. The containers provide reproducible environments for Snakemake workflows, R analysis, Python/Jupyter analysis, and bioinformatics toolchains. Built on Arch Linux with yay AUR helper for package management.

## Container Architecture

The containers follow a hierarchical inheritance structure:

```
beavermake (Arch Linux + Snakemake + yte)
    ↓
beaverworker (+ R + Bioinformatics tools + Conda environments)
    ↓
beaverstudio (+ RStudio Server)
beaverjupyter (+ JupyterLab)
```

### Key Containers

1. **beavermake** (`beavermake/Dockerfile`): Base container
   - Arch Linux base image
   - yay AUR helper installed under `builduser` account
   - Snakemake and yte (YAML template engine) via pipx
   - Parallel compilation configured via `makepkg.conf`

2. **beaverworker** (`beaverworker/Dockerfile`): Enhanced bioinformatics container
   - Extends beavermake
   - Installs R, bioinformatics tools (samtools, htslib, bedtools, etc.)
   - Python scientific stack (pandas, numpy, scipy)
   - Multiple Conda environments for specialized tools
   - Extensive R package installation via `pak` package manager
   - Custom tool compilation (wgbs_tools, UXM_deconv, Bismark, mHapTools)

3. **beaverstudio** (`beaverstudio/Dockerfile`): RStudio Server container
   - Extends beaverworker
   - Installs rstudio-server-bin from AUR
   - Creates user `fallingstar10` with password `fallingstar10`
   - Exposes ports 8787 (RStudio) and 8080
   - Custom startup script `/usr/local/bin/start-rstudio.sh`

4. **beaverjupyter** (`beaverjupyter/Dockerfile`): JupyterLab container
   - Extends beaverworker
   - Installs jupyterlab via pacman
   - Exposes port 8889

## Build and Development Commands

### Building Containers

**Using R scripts (primary method):**
```r
# Build all containers
source("build_image.R")

# Pull images from Docker Hub
source("pull_image.R")

# Update beaverstudio container with specific volumes/ports
source("beaverstudioUpdate.R")
```

**Using Docker directly:**
```bash
# Build individual containers
docker build -t fallingstar10/beavermake:latest ./beavermake
docker build -t fallingstar10/beaverworker:latest ./beaverworker
docker build -t fallingstar10/beaverstudio:latest ./beaverstudio
docker build -t fallingstar10/beaverjupyter:latest ./beaverjupyter
```

### Running Containers

```bash
# beavermake - interactive shell
docker run -it --name beavermake fallingstar10/beavermake:latest

# beaverworker - interactive shell
docker run -it --name beaverworker fallingstar10/beaverworker:latest

# beaverstudio - RStudio Server (access at http://localhost:8787)
docker run -p 8787:8787 -p 8080:8080 --name beaverstudio fallingstar10/beaverstudio:latest

# beaverjupyter - JupyterLab (access at http://localhost:8889)
docker run -p 8889:8889 --name beaverjupyter fallingstar10/beaverjupyter:latest
```

### CI/CD (GitHub Actions)

Weekly scheduled builds run via GitHub Actions:
- `beavermake.yml`: Fridays at 06:00 UTC
- `beaverworker.yml`: Fridays at 08:00 UTC
- `beaverstudio.yml`: Fridays at 10:00 UTC
- `beaverjupyter.yml`: Fridays at 12:00 UTC

Workflows trigger on:
- Schedule (weekly)
- Manual dispatch
- Push to `main` branch with changes to respective container directories

## Key Implementation Details

### Package Management Strategy
- **Arch Linux packages**: Installed via `pacman` with `--noconfirm` flag
- **AUR packages**: Installed via `yay` under `builduser` account with retry logic
- **Python packages**: System packages via pacman, workflow tools via `pipx`
- **R packages**: Installed via `pak` package manager with Tsinghua mirror
- **Bioinformatics tools**: Mix of AUR packages, Conda environments, and source compilation

### Build Optimization
- Parallel compilation configured in `beavermake/makepkg.conf`
- Package installation in batches with cleanup after each batch
- Retry logic for AUR package installation (3 attempts with 10s delay)
- Extensive cache cleaning to minimize image size

### User Management
- `builduser`: Low-privilege user for AUR package installation
- `fallingstar10`: Default login user in beaverstudio with sudo privileges
- `rstudio-server`: System user for RStudio Server daemon

### Environment Configuration
- Conda environments auto-activated in `.bashrc`
- PATH includes custom tool directories
- R configured to use Tsinghua CRAN mirror
- Java options set for headless operation

## Development Notes

### Recent Changes (per git status)
- `beaverstudio/Dockerfile` modified - scripts removed (`default_user.sh`, `init_set_env.sh`, `init_userconf.sh`, `install_rstudio.sh`, `install_s6init.sh`, `pam-helper.sh`)
- `beaverjupyter/Dockerfile` modified

### Claude Code Settings
- `.claude/settings.local.json` allows `Bash(find:*)` operations

### Project Structure
- RStudio project file: `BeaverdownContainers.Rproj`
- MIT License
- GitHub Actions workflows in `.github/workflows/`
- Container-specific directories: `beavermake/`, `beaverworker/`, `beaverstudio/`, `beaverjupyter/`

## Common Tasks

### Adding New Tools
1. For Arch Linux packages: Add to appropriate `pacman -S` command in Dockerfile
2. For AUR packages: Add to `yay -S` command with retry logic
3. For Conda packages: Add to `mamba create` or `conda install` commands
4. For R packages: Add to appropriate `pak::pkg_install` group
5. For source compilation: Add git clone and build steps in phase 5 of beaverworker

### Debugging Build Issues
1. Check AUR package availability and dependencies
2. Verify retry logic is working for flaky network connections
3. Check Conda channel compatibility
4. Verify R package dependencies and system library requirements

### Testing Changes
1. Build container locally: `docker build -t test-image ./container-dir`
2. Run interactive shell: `docker run -it test-image /bin/bash`
3. Test specific tools: `docker run test-image tool --version`
4. For RStudio/Jupyter: Test web interface accessibility