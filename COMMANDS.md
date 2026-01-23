# Nelson Loop Framework - Command Reference

All commands are available after reloading your shell: `source ~/.bashrc`

## Core Commands

### nelson-scaffold
Scaffold a new Nelson project with template files.

```bash
# Scaffold both approaches
nelson-scaffold both /path/to/project

# Scaffold toro mode only (PRD-based)
nelson-scaffold toro /path/to/project

# Scaffold plan/build mode only (IMPLEMENTATION_PLAN-based)
nelson-scaffold plan-build /path/to/project

# Scaffold in current directory
nelson-scaffold both .
```

**What it does:**
- Creates loop orchestrator scripts (nelson.sh, loop.sh)
- Creates prompt files (CLAUDE.md, PROMPT_*.md)
- Creates template files (prd.json, @IMPLEMENTATION_PLAN.md)
- Creates AGENTS.md project guide
- Sets up .gitignore entries

---

### nelson-prd-generator (NEW!)
Interactively generate a comprehensive prd.json file.

```bash
# Generate prd.json in current directory
nelson-prd-generator

# Generate with custom filename
nelson-prd-generator my-feature.json
```

**What it does:**
- Asks questions about your project
- Collects feature requirements
- Generates well-structured user stories
- Creates specific, testable acceptance criteria
- Outputs valid prd.json ready for Nelson

**Questions asked:**
1. Project name
2. Branch name (e.g., nelson/feature-name)
3. Feature description
4. Main goal/problem
5. Tech stack
6. List of features
7. Constraints/requirements

**Output:**
- Complete prd.json with 3-8 user stories
- Specific acceptance criteria
- Proper priority ordering
- Technical validation steps included

---

### nelson-specs-generator (NEW!)
Interactively generate comprehensive specification documents for plan/build mode.

```bash
# Generate specs/*.md in current directory
nelson-specs-generator
```

**What it does:**
- Asks questions about your project/feature
- Collects requirements and technical constraints
- Generates comprehensive specification documents
- Creates multiple .md files in specs/ directory
- Ready for use with plan/build workflow

**Questions asked:**
1. Project name and feature/module name
2. Problem statement
3. Desired outcome
4. Tech stack
5. List of components/features
6. Technical requirements/constraints
7. Edge cases and special scenarios

**Output:**
- Multiple markdown files in `specs/` directory:
  - `overview.md` - High-level architecture and goals
  - `api.md` - API specifications (if applicable)
  - `data-models.md` - Database schema (if applicable)
  - `ui.md` - Frontend specifications (if applicable)
- Or single comprehensive spec file for smaller features
- Covers: goals, user stories, technical requirements, data models, API endpoints, edge cases, testing strategy

---

### nelson-status (NEW!)
Monitor Nelson's progress in real-time with a comprehensive dashboard.

```bash
# One-shot status view
nelson-status

# Auto-refresh every 2 seconds (recommended)
nelson-status --watch

# Auto-refresh with custom interval (5 seconds)
nelson-status --watch 5
```

**What it shows:**
- Current task being worked on
- Progress bar with completion percentage
- Full task list with status indicators (✓ completed, ▶ in progress, ○ pending)
- Activity monitoring (last commit, last file modified)
- Process status (Nelson and Claude PIDs, CPU, memory)
- Warning if no activity detected (stuck detection)

**Works with both modes:**
- Auto-detects toro mode (reads .nelson/prd.json)
- Auto-detects plan/build mode (reads .nelson/@IMPLEMENTATION_PLAN.md)

**Use when:**
- Nelson runs in `--print` mode (which is silent by design)
- You want to see what Nelson is working on
- You need to detect if Nelson is stuck
- You want real-time progress updates

---

### nelson-prd-agent
Launch an interactive Claude session for PRD generation.

```bash
nelson-prd-agent
```

**What it does:**
- Opens an interactive Claude Code session
- Loads PRD generator agent prompt
- Allows conversational PRD creation
- Helpful for complex projects needing discussion

**Use when:**
- You want to discuss the PRD interactively
- Requirements are complex or uncertain
- You need to iterate on user stories
- You prefer conversational interface

---

## Nelson Loop Scripts

These are created by `nelson-scaffold` in your project directory.

### ./nelson.sh (Toro Mode)
Run the toro/ralph loop with PRD-based user stories.

```bash
# Run with Claude Code for 10 iterations
./nelson.sh --tool claude 10

# Run with Amp
./nelson.sh --tool amp 15

# Default (Claude, 10 iterations)
./nelson.sh
```

**What it does:**
- Reads prd.json
- Implements each user story
- Verifies acceptance criteria
- Updates prd.json (sets passes: true)
- Commits and pushes
- Archives previous runs when branch changes
- Stops when <promise>COMPLETE</promise> is output

---

### ./loop.sh (Plan/Build Mode)
Run the plan/build loop with implementation plan.

```bash
# Planning mode (5 iterations)
./loop.sh plan
./loop.sh plan 3

# Build mode (20 iterations)
./loop.sh 20
./loop.sh

# Build mode with custom iterations
./loop.sh 50
```

**What it does:**
- **Plan mode**: Analyzes codebase, creates @IMPLEMENTATION_PLAN.md
- **Build mode**: Implements tasks from plan, runs tests, commits
- Auto-pushes after each iteration in build mode
- Stops when <promise>COMPLETE</promise> is output

---

## Plugin Commands

### /nelson-loop
Run Nelson Loop in current Claude Code session.

```bash
/nelson-loop "Implement dark mode" --max-iterations 10
/nelson-loop "Add authentication" --completion-promise "AUTH COMPLETE"
```

**What it does:**
- Runs Nelson iterations in your current session
- Interactive (can ask questions)
- Uses stop hooks to loop
- Good for supervised work

**Difference from scripts:**
- `/nelson-loop`: Same session, interactive, supervised
- `./nelson.sh` / `./loop.sh`: Fresh instances, autonomous, unsupervised

---

## Template Files

### Project Templates

Located at `~/.nelson/`

**Toro mode:**
- `toro/nelson.sh` - Loop orchestrator
- `toro/CLAUDE.md` - Instructions for Claude
- `toro/prd.json.example` - PRD template

**Plan/Build mode:**
- `plan-build/loop.sh` - Loop orchestrator
- `plan-build/PROMPT_plan.md` - Planning instructions
- `plan-build/PROMPT_build.md` - Build instructions

**Shared:**
- `shared/AGENTS.md` - Project guide template

### Helper Scripts

- `nelson-scaffold` - Project scaffolder
- `nelson-prd-generator` - Interactive PRD generator
- `nelson-specs-generator` - Interactive specs generator
- `nelson-prd-agent` - Conversational PRD generator
- `nelson-status` - Monitoring dashboard
- `PRD_GENERATOR_PROMPT.md` - Agent prompt for PRD generation

### Documentation

- `README.md` - Complete documentation
- `QUICK_START.md` - Quick reference guide
- `COMMANDS.md` - This file

---

## Common Workflows

### Workflow 1: New Feature with Toro

```bash
# 1. Scaffold the project
cd /path/to/project
nelson-scaffold toro .

# 2. Generate PRD interactively (RECOMMENDED)
nelson-prd-generator

# 3. Update project guide
vim .nelson/AGENTS.md  # Add how to run tests, build, etc.

# 4. Run Nelson (in one terminal)
.nelson/nelson.sh --tool claude 15

# 5. Monitor progress (in another terminal)
nelson-status --watch
```

### Workflow 2: Complex Project with Plan/Build

```bash
# 1. Scaffold the project
cd /path/to/project
nelson-scaffold plan-build .

# 2. Generate specifications interactively (RECOMMENDED)
nelson-specs-generator

# OR manually create specifications
# mkdir specs
# cat > specs/feature.md <<EOF
# # Feature Specification
# [Description of what you're building]
# EOF

# 3. Update project guide
vim .nelson/AGENTS.md  # Add how to run tests, build, etc.

# 4. Run planning
.nelson/loop.sh plan

# 5. Review plan
cat .nelson/@IMPLEMENTATION_PLAN.md

# 6. Run build
.nelson/loop.sh 30

# 7. Monitor progress (in another terminal)
nelson-status --watch
```

### Workflow 3: Hybrid Approach

```bash
# 1. Use both modes
nelson-scaffold both .

# 2. Start with planning
nelson-specs-generator
.nelson/loop.sh plan
cat .nelson/@IMPLEMENTATION_PLAN.md

# 3. Switch to toro for implementation
nelson-prd-generator  # Convert plan to user stories
.nelson/nelson.sh --tool claude 20

# 4. Monitor progress (in another terminal)
nelson-status --watch
```

### Workflow 4: In-Session with Plugin

```bash
# In a Claude Code session
/nelson-loop "Add user profile page with avatar upload" --max-iterations 15
```

---

## File Outputs

### Created by nelson-scaffold

Toro mode:
- `nelson.sh` (executable)
- `CLAUDE.md`
- `prd.json`
- `prd.json.example`
- `progress.txt`
- `AGENTS.md`

Plan/Build mode:
- `loop.sh` (executable)
- `PROMPT_plan.md`
- `PROMPT_build.md`
- `@IMPLEMENTATION_PLAN.md`
- `AGENTS.md`

### Created during Nelson runs

Toro:
- `progress.txt` - Learnings from each iteration
- `archive/YYYY-MM-DD-branch-name/` - Previous runs

Plan/Build:
- `@IMPLEMENTATION_PLAN.md` - Updated with progress

---

## Environment Setup

### Add to PATH (done automatically)

```bash
# Added to ~/.bashrc
export PATH="$HOME/.nelson/bin:$PATH"
```

### Reload shell

```bash
source ~/.bashrc
# OR
exec bash
# OR
# Open new terminal
```

---

## Dependencies

Required:
- `claude` - Claude Code CLI
- `jq` - JSON processor (for nelson-prd-generator)
- `git` - Version control

Optional:
- `amp` - Anthropic Amp (for ./nelson.sh --tool amp)

Install jq:
```bash
# Fedora
sudo dnf install jq

# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq
```

---

## Help & Documentation

```bash
# Quick reference
cat ~/.nelson/QUICK_START.md

# Full documentation
cat ~/.nelson/README.md

# Command reference
cat ~/.nelson/COMMANDS.md

# PRD generator guide
cat ~/.nelson/PRD_GENERATOR_PROMPT.md

# List all templates
ls -la ~/.nelson/
```

---

## Tips

1. **Always update .nelson/AGENTS.md** - Future iterations depend on it
2. **Use nelson-prd-generator** - Saves hours of PRD writing (toro mode)
3. **Use nelson-specs-generator** - Saves hours of spec writing (plan/build mode)
4. **Use nelson-status --watch** - Monitor progress in real-time
5. **Start small** - Test with 5-10 iterations first
6. **Review commits** - Nelson auto-commits, check git log
7. **Tune prompts** - Edit .nelson/CLAUDE.md or .nelson/PROMPT_*.md if Nelson goes wrong
8. **Set completion promises** - Prevent infinite loops

---

## Learn More

- Original technique: https://ghuntley.com/nelson/
- Toro repo: https://github.com/toro/ralph
- Nelson Orchestrator: https://github.com/mikeyobrien/nelson-orchestrator
