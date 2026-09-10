#!/bin/bash
#
# install-git-hooks.sh
# Installs WebBLE git hooks, integrating with existing hooks if present
#

set -e

HOOKS_DIR=".git/hooks"
SOURCE_HOOKS_DIR="git-hooks"
SOURCE_HOOK="git-hooks/pre-commit"

# Ensure hooks directory exists
mkdir -p "$HOOKS_DIR"

# --------------------------------------------------------------------------------------------------
# Functions to do the work
# --------------------------------------------------------------------------------------------------
function insert_hook_file_with_markers() {
    marker_start=$1
    marker_end=$2
    source_file=$3
    target_file=$4
    # Append our hooks to the end
    echo "$marker_start" >> "$target_file"
    # Extract the actual hook content (skip shebang)
    grep -v '^#!' "$source_file" >> "$target_file"
    echo "$marker_end" >> "$target_file"
}

function install_hook() {
    marker_string=$1
    hook_name=$2

    marker_start="# @@@ $marker_string START @@@"
    marker_end="# @@@ $marker_string END @@@"

    source_file=$SOURCE_HOOKS_DIR/$hook_name
    target_file=$HOOKS_DIR/$hook_name

    # Check if target hook already exists
    if [[ -f $target_file ]]
    then
        echo "📝 Existing pre-commit hook found"

        # Check if our marker already exists
        if grep -q "$marker_start" "$target_file"; then
            echo "🔄 Updating existing WebBLE hooks..."

            # Remove old WebBLE section (portable approach using awk)
            awk -v start="$marker_start" -v end="$marker_end" '
                $0 == start { skip=1; next }
                $0 == end { skip=0; next }
                !skip { print }
            ' "$target_file" > "${target_file}.tmp" && mv "${target_file}.tmp" "$target_file"
        else
            echo "➕ Adding WebBLE hooks to existing pre-commit..."
        fi

        insert_hook_file_with_markers "$marker_start" "$marker_end" "$source_file" "$target_file"

        echo "✅ WebBLE hooks integrated with existing pre-commit hook"
    else
        echo "📦 Creating new pre-commit hook..."

        # Create new hook with markers
        cat > "$target_file" << EOF
#!/bin/sh
#
# Git $hook_name hook
#

EOF
        insert_hook_file_with_markers "$marker_start" "$marker_end" "$source_file" "$target_file"
        echo "✅ New pre-commit hook created"
    fi

    # Ensure hook is executable
    chmod +x "$target_file"

    echo "✨ Done! $hook_name hook installed at $target_file"
}

# --------------------------------------------------------------------------------------------------
# Main Script
# --------------------------------------------------------------------------------------------------
install_hook "WebBLE pre-commit hooks" "pre-commit"
