#!/bin/bash
# Nelson Loop - Integrated Build + Review workflow
# Usage: ./loop.sh [options] [max_iterations]
#
# Options:
#   --tool amp|claude       AI tool to use (default: claude)
#   --start-review N        Start reviews after N stories (default: 1)
#   --review-every N        Review every N stories after start (default: 1)
#   --prd FILE              Target specific PRD file (no auto-advance)
#   --no-lock               Disable file locking (not recommended for parallel runs)
#
# Examples:
#   ./loop.sh 20                                      # Auto-find PRD, with locking
#   ./loop.sh --prd prd-2.json 20                     # Target specific PRD
#   ./loop.sh --start-review 1 --review-every 1 20   # Review after EVERY story

set -e

# ============================================================
# ARGUMENT PARSING
# ============================================================

TOOL="claude"
MAX_ITERATIONS=20
START_REVIEW=${NELSON_START_AT:-1}
REVIEW_EVERY=${NELSON_FREQUENCY:-1}
EXPLICIT_PRD=""
USE_LOCKING=true

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
    --start-review)
      START_REVIEW="$2"
      shift 2
      ;;
    --review-every)
      REVIEW_EVERY="$2"
      shift 2
      ;;
    --prd)
      EXPLICIT_PRD="$2"
      shift 2
      ;;
    --prd=*)
      EXPLICIT_PRD="${1#*=}"
      shift
      ;;
    --no-lock)
      USE_LOCKING=false
      shift
      ;;
    *)
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

if [[ "$TOOL" != "amp" && "$TOOL" != "claude" ]]; then
  echo "Error: Invalid tool '$TOOL'. Must be 'amp' or 'claude'."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
COMPLETIONS_DIR="$SCRIPT_DIR/completions"
LOGS_DIR="$SCRIPT_DIR/nelson-logs"
LOCKS_DIR="$SCRIPT_DIR/.locks"
LAST_REVIEW_FILE="$SCRIPT_DIR/.last-review-count"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================================
# LOCKING FUNCTIONS
# ============================================================

get_lock_file() {
  local prd="$1"
  local prd_name=$(basename "$prd")
  echo "$LOCKS_DIR/${prd_name}.lock"
}

is_pid_alive() {
  local pid="$1"
  kill -0 "$pid" 2>/dev/null
}

is_prd_locked() {
  local prd="$1"
  local lock_file=$(get_lock_file "$prd")

  if [ ! -f "$lock_file" ]; then
    return 1  # Not locked
  fi

  # Check if lock is stale (PID no longer running)
  local lock_pid=$(grep "^PID=" "$lock_file" 2>/dev/null | cut -d= -f2)
  if [ -n "$lock_pid" ] && ! is_pid_alive "$lock_pid"; then
    # Stale lock - remove it
    rm -f "$lock_file"
    return 1  # Not locked (was stale)
  fi

  return 0  # Locked
}

acquire_lock() {
  local prd="$1"
  local lock_file=$(get_lock_file "$prd")

  mkdir -p "$LOCKS_DIR"

  # Check if already locked
  if is_prd_locked "$prd"; then
    return 1  # Failed to acquire
  fi

  # Create lock file
  cat > "$lock_file" << EOF
PID=$$
STARTED=$(date -Iseconds)
PRD=$(basename "$prd")
EOF

  return 0  # Lock acquired
}

release_lock() {
  local prd="$1"
  local lock_file=$(get_lock_file "$prd")

  # Only remove if we own the lock
  local lock_pid=$(grep "^PID=" "$lock_file" 2>/dev/null | cut -d= -f2)
  if [ "$lock_pid" = "$$" ]; then
    rm -f "$lock_file"
  fi
}

# Cleanup on exit
cleanup() {
  if [ -n "$ACTIVE_PRD" ] && [ "$USE_LOCKING" = true ]; then
    release_lock "$ACTIVE_PRD"
  fi
}
trap cleanup EXIT INT TERM

# ============================================================
# PRD FUNCTIONS
# ============================================================

find_prd_files() {
  local files=()
  [ -f "$SCRIPT_DIR/prd.json" ] && files+=("$SCRIPT_DIR/prd.json")
  for f in "$SCRIPT_DIR"/prd-[0-9]*.json; do
    [ -f "$f" ] && files+=("$f")
  done
  printf '%s\n' "${files[@]}" | sort -t'-' -k2 -n
}

is_prd_valid() {
  local prd="$1"
  # Check file exists, is non-empty, and has userStories array
  [ -s "$prd" ] && jq -e '.userStories | length > 0' "$prd" >/dev/null 2>&1
}

is_prd_complete() {
  local prd="$1"
  # Return false if PRD is invalid
  is_prd_valid "$prd" || return 1
  local incomplete=$(jq '[.userStories[] | select(.passes == false)] | length' "$prd" 2>/dev/null)
  [ -n "$incomplete" ] && [ "$incomplete" -eq 0 ]
}

get_completed_count() {
  local result=$(jq '[.userStories[] | select(.passes == true)] | length' "$1" 2>/dev/null)
  echo "${result:-0}"
}

get_total_count() {
  local result=$(jq '.userStories | length' "$1" 2>/dev/null)
  echo "${result:-0}"
}

# Find first incomplete PRD, respecting locks if locking is enabled
find_active_prd() {
  for prd in $(find_prd_files); do
    # Skip invalid PRDs
    if ! is_prd_valid "$prd"; then
      echo -e "${YELLOW}!${NC} Skipping $(basename "$prd") (invalid or empty)" >&2
      continue
    fi

    # Skip complete PRDs
    is_prd_complete "$prd" && continue

    # Skip locked PRDs (if locking enabled)
    if [ "$USE_LOCKING" = true ] && is_prd_locked "$prd"; then
      echo -e "${YELLOW}!${NC} Skipping $(basename "$prd") (locked by another instance)" >&2
      continue
    fi

    echo "$prd"
    return 0
  done
  echo ""
}

get_prd_name() {
  basename "$1" .json
}

get_last_review_count() {
  [ -f "$LAST_REVIEW_FILE" ] && cat "$LAST_REVIEW_FILE" || echo "0"
}

set_last_review_count() {
  echo "$1" > "$LAST_REVIEW_FILE"
}

should_review() {
  local completed="$1"
  local last_reviewed="$2"

  # Haven't reached first review checkpoint yet
  [ "$completed" -lt "$START_REVIEW" ] && return 1

  # First review
  [ "$last_reviewed" -lt "$START_REVIEW" ] && [ "$completed" -ge "$START_REVIEW" ] && return 0

  # Subsequent reviews
  local since_start=$((completed - START_REVIEW))
  local last_since=$((last_reviewed - START_REVIEW))
  [ "$last_since" -lt 0 ] && last_since=0

  [ $((since_start / REVIEW_EVERY)) -gt $((last_since / REVIEW_EVERY)) ] && return 0

  return 1
}

# ============================================================
# LOGGING FUNCTIONS
# ============================================================

create_log() {
  local description="$1"
  local timestamp=$(date +%Y%m%d%H%M)
  # Sanitize description for filename
  local safe_desc=$(echo "$description" | tr ' ' '-' | tr -cd '[:alnum:]-_' | head -c 50)
  local log_file="$LOGS_DIR/${timestamp}_${safe_desc}.md"

  mkdir -p "$LOGS_DIR"

  cat > "$log_file" << EOF
# Nelson Progress Log
**Timestamp**: $(date)
**Phase**: $description

## PRD Status
$(jq -r '.userStories[] | "- \(.id): \(.title) - \(if .passes then "COMPLETE" else "PENDING" end)"' "$ACTIVE_PRD" 2>/dev/null || echo "Unable to read PRD")

## Recent Learnings
$(tail -30 "$PROGRESS_FILE" 2>/dev/null || echo "No progress file yet")

---
*Logged before new Claude instance*
EOF
  echo "$log_file"
}

create_completion_doc() {
  local prd="$1"
  local name=$(get_prd_name "$prd")
  local timestamp=$(date +%Y-%m-%d-%H%M%S)

  mkdir -p "$COMPLETIONS_DIR"
  local doc="$COMPLETIONS_DIR/${name}-complete-${timestamp}.md"

  cat > "$doc" << EOF
# PRD Completion Report: $name
**Generated**: $(date)
**Workflow**: Nelson (Integrated Build + Review)
**Review Config**: start=$START_REVIEW, every=$REVIEW_EVERY

## Project
$(jq -r '"- **Name**: \(.project // "N/A")\n- **Branch**: \(.branchName // "N/A")\n- **Description**: \(.description // "N/A")"' "$prd")

## Completed Stories
$(jq -r '.userStories[] | "### \(.id): \(.title)\n**Notes**: \(.notes // "None")\n"' "$prd")

## Potential Items to Review
> These are areas that may warrant future attention:

- [ ] **Performance**: Review any N+1 queries or inefficient patterns
- [ ] **Security**: Verify input validation and auth flows
- [ ] **Edge cases**: Test boundary conditions and error states
- [ ] **Documentation**: Ensure inline docs match implementation
- [ ] **Technical debt**: Check for TODOs or temporary solutions

## Quality Summary
- Total stories: $(get_total_count "$prd")
- Reviews conducted at configured checkpoints
- Holistic compatibility verified between stories

---
*Nelson - Build with integrated review*
EOF
  echo "$doc"
}

init_progress() {
  [ -f "$PROGRESS_FILE" ] && return
  cat > "$PROGRESS_FILE" << EOF
# Nelson Progress Log
Started: $(date)
Config: start-review=$START_REVIEW, every=$REVIEW_EVERY
---
EOF
}

# ============================================================
# MAIN
# ============================================================

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  Nelson - Integrated Build + Review Loop               ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Determine active PRD
if [ -n "$EXPLICIT_PRD" ]; then
  # Explicit PRD specified
  if [[ "$EXPLICIT_PRD" != /* ]]; then
    # Relative path - prepend SCRIPT_DIR
    EXPLICIT_PRD="$SCRIPT_DIR/$EXPLICIT_PRD"
  fi

  if [ ! -f "$EXPLICIT_PRD" ]; then
    echo -e "${RED}Error: PRD file not found: $EXPLICIT_PRD${NC}"
    exit 1
  fi

  ACTIVE_PRD="$EXPLICIT_PRD"
  AUTO_ADVANCE=false

  # Check if locked by another instance
  if [ "$USE_LOCKING" = true ] && is_prd_locked "$ACTIVE_PRD"; then
    echo -e "${RED}Error: $(basename "$ACTIVE_PRD") is locked by another instance${NC}"
    echo "Use --no-lock to override (not recommended)"
    exit 1
  fi
else
  # Auto-find first incomplete PRD
  ACTIVE_PRD=$(find_active_prd)
  AUTO_ADVANCE=true
fi

if [ -z "$ACTIVE_PRD" ]; then
  # Check if any PRDs exist
  if [ -f "$SCRIPT_DIR/prd.json" ]; then
    # PRDs exist but all are either complete or locked
    ALL_COMPLETE=true
    for prd in $(find_prd_files); do
      if ! is_prd_complete "$prd"; then
        ALL_COMPLETE=false
        break
      fi
    done

    if [ "$ALL_COMPLETE" = true ]; then
      echo -e "${GREEN}✓${NC} All PRDs complete!"
    else
      echo -e "${YELLOW}!${NC} All incomplete PRDs are locked by other instances"
      echo "Wait for them to finish, or use --prd to target a specific PRD with --no-lock"
    fi
    exit 0
  fi

  echo -e "${YELLOW}!${NC} No PRD found. Run: nelson-prd-generator"
  exit 1
fi

# Acquire lock if locking is enabled
if [ "$USE_LOCKING" = true ]; then
  if ! acquire_lock "$ACTIVE_PRD"; then
    echo -e "${RED}Error: Failed to acquire lock on $(basename "$ACTIVE_PRD")${NC}"
    exit 1
  fi
fi

PRD_NAME=$(get_prd_name "$ACTIVE_PRD")

# Validate PRD before proceeding
if ! is_prd_valid "$ACTIVE_PRD"; then
  echo -e "${RED}Error: PRD file is invalid or empty: $ACTIVE_PRD${NC}"
  echo ""
  echo "The PRD file must:"
  echo "  - Exist and be non-empty"
  echo "  - Be valid JSON"
  echo "  - Have a 'userStories' array with at least one story"
  echo ""
  echo "Try regenerating it with: nelson-prd-generator"
  if [ "$USE_LOCKING" = true ]; then
    release_lock "$ACTIVE_PRD"
  fi
  exit 1
fi

COMPLETED=$(get_completed_count "$ACTIVE_PRD")
TOTAL=$(get_total_count "$ACTIVE_PRD")

echo -e "${BLUE}→${NC} PRD: $PRD_NAME ($COMPLETED/$TOTAL complete)"
echo -e "${BLUE}→${NC} Review: start at $START_REVIEW, then every $REVIEW_EVERY"
echo -e "${BLUE}→${NC} Tool: $TOOL | Max iterations: $MAX_ITERATIONS"
if [ "$USE_LOCKING" = true ]; then
  echo -e "${BLUE}→${NC} Locking: enabled"
else
  echo -e "${YELLOW}→${NC} Locking: disabled"
fi
if [ "$AUTO_ADVANCE" = false ]; then
  echo -e "${BLUE}→${NC} Mode: explicit PRD (no auto-advance)"
fi
echo ""

mkdir -p "$LOGS_DIR"
init_progress

for i in $(seq 1 $MAX_ITERATIONS); do
  COMPLETED=$(get_completed_count "$ACTIVE_PRD")
  TOTAL=$(get_total_count "$ACTIVE_PRD")
  LAST_REVIEWED=$(get_last_review_count)

  # PRD complete?
  if is_prd_complete "$ACTIVE_PRD"; then
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  PRD COMPLETE - Final Review${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"

    LOG=$(create_log "final-review-${PRD_NAME}")
    echo -e "${BLUE}→${NC} Log: $LOG"

    # Final review prompt
    PROMPT=$(mktemp)
    cat "$SCRIPT_DIR/CLAUDE.md" > "$PROMPT"
    cat >> "$PROMPT" << EOF

---
## FINAL REVIEW - All Stories Complete

Perform final holistic review:
1. Verify ALL stories work together cohesively
2. Check for any compounding issues across the full codebase
3. Create completion report noting potential items to review
4. Run /compact
5. Output <promise>COMPLETE</promise>
EOF

    if [[ "$TOOL" == "amp" ]]; then
      OUTPUT=$(cat "$PROMPT" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
    else
      OUTPUT=$(cat "$PROMPT" | claude --dangerously-skip-permissions --print 2>&1 | tee /dev/stderr) || true
    fi
    rm -f "$PROMPT"

    DOC=$(create_completion_doc "$ACTIVE_PRD")
    echo -e "${GREEN}✓${NC} Completion doc: $DOC"

    # Release lock before looking for next PRD
    if [ "$USE_LOCKING" = true ]; then
      release_lock "$ACTIVE_PRD"
    fi

    # Auto-advance to next PRD?
    if [ "$AUTO_ADVANCE" = true ]; then
      NEXT=$(find_active_prd)
      if [ -n "$NEXT" ] && [ "$NEXT" != "$ACTIVE_PRD" ]; then
        echo -e "${BLUE}→${NC} Next PRD: $(get_prd_name "$NEXT")"
        ACTIVE_PRD="$NEXT"
        PRD_NAME=$(get_prd_name "$ACTIVE_PRD")

        # Acquire lock on new PRD
        if [ "$USE_LOCKING" = true ]; then
          if ! acquire_lock "$ACTIVE_PRD"; then
            echo -e "${RED}Error: Failed to acquire lock on $PRD_NAME${NC}"
            exit 1
          fi
        fi

        set_last_review_count 0
        continue
      fi
    fi

    echo -e "${GREEN}✓${NC} All PRDs complete!"
    exit 0
  fi

  # Decide: BUILD or REVIEW?
  if should_review "$COMPLETED" "$LAST_REVIEWED"; then
    # ==================== REVIEW PHASE ====================
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  REVIEW - Iteration $i - $COMPLETED stories complete${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"

    # Get current story context for log name
    CURRENT_STORY=$(jq -r '[.userStories[] | select(.passes == true)][-1].id // "initial"' "$ACTIVE_PRD")
    LOG=$(create_log "review-after-${CURRENT_STORY}")
    echo -e "${BLUE}→${NC} Log: $LOG"

    PROMPT=$(mktemp)
    cat "$SCRIPT_DIR/CLAUDE.md" > "$PROMPT"
    cat >> "$PROMPT" << EOF

---
## REVIEW PHASE - Holistic Check at $COMPLETED Stories

This is a HOLISTIC review of ALL completed work - not just the last story.

### Review Tasks:
1. Read ALL completed stories in .nelson/prd.json
2. Examine the ENTIRE codebase for:
   - Compatibility between all stories
   - Compounding errors (early mistakes causing later problems)
   - Technical debt accumulating
   - Architectural consistency
   - Security issues
   - Missing documentation

3. If issues found:
   - Create fix stories in prd.json with id format: "US-XXX-FIX-1"
   - Set priority appropriately (fixes before new features)
   - These will be built in the next iteration

4. Create review log: .nelson/nelson-logs/$(date +%Y%m%d%H%M)_review-findings.md

5. Run /compact to maintain context

6. Output <promise>REVIEW_DONE</promise> when complete

### Stories to review holistically:
$(jq -r '.userStories[] | select(.passes == true) | "- \(.id): \(.title)"' "$ACTIVE_PRD" 2>/dev/null)
EOF

    if [[ "$TOOL" == "amp" ]]; then
      OUTPUT=$(cat "$PROMPT" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
    else
      OUTPUT=$(cat "$PROMPT" | claude --dangerously-skip-permissions --print 2>&1 | tee /dev/stderr) || true
    fi
    rm -f "$PROMPT"

    if echo "$OUTPUT" | grep -q "<promise>REVIEW_DONE</promise>"; then
      set_last_review_count "$COMPLETED"
      echo -e "${GREEN}✓${NC} Review complete"
    fi

  else
    # ==================== BUILD PHASE ====================
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  BUILD - Iteration $i - $COMPLETED/$TOTAL${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"

    # Get next story for log name
    NEXT_STORY=$(jq -r '[.userStories[] | select(.passes == false)][0].id // "unknown"' "$ACTIVE_PRD")
    LOG=$(create_log "build-${NEXT_STORY}")
    echo -e "${BLUE}→${NC} Log: $LOG"

    PROMPT=$(mktemp)
    cat "$SCRIPT_DIR/CLAUDE.md" > "$PROMPT"
    cat >> "$PROMPT" << EOF

---
## BUILD PHASE - Implement Next Story

**Active PRD**: .nelson/$(basename "$ACTIVE_PRD")

### Tasks:
1. Read .nelson/prd.json
2. Check .nelson/completions/ for context from previous PRDs
3. Check .nelson/progress.txt for learnings
4. Find highest-priority story with passes: false
5. Implement completely - no placeholders
6. Verify all acceptance criteria
7. Update prd.json: passes: true, add notes
8. Append learnings to progress.txt
9. Commit: git add -A && git commit -m "US-XXX: description"
10. Run /compact
11. Output <promise>STORY_DONE</promise>

### Pending stories:
$(jq -r '.userStories[] | select(.passes == false) | "- \(.id): \(.title) [priority \(.priority)]"' "$ACTIVE_PRD" 2>/dev/null)

### Next review at: $((COMPLETED < START_REVIEW ? START_REVIEW : COMPLETED + REVIEW_EVERY - ((COMPLETED - START_REVIEW) % REVIEW_EVERY))) stories
EOF

    if [[ "$TOOL" == "amp" ]]; then
      OUTPUT=$(cat "$PROMPT" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
    else
      OUTPUT=$(cat "$PROMPT" | claude --dangerously-skip-permissions --print 2>&1 | tee /dev/stderr) || true
    fi
    rm -f "$PROMPT"

    if echo "$OUTPUT" | grep -q "<promise>STORY_DONE</promise>"; then
      NEW_COUNT=$(get_completed_count "$ACTIVE_PRD")
      echo -e "${GREEN}✓${NC} Story complete ($NEW_COUNT/$TOTAL)"
    fi
  fi

  sleep 2
done

echo ""
echo -e "${YELLOW}!${NC} Max iterations ($MAX_ITERATIONS) reached"
echo "Check logs: $LOGS_DIR"
exit 1
