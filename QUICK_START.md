# Nelson Loop - Quick Start Guide

## Installation Complete ✓

The Nelson Loop framework is installed at `~/.nelson/`

The `nelson-scaffold` command is in your PATH.

## 30-Second Start

```bash
# 1. Go to your project
cd /path/to/project

# 2. Scaffold Nelson files (creates .nelson/ directory)
nelson-scaffold both .

# 3. Generate PRD interactively (RECOMMENDED for toro mode)
nelson-prd-generator    # Auto-detects .nelson/ and creates .nelson/prd.json

# 4a. For toro mode: Run Nelson
.nelson/nelson.sh --tool claude 10

# OR

# 4b. For plan/build mode: Generate specs, then run
nelson-specs-generator     # Interactive specs creation
.nelson/loop.sh plan       # Planning phase
.nelson/loop.sh 20         # Build phase
```

## Which Mode Should I Use?

### Use Toro Mode When:
- ✓ You have clear user stories
- ✓ Well-defined acceptance criteria
- ✓ Feature-based development
- ✓ Want PRD-driven workflow

### Use Plan/Build Mode When:
- ✓ Complex project needing planning
- ✓ Greenfield projects
- ✓ Need architectural planning first
- ✓ Want specification-driven workflow

### Use Both When:
- ✓ You're not sure yet
- ✓ Want maximum flexibility
- ✓ Different projects need different approaches

## Command Reference

```bash
# Scaffold a project (creates .nelson/ directory)
nelson-scaffold both /path/to/project
nelson-scaffold toro /path/to/project
nelson-scaffold plan-build /path/to/project

# Generate PRD interactively (NEW!)
nelson-prd-generator                # Auto-detects .nelson/, creates .nelson/prd.json
nelson-prd-generator my-prd.json    # Custom output file

# Generate specifications interactively (NEW!)
nelson-specs-generator              # Auto-creates specs/*.md

# Monitor Nelson progress (NEW!)
nelson-status                       # One-shot status view
nelson-status --watch               # Auto-refresh every 2s
nelson-status --watch 5             # Auto-refresh every 5s

# Run toro mode
.nelson/nelson.sh --tool claude 10   # 10 iterations max

# Run plan/build mode
.nelson/loop.sh plan                # Planning mode
.nelson/loop.sh 20                  # Build mode, 20 iterations

# Use nelson-loop plugin (in-session)
/nelson-loop "Task description" --max-iterations 20
```

## File Cheat Sheet

All Nelson files live in `.nelson/` directory to keep your project root clean!

### Toro Mode Files
- `.nelson/nelson.sh` - The loop script (executable)
- `.nelson/CLAUDE.md` - Instructions for Claude
- `.nelson/prd.json` - User stories (EDIT THIS)
- `.nelson/progress.txt` - Iteration log (auto-generated)
- `.nelson/AGENTS.md` - Project guide (UPDATE THIS)

### Plan/Build Mode Files
- `.nelson/loop.sh` - The loop script (executable)
- `.nelson/PROMPT_plan.md` - Planning instructions (customize goal)
- `.nelson/PROMPT_build.md` - Build instructions
- `.nelson/@IMPLEMENTATION_PLAN.md` - Task list (auto-generated)
- `.nelson/AGENTS.md` - Project guide (UPDATE THIS)
- `specs/` - Your specifications (CREATE THIS in project root)

## Completion Promises

Nelson stops when it outputs:
```
<promise>COMPLETE</promise>
```

If not output, runs until max iterations.

## PRD Generator (The Easy Button!)

The hardest part of Nelson is writing good user stories with testable acceptance criteria. The PRD generator does this for you!

### Interactive Mode (Recommended)
```bash
nelson-prd-generator
```

You'll be asked:
- Project name and description
- Branch name
- Main goal/problem
- Tech stack
- List of features
- Any constraints

Claude will then generate a complete `prd.json` with:
- Well-formed user stories
- Specific, testable acceptance criteria
- Proper priority ordering
- Technical validation steps

### What You Get

```json
{
  "project": "TodoApp",
  "branchName": "nelson/dark-mode",
  "description": "Add dark mode toggle to existing todo application",
  "userStories": [
    {
      "id": "US-001",
      "title": "Add dark mode state management",
      "description": "As a developer, I need theme state management so that components can access and update the theme.",
      "acceptanceCriteria": [
        "Create ThemeContext with light/dark state",
        "ThemeProvider wraps app root",
        "useTheme hook returns current theme and toggle function",
        "Typecheck passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

### Tips for Good PRD Generation

- **Be specific about features**: "User authentication with JWT" not "auth"
- **Mention your tech stack**: Helps generate relevant acceptance criteria
- **List constraints**: "Must work with existing Tailwind config"
- **Think about the user**: What are you building and why?

## Specs Generator (The Easy Button for Plan/Build!)

The specs generator makes it easy to create comprehensive specifications for the plan/build workflow.

### Interactive Mode (Recommended)
```bash
nelson-specs-generator
```

You'll be asked:
- Project name and feature/module name
- Problem statement and desired outcome
- Tech stack
- List of components/features
- Technical requirements and constraints
- Edge cases and special scenarios

Claude will then generate comprehensive specification files in `specs/` covering:
- Overview and goals
- User stories/use cases
- Technical requirements
- Data models and API contracts
- UI/UX specifications (if applicable)
- Edge cases and error handling
- Testing strategy

### What You Get

Multiple markdown files in `specs/` directory:
- `overview.md` - High-level architecture and goals
- `api.md` - API specifications and endpoints
- `data-models.md` - Database schema and data structures
- `ui.md` - Frontend/UI specifications (if applicable)

Or a single comprehensive spec file if the feature is smaller.

### Tips for Good Specs Generation

- **Be specific about components**: "REST API for user management" not "backend"
- **Mention technical constraints**: "Must handle 1000 req/sec", "Offline-first"
- **List edge cases**: "What happens if network fails?", "How to handle duplicates?"
- **Think about data**: What needs to be stored? What's the schema?

## Common Workflows

### Workflow 1: New Feature (Toro with PRD Generator)
```bash
nelson-scaffold toro .
nelson-prd-generator          # Interactive PRD creation (creates .nelson/prd.json)
# Edit .nelson/AGENTS.md with project info

# Run Nelson in one terminal
.nelson/nelson.sh --tool claude 15

# Monitor in another terminal (recommended!)
nelson-status --watch
```

### Workflow 1b: New Feature (Manual PRD)
```bash
nelson-scaffold toro .
# Manually edit .nelson/prd.json with user stories
# Edit .nelson/AGENTS.md with project info
.nelson/nelson.sh --tool claude 15
```

### Workflow 2: Complex Project (Plan/Build with Specs Generator)
```bash
nelson-scaffold plan-build .
nelson-specs-generator    # Interactive specs creation (creates specs/*.md)
# Edit .nelson/AGENTS.md with project info

# Run planning phase in one terminal
.nelson/loop.sh plan

# Review .nelson/@IMPLEMENTATION_PLAN.md
cat .nelson/@IMPLEMENTATION_PLAN.md

# Run build phase
.nelson/loop.sh 30

# Monitor in another terminal (recommended!)
nelson-status --watch
```

### Workflow 2b: Complex Project (Manual Specs)
```bash
nelson-scaffold plan-build .
mkdir specs
# Write specs/*.md files
# Update .nelson/PROMPT_plan.md with goal
.nelson/loop.sh plan
# Review .nelson/@IMPLEMENTATION_PLAN.md
.nelson/loop.sh 30
```

### Workflow 3: Quick Task (Plugin)
```bash
# In Claude Code session
/nelson-loop "Add dark mode toggle" --max-iterations 10
```

## Customization Tips

### Make Acceptance Criteria Specific
```json
"acceptanceCriteria": [
  "Priority dropdown in edit modal",
  "Current selection is highlighted",
  "Saves on change",
  "No placeholders or TODOs",
  "All tests pass",
  "Typecheck passes"
]
```

### Update AGENTS.md As You Go
```markdown
## Gotchas
### Issue: Tests fail with ECONNREFUSED
- Problem: Database not running
- Solution: Run `docker-compose up -d db` first
```

### Add Project Goal to Planning
```markdown
GOAL: Build a task management app with priority levels,
filtering, and real-time updates using React, TypeScript,
and PostgreSQL.
```

## Troubleshooting

### "command not found: nelson-scaffold"
```bash
# Reload your shell
source ~/.bashrc
# OR start a new terminal
```

### Nelson keeps repeating the same task
- Check acceptance criteria are specific
- Review progress.txt or @IMPLEMENTATION_PLAN.md
- Add learnings to AGENTS.md
- Make criteria more testable

### No completion promise
- Add to acceptance criteria: "Output <promise>COMPLETE</promise> when all tasks done"
- Or set reasonable --max-iterations

## Full Documentation

Read the complete guide:
```bash
cat ~/.nelson/README.md
```

## Examples

See working examples in the README.md file.

---

Need help? Check the README.md or visit:
- https://ghuntley.com/nelson/
- https://github.com/toro/ralph
