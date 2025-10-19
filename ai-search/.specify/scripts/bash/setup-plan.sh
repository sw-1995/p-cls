#!/bin/bash

# Setup a new plan for a feature or task

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ -z "$1" ]; then
    print_error "Usage: $0 <plan-name>"
    exit 1
fi

PLAN_NAME="$1"
PROJECT_ROOT=$(get_project_root)
PLAN_DIR="$PROJECT_ROOT/.specify/plans"
PLAN_FILE="$PLAN_DIR/${PLAN_NAME}.md"

ensure_dir "$PLAN_DIR"

if file_exists "$PLAN_FILE"; then
    print_warning "Plan already exists: $PLAN_FILE"
    if ! confirm "Do you want to overwrite it?"; then
        print_info "Aborted"
        exit 0
    fi
fi

TEMPLATE_FILE="$PROJECT_ROOT/.specify/templates/plan-template.md"

if file_exists "$TEMPLATE_FILE"; then
    cp "$TEMPLATE_FILE" "$PLAN_FILE"
    print_success "Created plan from template: $PLAN_FILE"
else
    # Create basic plan if template doesn't exist
    cat > "$PLAN_FILE" <<EOF
# Plan: ${PLAN_NAME}

## Objective
<!-- What are we trying to achieve? -->

## Context
<!-- Background information and current state -->

## Approach
<!-- High-level strategy -->

## Tasks
<!-- Detailed task breakdown -->

1. [ ] Task 1
2. [ ] Task 2
3. [ ] Task 3

## Dependencies
<!-- What needs to be in place first? -->

## Success Criteria
<!-- How do we know when we're done? -->

## Timeline
<!-- Estimated completion time -->

## Notes
<!-- Additional considerations -->

---
Created: $(get_timestamp)
Status: Planning
EOF
    print_success "Created plan: $PLAN_FILE"
fi

print_info "Edit the plan at: $PLAN_FILE"
