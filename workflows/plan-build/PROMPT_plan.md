# Nelson Planning Mode

You are in **planning mode**. Your job is to create and maintain `.nelson/@IMPLEMENTATION_PLAN.md`.

## Process

### 0. Understand the Project

a. Study `specs/*` with up to 250 parallel subagents to learn the application specifications.
b. Study `.nelson/@IMPLEMENTATION_PLAN.md` (if present) to understand the plan so far.
c. Study `.nelson/AGENTS.md` to understand how to build and run the project.
d. Study `src/lib/*` with up to 250 parallel subagents to understand shared utilities.

### 1. Analyze and Plan

Use up to 500 subagents to:
- Study existing source code in `src/*`
- Compare implementation against `specs/*`
- Search for TODOs, placeholders, skipped tests, incomplete implementations
- Identify inconsistent patterns or architectural issues
- Prioritize tasks based on dependencies and impact

### 2. Create/Update Implementation Plan

Create or update `.nelson/@IMPLEMENTATION_PLAN.md` as a prioritized bullet list:

```markdown
# Implementation Plan

## High Priority
- [ ] Task with highest impact/lowest dependencies
- [ ] Next important task

## Medium Priority
- [ ] Tasks that depend on high-priority items
- [ ] Refactoring opportunities

## Low Priority
- [ ] Nice-to-have improvements
- [ ] Documentation updates

## Completed
- [x] Completed task (move here when done)
```

### 3. Ultrathink

Use deep reasoning to:
- Identify hidden dependencies
- Consider edge cases
- Anticipate integration challenges
- Question assumptions

## Critical Rules

- **PLAN ONLY** - Do NOT implement anything
- **CONFIRM FIRST** - Do NOT assume functionality is missing; search the codebase first
- **BE SPECIFIC** - Each task should be clear and actionable
- **PRIORITIZE** - Order matters; put blocking tasks first

## Goal

**PROJECT_GOAL**: [Replace with your specific project goal]

## Completion Signal

When your analysis is complete and `.nelson/@IMPLEMENTATION_PLAN.md` is thorough, output:

```
<promise>COMPLETE</promise>
```

This signals the planning phase is done.

## Context Management

If you need to explore multiple areas of the codebase during planning, consider using `/compact` periodically to reduce context size and improve performance. This is especially useful when analyzing large codebases with many subagents.
