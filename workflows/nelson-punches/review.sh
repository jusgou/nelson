#!/bin/bash
# Nelson Review Loop - Optional quality rigor
# Usage: ./review.sh [--tool amp|claude] [max_iterations]

set -e

# Parse arguments
TOOL="claude"  # Default to claude
MAX_ITERATIONS=5  # Reviews typically need fewer iterations

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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
NELSON_DIR="$PROJECT_ROOT/.nelson"
PRD_FILE="$NELSON_DIR/prd.json"
REVIEW_LOGS_DIR="$NELSON_DIR/nelson-logs"

# Check if running from a Nelson project
if [ ! -f "$PRD_FILE" ]; then
  echo "Error: Not in a Nelson project. Missing .nelson/prd.json"
  echo "Run this from a project directory that has been scaffolded with nelson-scaffold"
  exit 1
fi

# Create review logs directory if needed
mkdir -p "$REVIEW_LOGS_DIR"

echo "Starting Nelson Review Loop - Tool: $TOOL - Max iterations: $MAX_ITERATIONS"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Nelson Review - Punch those bugs!"
echo "═══════════════════════════════════════════════════════════"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "==============================================================="
  echo "  Review Iteration $i of $MAX_ITERATIONS ($TOOL)"
  echo "==============================================================="

  # Run the selected tool with the review prompt
  if [[ "$TOOL" == "amp" ]]; then
    OUTPUT=$(cat "$SCRIPT_DIR/CLAUDE.md" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
  else
    # Claude Code: use --dangerously-skip-permissions for autonomous operation, --print for output
    OUTPUT=$(cat "$SCRIPT_DIR/CLAUDE.md" | claude --dangerously-skip-permissions --print 2>&1 | tee /dev/stderr) || true
  fi

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>REVIEW_COMPLETE</promise>"; then
    echo ""
    echo "Nelson review completed!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    echo ""
    echo "Review logs saved to: $REVIEW_LOGS_DIR"
    exit 0
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Nelson review reached max iterations ($MAX_ITERATIONS) without completion."
echo "Check review logs in $REVIEW_LOGS_DIR for status."
exit 1
