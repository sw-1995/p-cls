#!/bin/bash

# Create a new feature specification

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ -z "$1" ]; then
    print_error "Usage: $0 <feature-name>"
    exit 1
fi

FEATURE_NAME="$1"
PROJECT_ROOT=$(get_project_root)
SPEC_DIR="$PROJECT_ROOT/.specify/specs"
FEATURE_FILE="$SPEC_DIR/${FEATURE_NAME}.md"

ensure_dir "$SPEC_DIR"

if file_exists "$FEATURE_FILE"; then
    print_error "Feature specification already exists: $FEATURE_FILE"
    exit 1
fi

TEMPLATE_FILE="$PROJECT_ROOT/.specify/templates/spec-template.md"

if file_exists "$TEMPLATE_FILE"; then
    cp "$TEMPLATE_FILE" "$FEATURE_FILE"
    print_success "Created feature specification from template: $FEATURE_FILE"
else
    # Create basic spec if template doesn't exist
    cat > "$FEATURE_FILE" <<EOF
# Feature: ${FEATURE_NAME}

## Overview
<!-- Brief description of the feature -->

## Requirements
<!-- List of functional requirements -->

## Technical Design
<!-- Technical approach and architecture -->

## Implementation Plan
<!-- Step-by-step implementation tasks -->

## Testing Strategy
<!-- How to test this feature -->

## Documentation
<!-- Documentation requirements -->

## Status
- [ ] Specification approved
- [ ] Implementation in progress
- [ ] Testing complete
- [ ] Documentation complete
- [ ] Feature deployed

---
Created: $(get_timestamp)
EOF
    print_success "Created feature specification: $FEATURE_FILE"
fi

print_info "Edit the specification at: $FEATURE_FILE"
