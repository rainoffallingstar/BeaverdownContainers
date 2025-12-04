# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BeaverdownContainers is a suite of Docker containers for the Beaverdown2 bioinformatics workflow system. The containers provide reproducible environments for Snakemake workflows, R analysis, Python/Jupyter analysis, and bioinformatics toolchains. Built on Arch Linux with yay AUR helper for package management.

**Target Users**: Bioinformatics researchers, data scientists, and computational biologists working with genomics data.

**Supported Analysis Types**:
- **WGBS (Whole-Genome Bisulfite Sequencing)**: Methylation analysis with Bismark, wgbs_tools
- **RNA-seq**: Transcriptomic analysis with STAR, htseq, rmats
- **Single-cell analysis**: Seurat (R) and Scanpy (Python) workflows
- **Genomics**: General analysis with samtools, bedtools, GATK
- **Epigenomics**: Specialized tools for methylation and chromatin analysis

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

   **Conda Environments**:
   - `py27`: Python 2.7 environment for legacy tools
   - `pyfastx`: Fastx toolkit for sequence analysis
   - `clubcpg`: CpG island analysis tools
   - `multiqc`: Quality control report aggregation
   - `star`: RNA-seq alignment tool
   - `htseq`: Feature counting for RNA-seq
   - `rmats`: Alternative splicing analysis
   - `bwtool`: BigWig file analysis
   - `scanpy`: Single-cell analysis (Python)

   **R Package Groups**:
   - Group 1: Shiny ecosystem (DT, shinyWidgets, shiny, bslib)
   - Group 2: Statistics and visualization (plotly, pROC, sva, tidyverse)
   - Group 3: Bioinformatics core (Rsamtools, rtracklayer, GenomicRanges)
   - Group 4: Enrichment analysis (clusterProfiler, org.Hs.eg.db, KEGGREST)
   - Group 5: Advanced analysis (NOISeq, reticulate, TCGAbiolinks, Seurat)
   - Group 6: Machine learning (mlr3verse)

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
# Requires dockerR package: install.packages("dockerR")

# Build all containers locally
source("build_image.R")

# Pull pre-built images from Docker Hub
source("pull_image.R")

# Development-specific beaverstudio setup (modify paths for your environment)
source("beaverstudioUpdate.R")  # Note: Contains Windows paths, customize for your setup
```

**Using Docker directly:**
```bash
# Build individual containers
docker build -t fallingstar10/beavermake:latest ./beavermake
docker build -t fallingstar10/beaverworker:latest ./beaverworker
docker build -t fallingstar10/beaverstudio:latest ./beaverstudio
docker build -t fallingstar10/beaverjupyter:latest ./beaverjupyter

# Build with build caching for faster iteration
docker buildx build -t fallingstar10/beaverworker:latest ./beaverworker --cache-from type=local,src=/tmp/.buildx-cache --cache-to type=local,dest=/tmp/.buildx-cache
```

### Testing Containers

```bash
# Test container builds
docker run --rm fallingstar10/beavermake:latest snakemake --version
docker run --rm fallingstar10/beaverworker:latest R --version
docker run --rm fallingstar10/beaverworker:latest python --version
docker run --rm fallingstar10/beaverworker:latest samtools --version

# Test web interfaces (check accessibility)
curl -f http://localhost:8787  # RStudio
curl -f http://localhost:8889  # JupyterLab

# Check container logs
docker logs beaverstudio
docker logs beaverjupyter
```

### Development Environment Setup

```bash
# Development-specific volume mounting
docker run -p 8787:8787 -p 8080:8080 \
  -v /path/to/workspace:/home/builduser \
  -v /path/to/fonts:/etc/rstudio/fonts \
  --name beaverstudio-dev fallingstar10/beaverstudio:latest

# Interactive development with shell access
docker run -it --entrypoint /bin/bash fallingstar10/beaverworker:latest
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
- `beaverstudio/Dockerfile` modified - Enhanced with:
  - Node.js and npm packages installation
  - Claude Code CLI tools integration
  - Improved user management with `getent` pattern
  - Enhanced PAM configuration for RStudio
  - Optimized startup script with better directory management
  - Explicit volume management for `/var/lib/rstudio-server`
  - Removed legacy scripts: `default_user.sh`, `init_set_env.sh`, `init_userconf.sh`, `install_rstudio.sh`, `install_s6init.sh`, `pam-helper.sh`
- `beaverjupyter/Dockerfile` modified

### Claude Code Settings
- `.claude/settings.local.json` allows operations:
  - `Bash(find:*)` - File searching and directory operations
  - `Bash(git add:*)` - Git staging operations
  - `Bash(git commit:*)` - Git commit operations
  - `Bash(git push:*)` - Git push operations
  - `Bash(ls:*)` - Directory listing operations

### Critical File Paths

#### Configuration Files
- `beavermake/makepkg.conf` - Parallel compilation configuration
- `.claude/settings.local.json` - Claude Code permissions
- `BeaverdownContainers.Rproj` - RStudio project configuration

#### Build Scripts
- `build_image.R` - Primary container build script using dockerR
- `pull_image.R` - Pull pre-built images from Docker Hub
- `beaverstudioUpdate.R` - Development-specific beaverstudio setup (customize paths)
- `ADD_USER.R` - Shell script for adding users to containers

#### CI/CD Configuration
- `.github/workflows/beavermake.yml` - Friday 06:00 UTC builds
- `.github/workflows/beaverworker.yml` - Friday 08:00 UTC builds
- `.github/workflows/beaverstudio.yml` - Friday 10:00 UTC builds
- `.github/workflows/beaverjupyter.yml` - Friday 12:00 UTC builds

#### Container Entrypoints
- `/usr/local/bin/start-rstudio.sh` - RStudio Server startup script (beaverstudio)
- `.bashrc` - Conda environment activation and PATH configuration (beaverworker)

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

## Development Workflow

### Step-by-Step Development Process

#### 1. Initial Setup
```bash
# Clone repository and navigate to project
git clone https://github.com/rainoffallingstar/BeaverdownContainers.git
cd BeaverdownContainers

# Install R package dependencies (if using R scripts)
R -e "install.packages('dockerR')"
```

#### 2. Local Development Workflow
```r
# Option 1: Use R scripts for container management
source("build_image.R")    # Build all containers locally
source("pull_image.R")     # Pull latest pre-built images

# Option 2: Build specific container
docker build -t test-beaverworker ./beaverworker
```

#### 3. Making Changes to Containers
1. **Modify Dockerfile**: Edit the appropriate container's Dockerfile
2. **Test locally**: Build and test the specific container
3. **Validate tools**: Ensure installed tools work correctly
4. **Commit changes**: Push to repository for CI/CD build

#### 4. Testing and Validation
```bash
# Quick validation of key tools
docker run --rm test-beaverworker snakemake --version
docker run --rm test-beaverworker R --version
docker run --rm test-beaverworker samtools --version

# Test interactive functionality
docker run -it test-beaverworker /bin/bash
# Inside container: test conda environments, R packages, etc.
```

#### 5. Debugging Build Issues
```bash
# Build with verbose output
docker build --progress=plain -t debug-image ./beaverworker

# Run interactive debugging session
docker run -it --entrypoint /bin/bash debug-image

# Check logs for running containers
docker logs container-name
```

### CI/CD Integration

#### GitHub Actions Workflows
- **Location**: `.github/workflows/`
- **Schedule**: Weekly builds (Fridays at staggered times)
- **Triggers**: Schedule, manual dispatch, directory-specific pushes
- **Authentication**: Uses Docker Hub secrets for image publishing

#### Manual CI/CD Trigger
```bash
# Force rebuild via GitHub Actions
# 1. Make small change to container directory
# 2. Push to main branch
# 3. Monitor workflow progress in GitHub Actions tab
```

### Environment-Specific Configurations

#### Windows Development
- `beaverstudioUpdate.R` contains Windows paths (`/d/beaver`, `/d/fonts-main`)
- Modify paths based on your development environment
- Consider using WSL2 for better Docker performance

#### Linux/macOS Development
- Adapt volume mount paths in development scripts
- Use native Docker without WSL overhead
- Leverage Unix permissions model for file sharing

### Package Management Strategy

#### AUR Package Installation
```bash
# In beaverworker Dockerfile - pattern for AUR packages
yay -S --noconfirm package-name || \
  { sleep 10 && yay -S --noconfirm package-name; } || \
  { sleep 10 && yay -S --noconfirm package-name; }
```

#### R Package Groups
- Packages installed in logical groups to prevent cascading failures
- Uses `pak::pkg_install()` with Tsinghua mirror for faster downloads
- Each group isolated to prevent one failure from stopping entire installation

#### Conda Environment Management
- Uses `mamba` for faster package installation
- Multiple isolated environments for different analysis types
- Environment activation configured in `.bashrc`