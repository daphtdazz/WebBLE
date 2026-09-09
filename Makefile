.PHONY: git-hooks help

# Default target
help:
	@echo "Available targets:"
	@echo "  make git-hooks  - Install Git hooks from git-hooks/ directory"
	@echo "  make help       - Show this help message"

# Install Git hooks
git-hooks: .git/hooks/pre-commit
	@echo "✅ Git hooks installed successfully!"

.git/hooks/pre-commit: git-hooks/pre-commit
	@mkdir -p .git/hooks
	@cp git-hooks/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
