# OpenCode Command Integration
.PHONY: all opencode

# Default target installs OpenCode commands
all: opencode

opencode: ## Install Claude commands globally to OpenCode. Archives existing commands.
	@echo "Archiving existing OpenCode commands..."
	@mkdir -p ~/.config/opencode/command
	@timestamp=$$(date +%Y%m%d_%H%M%S) && \
	if [ -d ~/.config/opencode/command ] && [ "$$(ls -A ~/.config/opencode/command 2>/dev/null)" ]; then \
		mv ~/.config/opencode/command ~/.config/opencode/command-archived-at-$$timestamp; \
	fi
	@echo "Installing Claude commands globally..."
	@mkdir -p ~/.config/opencode/command
	@cp .claude/commands/*.md ~/.config/opencode/command/
	@echo "OpenCode commands installed. Run 'make opencode-clean' to restore previous commands."
	@tree ~/.config/opencode/command || true

opencode-clean: ## Restore most recent archived OpenCode commands
	@echo "Restoring most recent archived commands..."
	@latest_archive=$$(ls -td ~/.config/opencode/command-archived-at-* 2>/dev/null | head -1) && \
	if [ -n "$$latest_archive" ]; then \
		rm -rf ~/.config/opencode/command && \
		mv $$latest_archive ~/.config/opencode/command && \
		echo "Restored: $$latest_archive"; \
	else \
		echo "No archived commands found."; \
	fi
	@tree ~/.config/opencode/command || true