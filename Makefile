.PHONY: git-hooks help

# Default target
help:
	@echo "Available targets:"
	@echo "  make git-hooks      - Alias for install-hooks"
	@echo "  make help           - Show this help message"

# Install Git hooks (intelligently integrates with existing hooks)
git-hooks: git-hooks/* git-hooks/install-git-hooks.sh
	@bash git-hooks/install-git-hooks.sh
