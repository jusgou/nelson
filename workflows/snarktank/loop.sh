#!/bin/bash
# Nelson Loop - Long-running AI agent loop with multi-PRD support
# Usage: ./loop.sh [--tool amp|claude] [max_iterations]
#
# Multi-PRD Support:
#   - Supports multiple PRD files: prd.json, prd-2.json, prd-3.json, etc.
#   - Automatically finds the first incomplete PRD
#   - Generates completion documents when a PRD finishes
#   - Passes completion context to the agent for continuity

set -e

# Parse arguments
TOOL="claude"  # Default to claude
MAX_ITERATIONS=10

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    *)
      # Assume it's max_iterations if it's a number
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

# Validate tool choice
if [[ "$TOOL" != "amp" && "$TOOL" != "claude" ]]; then
  echo "Error: Invalid tool '$TOOL'. Must be 'amp' or 'claude'."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
COMPLETIONS_DIR="$SCRIPT_DIR/completions"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Find all PRD files in order: prd.json, prd-2.json, prd-3.json, etc.
find_prd_files() {
  local files=()

  # First check for prd.json (primary)
  if [ -f "$SCRIPT_DIR/prd.json" ]; then
    files+=("$SCRIPT_DIR/prd.json")
  fi

  # Then find numbered PRDs: prd-2.json, prd-3.json, etc.
  for f in "$SCRIPT_DIR"/prd-[0-9]*.json; do
    if [ -f "$f" ]; then
      files+=("$f")
    fi
  done

  # Sort by number (prd.json first, then prd-2, prd-3, etc.)
  printf '%s\n' "${files[@]}" | sort -t'-' -k2 -n
}

# Check if a PRD is complete (all stories pass)
is_prd_complete() {
  local prd_file="$1"
  local incomplete_count=$(jq '[.userStories[] | select(.passes == false)] | length' "$prd_file" 2>/dev/null || echo "999")
  [ "$incomplete_count" -eq 0 ]
}

# Get PRD display name
get_prd_name() {
  local prd_file="$1"
  basename "$prd_file" .json
}

# Find the active (first incomplete) PRD
find_active_prd() {
  local prd_files=$(find_prd_files)

  for prd_file in $prd_files; do
    if ! is_prd_complete "$prd_file"; then
      echo "$prd_file"
      return 0
    fi
  done

  # All PRDs complete or no PRDs found
  echo ""
}

# Generate completion document for a finished PRD
generate_completion_doc() {
  local prd_file="$1"
  local prd_name=$(get_prd_name "$prd_file")
  local timestamp=$(date +%Y-%m-%d-%H%M%S)

  mkdir -p "$COMPLETIONS_DIR"

  local completion_file="$COMPLETIONS_DIR/${prd_name}-complete-${timestamp}.md"

  cat > "$completion_file" << EOF
# PRD Completion Report: $prd_name
Generated: $(date)

## Project Information
$(jq -r '"**Project**: \(.project // "N/A")\n**Branch**: \(.branchName // "N/A")\n**Description**: \(.description // "N/A")"' "$prd_file")

## Completed User Stories

$(jq -r '.userStories[] | "### \(.id): \(.title)\n**Priority**: \(.priority)\n**Notes**: \(.notes // "None")\n\n**Acceptance Criteria**:\n" + (.acceptanceCriteria | map("- " + .) | join("\n")) + "\n"' "$prd_file")

## Summary
- Total Stories: $(jq '.userStories | length' "$prd_file")
- All stories completed successfully
- PRD marked as complete at: $(date)

---
*This completion document can be referenced by future PRDs for context.*
EOF

  echo "$completion_file"
}

# Build context from previous completion documents
build_completion_context() {
  local context=""

  if [ -d "$COMPLETIONS_DIR" ] && [ "$(ls -A "$COMPLETIONS_DIR" 2>/dev/null)" ]; then
    context="\n## Previous PRD Completions (for context)\n\n"
    context+="The following PRDs have been completed previously. Review them for context about what has been built:\n\n"

    for completion_file in "$COMPLETIONS_DIR"/*-complete-*.md; do
      if [ -f "$completion_file" ]; then
        local filename=$(basename "$completion_file")
        context+="### $(echo "$filename" | sed 's/-complete-.*\.md//')\n"
        context+="See: .nelson/completions/$filename\n\n"
      fi
    done
  fi

  echo -e "$context"
}

# Archive previous run if branch changed
archive_if_branch_changed() {
  local prd_file="$1"

  if [ -f "$prd_file" ] && [ -f "$LAST_BRANCH_FILE" ]; then
    local current_branch=$(jq -r '.branchName // empty' "$prd_file" 2>/dev/null || echo "")
    local last_branch=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

    if [ -n "$current_branch" ] && [ -n "$last_branch" ] && [ "$current_branch" != "$last_branch" ]; then
      local date=$(date +%Y-%m-%d)
      local folder_name=$(echo "$last_branch" | sed 's|^nelson/||')
      local archive_folder="$ARCHIVE_DIR/$date-$folder_name"

      echo -e "${YELLOW}→${NC} Archiving previous run: $last_branch"
      mkdir -p "$archive_folder"
      [ -f "$prd_file" ] && cp "$prd_file" "$archive_folder/"
      [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$archive_folder/"
      echo "   Archived to: $archive_folder"

      # Reset progress file for new run
      echo "# Nelson Progress Log" > "$PROGRESS_FILE"
      echo "Started: $(date)" >> "$PROGRESS_FILE"
      echo "---" >> "$PROGRESS_FILE"
    fi
  fi
}

# Initialize progress file if needed
init_progress_file() {
  if [ ! -f "$PROGRESS_FILE" ]; then
    echo "# Nelson Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
}

# ============================================================
# MAIN EXECUTION
# ============================================================

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  Nelson Loop - Multi-PRD Autonomous Development         ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Find active PRD
ACTIVE_PRD=$(find_active_prd)

if [ -z "$ACTIVE_PRD" ]; then
  # Check if there are any PRD files at all
  if [ ! -f "$SCRIPT_DIR/prd.json" ]; then
    echo -e "${YELLOW}!${NC} No PRD files found in $SCRIPT_DIR"
    echo ""
    echo "Create a PRD file using:"
    echo "  nelson-prd-generator"
    echo ""
    echo "Or manually create .nelson/prd.json"
    exit 1
  else
    echo -e "${GREEN}✓${NC} All PRD files are complete!"
    echo ""
    echo "To create a new PRD, use:"
    echo "  nelson-prd-generator .nelson/prd-2.json"
    exit 0
  fi
fi

PRD_NAME=$(get_prd_name "$ACTIVE_PRD")
echo -e "${BLUE}→${NC} Active PRD: $PRD_NAME"
echo -e "${BLUE}→${NC} Tool: $TOOL"
echo -e "${BLUE}→${NC} Max iterations: $MAX_ITERATIONS"

# Show PRD summary
TOTAL_STORIES=$(jq '.userStories | length' "$ACTIVE_PRD")
COMPLETE_STORIES=$(jq '[.userStories[] | select(.passes == true)] | length' "$ACTIVE_PRD")
echo -e "${BLUE}→${NC} Progress: $COMPLETE_STORIES / $TOTAL_STORIES stories complete"
echo ""

# Check for previous completions
COMPLETION_CONTEXT=$(build_completion_context)
if [ -n "$COMPLETION_CONTEXT" ]; then
  echo -e "${BLUE}→${NC} Found previous completion documents for context"
fi

# Archive if branch changed
archive_if_branch_changed "$ACTIVE_PRD"

# Track current branch
CURRENT_BRANCH=$(jq -r '.branchName // empty' "$ACTIVE_PRD" 2>/dev/null || echo "")
if [ -n "$CURRENT_BRANCH" ]; then
  echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
fi

# Initialize progress file
init_progress_file

echo "Starting Nelson - Tool: $TOOL - Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "==============================================================="
  echo "  Nelson Iteration $i of $MAX_ITERATIONS ($TOOL) - PRD: $PRD_NAME"
  echo "==============================================================="

  # Build the prompt with active PRD info and completion context
  PROMPT_FILE=$(mktemp)
  cat "$SCRIPT_DIR/CLAUDE.md" > "$PROMPT_FILE"

  # Add active PRD indicator
  cat >> "$PROMPT_FILE" << EOF

---
## Active PRD File
**IMPORTANT**: Work on stories in: .nelson/$(basename "$ACTIVE_PRD")
EOF

  # Add completion context if exists
  if [ -n "$COMPLETION_CONTEXT" ]; then
    echo -e "$COMPLETION_CONTEXT" >> "$PROMPT_FILE"
  fi

  # Run the selected tool
  if [[ "$TOOL" == "amp" ]]; then
    OUTPUT=$(cat "$PROMPT_FILE" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
  else
    OUTPUT=$(cat "$PROMPT_FILE" | claude --dangerously-skip-permissions --print 2>&1 | tee /dev/stderr) || true
  fi

  rm -f "$PROMPT_FILE"

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo -e "${GREEN}✓${NC} PRD $PRD_NAME completed!"

    # Generate completion document
    COMPLETION_FILE=$(generate_completion_doc "$ACTIVE_PRD")
    echo -e "${GREEN}✓${NC} Completion document: $COMPLETION_FILE"

    # Check if there are more PRDs to work on
    NEXT_PRD=$(find_active_prd)

    if [ -n "$NEXT_PRD" ] && [ "$NEXT_PRD" != "$ACTIVE_PRD" ]; then
      echo ""
      echo -e "${BLUE}→${NC} Next PRD found: $(get_prd_name "$NEXT_PRD")"
      echo -e "${BLUE}→${NC} Continuing to next PRD..."
      ACTIVE_PRD="$NEXT_PRD"
      PRD_NAME=$(get_prd_name "$ACTIVE_PRD")
      COMPLETION_CONTEXT=$(build_completion_context)
      continue
    else
      echo ""
      echo -e "${GREEN}✓${NC} All PRDs complete!"
      echo "Completed at iteration $i of $MAX_ITERATIONS"
      exit 0
    fi
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo -e "${YELLOW}!${NC} Nelson reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
