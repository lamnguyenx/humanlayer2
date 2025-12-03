# OpenCode Command Integration
.PHONY: all opencode

# Default target installs OpenCode commands
all: opencode

oc: opencode
opencode:
	@bash ./bach_lite.sh archive ~/.config/opencode/command
	@mkdir -p ~/.config/opencode
	@ln -sf "$(shell pwd)/dot-claude/commands" ~/.config/opencode/command
	@bash ./bach_lite.sh echo_banner "OpenCode"
	@echo "Symlinks:"
	@bash ./show_symlinks.sh ~/.config/opencode/