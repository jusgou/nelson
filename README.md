```
███╗   ██╗███████╗██╗     ███████╗ ██████╗ ███╗   ██╗
████╗  ██║██╔════╝██║     ██╔════╝██╔═══██╗████╗  ██║
██╔██╗ ██║█████╗  ██║     ███████╗██║   ██║██╔██╗ ██║
██║╚██╗██║██╔══╝  ██║     ╚════██║██║   ██║██║╚██╗██║
██║ ╚████║███████╗███████╗███████║╚██████╔╝██║ ╚████║
╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝
```

# Nelson Loop Framework

**Autonomous AI development with integrated quality control.**

Nelson is an AI development workflow that combines automated implementation with holistic quality reviews—catching bugs, technical debt, and compounding errors before they spread.

## Requirements

- **Claude Code CLI** - Nelson is built specifically for Claude (`claude` command must be available)
- **jq** - JSON processor for PRD handling (`sudo dnf install jq` or `brew install jq`)

## Installation

```bash
# Quick install
curl -fsSL https://raw.githubusercontent.com/jusgou/nelson/main/install.sh | bash

# Or manual
git clone git@github.com:jusgou/nelson.git ~/.nelson
chmod +x ~/.nelson/bin/nelson-*
export PATH="$HOME/.nelson/bin:$PATH"  # Add to ~/.bashrc
```

Verify: `which nelson-scaffold`

---

# Nelson Workflow

The integrated build + review loop for quality-controlled autonomous development.

## Quick Start

```bash
# 1. Scaffold your project
cd /path/to/project
nelson-scaffold nelson .

# 2. Generate PRD with user stories
nelson-prd-generator

# 3. Run the integrated build + review loop
.nelson/loop.sh --start-review 1 --review-every 1 20

# Monitor progress (separate terminal)
nelson-status --watch
```

## How It Works

Nelson alternates between BUILD and REVIEW phases:

**BUILD Phase:**
- Finds highest-priority incomplete story
- Implements completely (no placeholders)
- Verifies all acceptance criteria
- Commits locally (never pushes)

**REVIEW Phase:**
- Holistic review of ALL completed work
- Checks for compounding errors across stories
- Creates fix stories if issues found
- Logs findings with timestamps

## Review Configuration

```bash
# Review after EVERY story (maximum rigor)
.nelson/loop.sh --start-review 1 --review-every 1 20

# Review at story 3, then every 2 stories
.nelson/loop.sh --start-review 3 --review-every 2 20

# Set defaults via environment
export NELSON_START_AT=1
export NELSON_FREQUENCY=1
.nelson/loop.sh 20
```

### What Nelson Reviews

- **Acceptance criteria** - Did stories actually get completed?
- **Compounding errors** - Mistakes from Story 1 making Story 5 worse?
- **Technical debt** - Shortcuts that will hurt later?
- **Architectural consistency** - Does new code fit existing patterns?
- **Security issues** - SQL injection, XSS, vulnerabilities?
- **Documentation gaps** - Missing inline docs?

Review logs are saved to `.nelson/nelson-logs/` with format: `YYYYMMDDHHMM_description.md`

## Parallel Instances

Run multiple Nelson instances on different PRDs simultaneously:

```bash
# Terminal 1: Auto-finds first incomplete PRD, locks it
.nelson/loop.sh 20

# Terminal 2: Auto-finds next unlocked incomplete PRD
.nelson/loop.sh 20

# Or explicitly target specific PRDs
.nelson/loop.sh --prd prd.json 20      # Terminal 1: auth features
.nelson/loop.sh --prd prd-2.json 20    # Terminal 2: API features
```

**How locking works:**
- Locking is **enabled by default**
- When a loop starts, it creates `.nelson/.locks/prd.json.lock`
- Other instances skip locked PRDs and find the next available one
- Locks are released when the loop exits (or detected as stale if crashed)
- Use `--no-lock` to disable (not recommended for parallel runs)

**Flags:**

| Flag | Behavior |
|------|----------|
| (default) | Auto-find first unlocked incomplete PRD, auto-advance when done |
| `--prd FILE` | Target specific PRD, stop when done (no auto-advance) |
| `--no-lock` | Disable locking (use with caution) |

---

## Multi-PRD Workflow

Work through multiple sets of user stories sequentially:

```bash
# First PRD
nelson-prd-generator              # Creates .nelson/prd.json
.nelson/loop.sh --start-review 1 --review-every 1 20
# → Completion doc generated in .nelson/completions/

# Second PRD
nelson-prd-generator              # Auto-creates .nelson/prd-2.json
.nelson/loop.sh --start-review 1 --review-every 1 20
# → Continues with prd-2.json
```

**How it works:**
- PRD files: `prd.json`, `prd-2.json`, `prd-3.json`, etc.
- Loop automatically finds the first incomplete PRD
- Completion documents provide context for subsequent PRDs
- Previous work is preserved and referenced

---

## Core Commands

### nelson-scaffold

Scaffold workflow templates into `.nelson/` directory:

```bash
nelson-scaffold nelson .          # Integrated build + review (RECOMMENDED)
nelson-scaffold snarktank .       # Legacy: build only
nelson-scaffold plan-build .      # Legacy: spec-based workflow
nelson-scaffold all .             # All workflows
```

### nelson-prd-generator

Interactively generate comprehensive PRD files:

```bash
nelson-prd-generator              # Creates .nelson/prd.json (or next available)
nelson-prd-generator custom.json  # Custom filename
```

Asks questions about your project, then **uses Claude to generate** well-structured, atomic user stories with testable acceptance criteria. Claude breaks down your requirements into small, focused stories (each completable in one iteration).

### nelson-prd-edit

Open the active PRD file in your editor:

```bash
nelson-prd-edit                   # Opens active PRD in $EDITOR
```

Finds the first incomplete PRD (or most recent if all complete) and opens it for editing.

### nelson-specs-generator

Generate specifications for plan/build workflow:

```bash
nelson-specs-generator            # Creates specs/*.md
```

### nelson-status

Monitor progress in real-time:

```bash
nelson-status           # One-shot view
nelson-status --watch   # Auto-refresh every 2s
```

---

## File Structure

```
project/
├── .nelson/
│   ├── loop.sh              # Integrated build + review loop
│   ├── CLAUDE.md            # Agent instructions
│   ├── prd.json             # First PRD
│   ├── prd-2.json           # Second PRD (optional)
│   ├── AGENTS.md            # Project guide (UPDATE THIS!)
│   ├── progress.txt         # Learnings log
│   ├── completions/         # PRD completion documents
│   ├── nelson-logs/         # Review logs (YYYYMMDDHHMM_description.md)
│   └── .locks/              # PRD lock files (for parallel instances)
└── src/                     # Your code
```

---

## Best Practices

### Write Small, Focused Stories

Each story should complete in one iteration:

```json
// Good: Focused
"Add user registration endpoint with email validation"

// Bad: Too large
"Build complete auth system with login, registration, OAuth, and 2FA"
```

### Write Testable Acceptance Criteria

```json
"acceptanceCriteria": [
  "POST /api/users returns 201 on success",
  "Returns 400 if email invalid",
  "Tests pass",
  "Typecheck passes"
]
```

### Keep AGENTS.md Updated

Add project-specific info as Nelson learns:
- How to run tests
- How to start dev server
- Known gotchas and fixes

### Always Monitor

Run `nelson-status --watch` in a separate terminal.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Nelson repeats same task | Make acceptance criteria more specific |
| Implements placeholders | Add "No TODOs or placeholders" to criteria |
| Can't see output | Normal! Use `nelson-status --watch` |
| Appears stuck | Check nelson-status, kill and restart if needed |

---

# Legacy Workflows

These workflows preceded the integrated quality review system.

## Snarktank (Build Only)

Fresh Claude instances cycle through user stories sequentially. No integrated review phases—just build, build, build until all stories are complete.

**Difference from Nelson:**
- **Nelson**: BUILD → REVIEW → BUILD → REVIEW → BUILD...
- **Snarktank**: BUILD → BUILD → BUILD → BUILD...

```bash
nelson-scaffold snarktank .
nelson-prd-generator
.nelson/snarktank-loop.sh --tool claude 15
```

## Plan/Build (Spec-Based)

Two-phase workflow: planning then building.

```bash
nelson-scaffold plan-build .
nelson-specs-generator
.nelson/plan-build-loop.sh plan    # Planning phase
.nelson/plan-build-loop.sh 20      # Build phase
```

---

## Credits

Nelson builds upon the Ralph Wiggum autonomous development technique.

**Original Authors:**
- **Geoffrey Huntley** ([@ghuntley](https://github.com/ghuntley)) - Original technique, Plan/Build workflow
- **Snarktank** ([@snarktank](https://github.com/snarktank)) - PRD-based implementation
- **Mike O'Brien** ([@mikeyobrien](https://github.com/mikeyobrien)) - Ralph Orchestrator
- **Clayton Farr** ([@ClaytonFarr](https://github.com/ClaytonFarr)) - Ralph Playbook

**Nelson's Contribution:**
Integrated build + review workflow with holistic quality checks at configurable intervals. Catches compounding errors before they spread.

---

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   ██╗  ██╗ █████╗       ██╗  ██╗ █████╗     ██╗              ║
║   ██║  ██║██╔══██╗      ██║  ██║██╔══██╗    ██║              ║
║   ███████║███████║█████╗███████║███████║    ██║              ║
║   ██╔══██║██╔══██║╚════╝██╔══██║██╔══██║    ╚═╝              ║
║   ██║  ██║██║  ██║      ██║  ██║██║  ██║    ██╗              ║
║   ╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```
