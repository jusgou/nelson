# Nelson Build Mode

You are in **build mode**. Your job is to implement tasks from `.nelson/@IMPLEMENTATION_PLAN.md`.

## Process

### 0. Understand Context

a. Study `specs/*` with up to 500 parallel subagents to learn specifications.
b. Study `.nelson/@IMPLEMENTATION_PLAN.md` to understand the plan.
c. Study `.nelson/AGENTS.md` to learn how to build and run the project.
d. Application source is in `src/*`.

### 1. Implement

- Choose the **most important** incomplete item from `.nelson/@IMPLEMENTATION_PLAN.md`
- **Before making changes**: Search codebase to confirm functionality is missing
- Use up to 500 subagents for searches
- Use only 1 subagent for build/test operations
- Implement completely per specifications
- Follow patterns from `.nelson/AGENTS.md`

### 2. Verify

- Run tests (per `.nelson/AGENTS.md`)
- Run typecheck (if applicable)
- Run linter (if applicable)
- Verify in browser/runtime if specified in acceptance criteria
- If tests fail, fix the issues

### 3. Update Documentation

When implementation is complete:
- Update `.nelson/@IMPLEMENTATION_PLAN.md`:
  - Move completed task to "Completed" section
  - Add any newly discovered tasks
- Update `.nelson/AGENTS.md` if you learned something about running the project
- Capture the **why** in code comments (only where logic isn't self-evident)

### 4. Commit & Push

```bash
git add -A
git commit -m "Descriptive message about what was implemented"
git push
```

### 5. Compact Context

After completing a task and committing, run `/compact` to reduce context size and improve performance for the next task.

### 6. Ultrathink

- Did you implement completely? (No placeholders or stubs?)
- Are there single sources of truth? (No migrations/adapters unless necessary?)
- Does this match the specification exactly?
- Are there hidden edge cases?

## Critical Rules

- **IMPLEMENT COMPLETELY** - No placeholders, no stubs, no TODOs
- **SEARCH FIRST** - Never assume functionality is missing
- **ONE TASK AT A TIME** - Focus on the current highest-priority item
- **KEEP PLAN CURRENT** - Future work depends on accurate plan
- **SINGLE SOURCES OF TRUTH** - Avoid duplication and migrations
- **UPDATE AGENTS.MD** - Document project-specific learnings
- **COMPACT AFTER TASKS** - Run `/compact` after completing each task to reduce context and improve performance

## Completion Signal

When ALL tasks in `.nelson/@IMPLEMENTATION_PLAN.md` are complete and tests pass, output:

```
<promise>COMPLETE</promise>
```

This signals the build is done.

## Example Iteration

1. Read plan, see "Add user authentication" is next
2. Search codebase for existing auth code
3. Implement auth per spec
4. Run tests, fix failures
5. Update plan (move task to completed)
6. Commit and push
7. Run `/compact` to reduce context
8. Move to next task

## Context Management

Since you may work on multiple tasks in a single session, use `/compact` after completing each task to:
- Reduce context size
- Improve response speed
- Prevent context limits from being reached
- Maintain only essential information for the next task
