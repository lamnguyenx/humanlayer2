# How to Write a Dockerfile

1. **Indent commands after WORKDIR to show context**. All commands that operate within a working directory should be indented (4 spaces) to visually group them with that context.

2. **Align RUN flags vertically**. When using multiple flags in a RUN command (like `--mount`, `--network`, `--security`), place each on its own line with consistent indentation for readability.

3. **Place `&& \` at line ends for command chaining**. When chaining multiple commands, end each line with `&& \` and indent continuation lines for clarity.

4. **Use `--mount=type=cache` for package managers**. Cache package manager directories to speed up rebuilds by avoiding redundant downloads. There are two approaches: (1) **Mount to default cache locations** (preferred when known): Mount directly to the tool's well-known cache directory (e.g., `/var/cache/apt` for apt, `/root/.cache/pip` for pip, `/root/.npm` for npm). This works automatically without additional configuration. (2) **Mount to custom locations**: Use a custom mount path and configure the tool via environment variables (e.g., `PIP_CACHE_DIR`, `CONDA_PKGS_DIRS`, `UV_CACHE_DIR`) or command-line flags. You MUST ensure the tool is explicitly configured to use your custom cache directory—the mount alone is not enough.

5. **Use apt-fast with MAXNUM for parallel downloads**. Install apt-fast early and use it with `MAXNUM=8` to enable parallel package downloads, significantly reducing build time.

6. **Align pipes and redirections vertically**. When using shell pipes or redirections, indent them consistently to show the data flow clearly.

7. **Group related commands with blank lines**. Separate logical sections (system packages, application dependencies, configuration) with blank lines for better organization.

8. **Order commands for optimal layer caching**. Place less frequently changing commands (system packages) before more frequently changing ones (application code).

9. **Follow shell script formatting for RUN commands**. For shell commands within RUN instructions, find the "# How to format a shell script" guide in the file "how-to-write-an-one-example-guide.md" or the markdown file with title "# How to format a shell script" in ~/.snippets, ~/.config/opencode or local AI folders (like dot-claude, .agents..). Find it recursively and follow symlinks. If can't find the it, please wait for my next instruction.

## Example:

```dockerfile
# RULE 1: Indent commands after WORKDIR to show context
FROM ubuntu:22.04

WORKDIR /

    RUN apt-get update


# RULE 2: Align RUN flags vertically
# Multiple --mount flags
WORKDIR /

    RUN --mount=type=cache,target=/var/cache/apt \
        --mount=type=cache,target=/var/lib/apt \
        apt-get update

# Mix of different flag types
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=/tmp/requirements.txt \
    --network=none \
    pip install -r /tmp/requirements.txt

# Using --security flag
RUN --mount=type=secret,id=github_token \
    --network=default \
    git clone https://$(cat /run/secrets/github_token)@github.com/repo.git


# RULE 3: Place && \ at line ends for command chaining
WORKDIR /

    RUN --mount=type=cache,target=/var/cache/apt \
        --mount=type=cache,target=/var/lib/apt \
        apt-get update && \
        apt-get install -y \
            curl \
            git \
            python3-pip


# RULE 4: Use --mount=type=cache for package managers
# APT cache (uses mounted directories directly)
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && \
    apt-get install -y packages

# pip cache (MUST set PIP_CACHE_DIR to match cache target)
RUN --mount=type=cache,target=/tmp/pip_cache \
    PIP_CACHE_DIR=/tmp/pip_cache \
    pip install -r requirements.txt

# uv cache (MUST set UV_CACHE_DIR and PIP_CACHE_DIR to match cache target)
RUN --mount=type=cache,target=/tmp/pip_cache \
    PIP_CACHE_DIR=/tmp/pip_cache \
    UV_CACHE_DIR=/tmp/pip_cache \
    uv pip install -r requirements.txt --system

# npm cache (uses mounted directory directly)
RUN --mount=type=cache,target=/root/.npm \
    npm install

# conda cache (MUST set CONDA_PKGS_DIRS to match cache target)
RUN --mount=type=cache,target=/cache/conda \
    CONDA_PKGS_DIRS=/cache/conda \
    conda install -y -c conda-forge scipy matplotlib

# Go modules cache (set GOMODCACHE to match cache target)
RUN --mount=type=cache,target=/go/pkg/mod \
    GOMODCACHE=/go/pkg/mod \
    go build -o app


# RULE 5: Use apt-fast with MAXNUM for parallel downloads
# Install apt-fast first
RUN apt-get update && \
    apt-get install -y software-properties-common aria2 && \
    add-apt-repository -y ppa:apt-fast/stable && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-fast

# Use apt-fast with cache and parallel downloads
RUN --mount=type=cache,target=/var/cache/apt \
    apt-fast update && \
    MAXNUM=8 apt-fast install --no-install-recommends -y \
        build-essential \
        curl \
        wget

# Combine with multiple mount flags
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-fast update && \
    MAXNUM=8 apt-fast install -y python3-dev


# RULE 6: Align pipes and redirections vertically
RUN cat requirements/*.txt \
        | sort -u \
        | grep -v test \
        > requirements.txt

RUN find /app -name "*.pyc" \
        -o -name "__pycache__" \
        | xargs rm -rf


# RULE 7: Group related commands with blank lines
WORKDIR /

    RUN --mount=type=cache,target=/var/cache/apt \
        apt-fast update && \
        MAXNUM=8 apt-fast install -y \
            python3-pip \
            python3-dev

WORKDIR /app

    COPY requirements.txt .
    RUN --mount=type=cache,target=/tmp/pip_cache \
        PIP_CACHE_DIR=/tmp/pip_cache \
        pip install -r requirements.txt

    COPY . .


# RULE 8: Order commands for optimal layer caching
# System packages (changes rarely) - first
RUN --mount=type=cache,target=/var/cache/apt \
    apt-fast update && \
    MAXNUM=8 apt-fast install -y curl git

# Dependencies file (changes occasionally) - second
COPY requirements.txt .
RUN --mount=type=cache,target=/tmp/pip_cache \
    PIP_CACHE_DIR=/tmp/pip_cache \
    pip install -r requirements.txt

# Application code (changes frequently) - last
COPY . .


# COMPLETE EXAMPLE: All rules together
FROM ubuntu:22.04

# Install apt-fast for faster downloads
RUN apt-get update && \
    apt-get install -y software-properties-common aria2 && \
    add-apt-repository -y ppa:apt-fast/stable && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y apt-fast

WORKDIR /

    # Approach 1: Mount to default location (no config needed)
    RUN --mount=type=cache,target=/var/cache/apt \
        --mount=type=cache,target=/var/lib/apt \
        apt-fast update && \
        MAXNUM=8 apt-fast install --no-install-recommends -y \
            curl \
            git \
            python3-pip \
            python3-dev

WORKDIR /app

    COPY requirements.txt .

    # Approach 2: Custom location with explicit config
    RUN --mount=type=cache,target=/tmp/pip_cache \
        --mount=type=bind,source=pip.conf,target=/etc/pip.conf \
        PIP_CACHE_DIR=/tmp/pip_cache \
        pip install -r requirements.txt

    RUN cat requirements/*.txt \
            | sort -u \
            | grep -v "^#" \
            > all-requirements.txt && \
        pip install -r all-requirements.txt

    COPY . .

    RUN find . -type d -name "__pycache__" \
            -o -name "*.pyc" \
            | xargs rm -rf

CMD ["python3", "app.py"]


# RULE 9: Follow shell script formatting for RUN commands
# Complex example combining Docker indentation with shell formatting
WORKDIR /build

    RUN --mount=type=cache,target=/var/cache/apt \
        --mount=type=cache,target=/var/lib/apt \
        --mount=type=bind,source=packages.list,target=/tmp/packages.list \
        apt-fast update && \
        \
        MAXNUM=8 apt-fast install --no-install-recommends -y \
            build-essential \
            curl \
            git \
            python3-dev && \
        \
        cd /tmp && \
            curl -fsSL https://deb.nodesource.com/setup_18.x \
                | bash - && \
            apt-fast install -y nodejs && \
        \
        find /usr/share/doc -name "*.gz" \
            | xargs gunzip \
            | grep -i "license\|copyright" \
            | sort -u \
            > /tmp/licenses.txt && \
        \
        python3 -c "
import sys
with open('/tmp/packages.list') as f:
    packages = [line.strip() for line in f if line.strip()]
print('Installing packages:', ', '.join(packages))
" && \
        pip install --upgrade pip setuptools wheel

**Note**: Cache mounts require Docker BuildKit. Build with: `DOCKER_BUILDKIT=1 docker build .`
```
