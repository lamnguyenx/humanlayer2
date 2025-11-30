# How to Write a Dockerfile

1. **Indent commands after WORKDIR to show context**. All commands that operate within a working directory should be indented (4 spaces) to visually group them with that context.

2. **Align `--mount` flags vertically**. When using multiple mount flags in a RUN command, place each on its own line with consistent indentation for readability.

3. **Place `&& \` at line ends for command chaining**. When chaining multiple commands, end each line with `&& \` and indent continuation lines for clarity.

4. **Use `--mount=type=cache` for package managers**. Cache package manager directories to speed up rebuilds by avoiding redundant downloads.

5. **Align pipes and redirections vertically**. When using shell pipes or redirections, indent them consistently to show the data flow clearly.

6. **Group related commands with blank lines**. Separate logical sections (system packages, application dependencies, configuration) with blank lines for better organization.

7. **Order commands for optimal layer caching**. Place less frequently changing commands (system packages) before more frequently changing ones (application code).

## Example:

```dockerfile
# RULE 1: Indent commands after WORKDIR to show context
FROM ubuntu:20.04

WORKDIR /

    RUN apt-get update


# RULE 2: Align --mount flags vertically
WORKDIR /

    RUN --mount=type=cache,target=/var/cache/apt \
        --mount=type=cache,target=/var/lib/apt \
        apt-get update


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
# APT cache
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && \
    apt-get install -y packages

# pip cache
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# npm cache
RUN --mount=type=cache,target=/root/.npm \
    npm install


# RULE 5: Align pipes and redirections vertically
RUN cat requirements/*.txt \
        | sort -u \
        | grep -v test \
        > requirements.txt

RUN find /app -name "*.pyc" \
        -o -name "__pycache__" \
        | xargs rm -rf


# RULE 6: Group related commands with blank lines
WORKDIR /

    RUN --mount=type=cache,target=/var/cache/apt \
        --mount=type=cache,target=/var/lib/apt \
        apt-get update && \
        apt-get install -y \
            python3-pip \
            python3-dev

WORKDIR /app

    COPY requirements.txt .
    RUN --mount=type=cache,target=/root/.cache/pip \
        pip install -r requirements.txt

    COPY . .


# RULE 7: Order commands for optimal layer caching
# System packages (changes rarely) - first
RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    apt-get update && \
    apt-get install -y curl git

# Dependencies file (changes occasionally) - second
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# Application code (changes frequently) - last
COPY . .


# COMPLETE EXAMPLE: All rules together
FROM ubuntu:20.04

WORKDIR /

    RUN --mount=type=cache,target=/var/cache/apt \
        --mount=type=cache,target=/var/lib/apt \
        apt-get update && \
        apt-get install -y \
            curl \
            git \
            python3-pip \
            python3-dev

WORKDIR /app

    COPY requirements.txt .
    RUN --mount=type=cache,target=/root/.cache/pip \
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
```