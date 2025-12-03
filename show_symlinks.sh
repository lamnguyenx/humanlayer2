#!/bin/bash
set -Eeuo pipefail

# Display symlink information in clean format

TARGETS=("$@")

for TARGET in "${TARGETS[@]}"; do
    ls -la "$TARGET" | awk '{print $(NF-2), $(NF-1), $NF}' | sed "s|${HOME}|~|g"
done
