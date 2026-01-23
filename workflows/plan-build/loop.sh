#!/bin/bash
# Nelson Loop - Plan/Build Mode
# Usage: ./loop.sh [plan] [max_iterations]

if [ "$1" = "plan" ]; then
    MODE="plan"
    PROMPT_FILE="PROMPT_plan.md"
    MAX_ITERATIONS=${2:-5}
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    MODE="build"
    PROMPT_FILE="PROMPT_build.md"
    MAX_ITERATIONS=$1
else
    MODE="build"
    PROMPT_FILE="PROMPT_build.md"
    MAX_ITERATIONS=${1:-20}
fi

ITERATION=0
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Nelson Loop - $MODE Mode                                    "
echo "║  Prompt: $PROMPT_FILE"
echo "║  Branch: $CURRENT_BRANCH"
echo "║  Max Iterations: $MAX_ITERATIONS"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

while true; do
    [ $MAX_ITERATIONS -gt 0 ] && [ $ITERATION -ge $MAX_ITERATIONS ] && break

    echo ""
    echo "┌────────────────────────────────────────────────────────────┐"
    echo "│  Iteration $((ITERATION + 1)) of $MAX_ITERATIONS"
    echo "└────────────────────────────────────────────────────────────┘"

    # Run Claude Code with the prompt
    OUTPUT=$(cat "$PROMPT_FILE" | claude --dangerously-skip-permissions --print 2>&1 | tee /dev/stderr) || true

    # Check for completion signal
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo ""
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║  Nelson completed successfully!"
        echo "║  Completed at iteration $((ITERATION + 1)) of $MAX_ITERATIONS"
        echo "╚════════════════════════════════════════════════════════════╝"
        exit 0
    fi

    # Auto-push if in build mode
    if [ "$MODE" = "build" ]; then
        git push origin "$CURRENT_BRANCH" 2>/dev/null || git push -u origin "$CURRENT_BRANCH" 2>/dev/null || true
    fi

    ITERATION=$((ITERATION + 1))
    echo ""
    echo "Iteration complete. Continuing..."
    sleep 2
done

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Nelson reached max iterations ($MAX_ITERATIONS)"
echo "║  Check @IMPLEMENTATION_PLAN.md for status"
echo "╚════════════════════════════════════════════════════════════╝"
exit 1
