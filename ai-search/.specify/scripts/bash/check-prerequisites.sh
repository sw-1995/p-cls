#!/bin/bash

# Check prerequisites for Specify workflow

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_info "Checking prerequisites for Specify workflow..."

# Check for required commands
REQUIRED_COMMANDS=("git" "node" "npm")
MISSING_COMMANDS=()

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command_exists "$cmd"; then
        MISSING_COMMANDS+=("$cmd")
    fi
done

if [ ${#MISSING_COMMANDS[@]} -gt 0 ]; then
    print_error "Missing required commands: ${MISSING_COMMANDS[*]}"
    exit 1
fi

print_success "All required commands found"

# Check if we're in a git repository
ensure_git_repo

# Check for .specify directory
PROJECT_ROOT=$(get_project_root)
SPECIFY_DIR="$PROJECT_ROOT/.specify"

if [ ! -d "$SPECIFY_DIR" ]; then
    print_error ".specify directory not found. Run 'specify init' first."
    exit 1
fi

print_success ".specify directory found"

# Check for required directories
REQUIRED_DIRS=(
    "$SPECIFY_DIR/memory"
    "$SPECIFY_DIR/scripts"
    "$SPECIFY_DIR/templates"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        print_warning "Directory not found: $dir"
    else
        print_success "Found: $dir"
    fi
done

print_success "Prerequisites check completed"
