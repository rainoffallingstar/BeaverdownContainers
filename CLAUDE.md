# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BeaverdownContainers is a **simplified** suite of Docker containers for the Beaverdown2 bioinformatics workflow system. The project has been streamlined from 4 containers to 2, providing a unified development environment with multi-language support.

**Target Users**: Bioinformatics researchers, data scientists, and computational biologists working with genomics data.

**Design Philosophy**: Provide lightweight base environments with flexible tool installation via micromamba/yay/pak/cargo/npm, supporting multi-language development (Python, R, Rust, Node.js, Go).

**Container Architecture**:
```
beavermake (Arch Linux + Python + R + micromamba + yay + rustup + Node.js + npm + Go)
    ↓
beaverworker (R packages + JupyterLab + SSH + Claude Code + fallingstar10 user)
```

---

## Container Architecture

The containers follow a hierarchical inheritance structure:

```
archlinux:latest
    ↓
beavermake (Base: Python 3, R, pak, micromamba, yay, rustup, Node.js, npm, Go)
    ↓
beaverworker (R packages, JupyterLab, SSH, Claude Code, fallingstar10 user)
```

### Key Containers

#### 1. **beavermake** (`beavermake/Dockerfile`): Base container

**Purpose**: Lightweight base environment with multi-language support

**Components**:
- **Base**: Arch Linux with parallel compilation (`makepkg.conf`)
- **User**: `builduser` for AUR package installation
- **Package Managers**:
  - `yay` (AUR helper, installed under `builduser`)
  - `pak` (R package manager)
  - `micromamba` (lightweight Conda alternative)
  - `pip` (Python)
  - `cargo` (Rust)
  - `npm` (Node.js)
  - `go mod` (Go)

**Programming Languages**:
- **Python 3**: System package via pacman
- **R**: System package via pacman
- **Rust**: Installed via rustup (latest stable)
- **Node.js**: System package via pacman
- **Go**: System package via pacman

**Environment Configuration**:
```bash
# PATH includes:
/opt/micromamba/bin:/root/.cargo/bin:/root/.local/bin:/root/go/bin

# For builduser:
export PATH=/opt/micromamba/bin:$HOME/.cargo/bin:$HOME/go/bin:$PATH
export GOPATH=$HOME/go
```

---

#### 2. **beaverworker** (`beaverworker/Dockerfile`): Unified workspace

**Purpose**: Complete development environment with R packages, JupyterLab, SSH, and Claude Code

**Inherits**: `fallingstar10/beavermake:latest`

**Components**:

**R Packages (6 groups, 40+ packages)**:
- **Group 1**: Shiny ecosystem (DT, shinyWidgets, shiny, bslib)
- **Group 2**: Statistics and visualization (plotly, pROC, tidyverse)
- **Group 3**: Bioinformatics core (Rsamtools, rtracklayer, GenomicRanges)
- **Group 4**: Enrichment analysis (clusterProfiler, org.Hs.eg.db, KEGGREST)
- **Group 5**: Advanced analysis (NOISeq, TCGAbiolinks, Seurat)
- **Group 6**: Machine learning (mlr3verse)

**Services**:
- **JupyterLab**: Port 8889
- **SSH**: Port 2222
- **Reserved ports**: 8080, 8787 (available for other services)

**User Management**:
- **fallingstar10**: Default user (password: fallingstar10)
- **Sudo access**: Full sudo privileges
- **SSH access**: Configured with password and key authentication

**Global Tools**:
- **Claude Code CLI**: Installed globally via npm

**Environment Configuration**:
```bash
# PATH includes all tools:
/opt/micromamba/bin:/home/fallingstar10/.cargo/bin:/home/fallingstar10/.local/bin:/home/fallingstar10/go/bin:/root/.cargo/bin:/root/.local/bin:/root/go/bin:$PATH

# Environment variables:
GOPATH=/home/fallingstar10/go
NODE_PATH=/home/fallingstar10/.local/lib/node_modules:/root/.local/lib/node_modules
```

**Bash Configuration**:
- **root**: Full PATH with all tools
- **fallingstar10**: Full PATH but Rust not auto-initialized (manual `source ~/.cargo/env` required)

**Startup Script**: `/usr/local/bin/start-services.sh`
- Generates SSH host keys
- Starts SSH daemon
- Starts JupyterLab as fallingstar10 user
- Displays connection information

---

## Build and Development Commands

### Building Containers

**Using R scripts**:
```r
# Requires dockerR package
source("build_image.R")  # Build all containers
source("pull_image.R")   # Pull pre-built images
```

**Using Docker directly**:
```bash
# Build beavermake
docker build -t fallingstar10/beavermake:latest ./beavermake

# Build beaverworker
docker build -t fallingstar10/beaverworker:latest ./beaverworker
```

### Running Containers

```bash
# beavermake - interactive shell (base environment)
docker run -it --name beavermake fallingstar10/beavermake:latest

# beaverworker - full workspace (recommended)
docker run -p 2222:2222 -p 8889:8889 -p 8080:8080 -p 8787:8787 \
  --name beaverworker fallingstar10/beaverworker:latest
```

### Accessing Services

- **JupyterLab**: http://localhost:8889
- **SSH**: `ssh fallingstar10@localhost -p 2222` (password: fallingstar10)
- **Reserved ports**: 8080, 8787 (available for Shiny or other services)

---

## Environment Variables

### beavermake

```bash
PATH=/opt/micromamba/bin:/root/.cargo/bin:/root/.local/bin:/root/go/bin:$PATH
GOPATH=/root/go
```

### beaverworker

```bash
PATH=/opt/micromamba/bin:/home/fallingstar10/.cargo/bin:/home/fallingstar10/.local/bin:/home/fallingstar10/go/bin:/root/.cargo/bin:/root/.local/bin:/root/go/bin:$PATH
GOPATH=/home/fallingstar10/go
NODE_PATH=/home/fallingstar10/.local/lib/node_modules:/root/.local/lib/node_modules
CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
JAVA_OPTS="-Djava.awt.headless=true"
R_PROGRESSR_ENABLE=TRUE
LANG=C.UTF-8
```

---

## Package Management

### Python Packages

**Via micromamba** (recommended):
```bash
micromamba install pandas numpy scipy -y
micromamba install -c bioconda samtools -y
```

**Via pip**:
```bash
pip install package-name
```

### R Packages

**Via pak** (recommended):
```bash
R -e "pak::pkg_install('package-name')"
```

**From GitHub**:
```bash
R -e "pak::pak('username/repo')"
```

### Arch/AUR Packages

**Via yay** (as builduser):
```bash
sudo -u builduser yay -S package-name
```

**Via pacman** (as root):
```bash
pacman -S package-name
```

### Rust Tools

**Via cargo**:
```bash
# First, initialize Rust environment (for fallingstar10 user)
source ~/.cargo/env

# Install tools
cargo install ripgrep  # rg - faster grep
cargo install fd-find  # fd - faster find
cargo install bat      # bat - cat with syntax highlighting
cargo install starship # cross-shell prompt
```

### Node.js Packages

**Via npm** (global):
```bash
npm install -g package-name

# Examples:
npm install -g typescript
npm install -g prettier
npm install -g yarn
npm install -g pnpm
```

### Go Tools

**Via go install**:
```bash
go install golang.org/x/tools/...@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

---

## CI/CD (GitHub Actions)

### Workflows

**Location**: `.github/workflows/`

**Active Workflows**:
- `beavermake.yml`: Fridays at 06:00 UTC
- `beaverworker.yml`: Fridays at 08:00 UTC

**Deprecated Workflows** (moved to `.depress/`):
- `beaverstudio.yml` (removed)
- `beaverjupyter.yml` (removed)

**Triggers**:
- Schedule (weekly)
- Manual dispatch (`workflow_dispatch`)
- Push to `main` branch with changes to respective directories

**Authentication**: Uses Docker Hub secrets for image publishing

---

## Common Development Tasks

### Installing Bioinformatics Tools

```bash
# Enter container
docker exec -it beaverworker /bin/bash

# Install samtools via micromamba
micromamba install -c bioconda samtools -y

# Install bowtie2 via yay
sudo -u builduser yay -S bowtie2-bin

# Install R packages via pak
R -e "pak::pkg_install('BiocParallel')"
```

### Using Claude Code

```bash
# Claude Code is globally installed
claude-code

# Or use the shorter alias
cc
```

### Rust Development

```bash
# Initialize Rust environment (fallingstar10 user only)
source ~/.cargo/env

# Create new project
cargo new myproject
cd myproject
cargo build
cargo run
```

### Node.js Development

```bash
# Initialize project
npm init -y

# Install dependencies
npm install express

# Install global tools
npm install -g typescript prettier
```

### Go Development

```bash
# Create project
mkdir myproject && cd myproject
go mod init myproject

# Run program
go run main.go
```

---

## Directory Structure

```
BeaverdownContainers/
├── beavermake/
│   ├── Dockerfile          # Base container
│   └── makepkg.conf        # Parallel compilation config
├── beaverworker/
│   └── Dockerfile          # Unified workspace
├── .depress/               # Backup of deprecated containers
│   ├── beaverstudio/
│   ├── beaverjupyter/
│   ├── beaverstudio.yml
│   └── beaverjupyter.yml
├── .github/workflows/
│   ├── beavermake.yml      # CI/CD for beavermake
│   └── beaverworker.yml    # CI/CD for beaverworker
├── build_image.R           # R script to build containers
├── pull_image.R            # R script to pull images
├── README.md               # User-facing documentation
├── CLAUDE.md               # This file
└── ADD_USER.sh             # User management script
```

---

## Key Implementation Details

### Package Management Strategy

- **Arch packages**: Installed via `pacman` with `--noconfirm` flag
- **AUR packages**: Installed via `yay` under `builduser` account
- **Python packages**: Via `micromamba` (recommended) or `pip`
- **R packages**: Via `pak` with Tsinghua mirror
- **Rust tools**: Via `cargo`
- **Node.js tools**: Via `npm`
- **Go tools**: Via `go install`

### Build Optimization

- Parallel compilation configured in `beavermake/makepkg.conf`
- Package installation in batches to reduce cascading failures
- Cache cleaning to minimize image size
- CRAN and npm mirrors configured for faster downloads

### User Management

- **builduser**: Low-privilege user for AUR package installation
- **fallingstar10**: Default login user in beaverworker with sudo privileges
- **root**: System administration

### Environment Configuration

- Conda/micromamba environment configured in `.bashrc`
- PATH includes custom tool directories
- R configured to use Tsinghua CRAN mirror
- Go workspace configured via GOPATH

---

## Important Notes

### Rust Environment

**fallingstar10 user does NOT auto-initialize Rust**. Users must manually run:
```bash
source ~/.cargo/env
```

This is intentional to keep the shell startup fast and allow users to initialize Rust only when needed.

### Reserved Ports

- **8080**: Available for Shiny apps or other R web services
- **8787**: Available for other services (previously RStudio)

### Backup

Deprecated containers are backed up in `.depress/` directory for reference:
- `beaverstudio/` (RStudio Server)
- `beaverjupyter/` (JupyterLab only - now integrated into beaverworker)

---

## Development Workflow

### Step-by-Step Development Process

1. **Local Development**
   ```bash
   # Build containers locally
   docker build -t test-beavermake ./beavermake
   docker build -t test-beaverworker ./beaverworker
   ```

2. **Testing**
   ```bash
   # Test beavermake
   docker run --rm test-beavermake python --version
   docker run --rm test-beavermake R --version
   docker run --rm test-beavermake go version

   # Test beaverworker
   docker run -p 2222:2222 -p 8889:8889 --name test-worker test-beaverworker
   ```

3. **Making Changes**
   - Modify Dockerfiles
   - Test locally
   - Commit changes
   - Push to repository (triggers CI/CD)

---

## Troubleshooting

### Build Issues

- **AUR package installation fails**: Check network connection, AUR package availability
- **R package installation fails**: Verify system dependencies, check CRAN mirror
- **Out of space**: Clean Docker cache: `docker system prune -a`

### Runtime Issues

- **Port conflicts**: Check with `netstat -tulpn | grep <port>`
- **Container won't start**: Check logs with `docker logs <container>`
- **SSH connection refused**: Verify SSH service is running inside container

---

## License

MIT License - See LICENSE file for details.
