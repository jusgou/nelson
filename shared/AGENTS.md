# AGENTS.md - Project Guide for AI Agents

This file helps AI agents (Claude, Amp, etc.) understand how to work with this project.

## Project Overview

**Name**: [PROJECT_NAME]
**Description**: [PROJECT_DESCRIPTION]
**Tech Stack**: [e.g., React, TypeScript, Node.js, PostgreSQL]

## Build & Run

### Install Dependencies
```bash
npm install
# or
pnpm install
# or
yarn install
```

### Development Server
```bash
npm run dev
# or
pnpm dev
```

Access at: `http://localhost:3000` (or specify port)

### Build
```bash
npm run build
```

### Tests
```bash
npm test
# or
npm run test:watch  # Watch mode
```

### Type Checking
```bash
npm run typecheck
# or
tsc --noEmit
```

### Linting
```bash
npm run lint
# or
npm run lint:fix  # Auto-fix issues
```

## Codebase Structure

```
src/
├── components/     # React components
├── lib/           # Shared utilities and helpers
├── pages/         # Page components / routes
├── styles/        # CSS/styling files
├── types/         # TypeScript type definitions
└── ...
```

## Important Patterns

### Component Structure
- Use functional components with hooks
- Keep components focused and single-purpose
- Extract reusable logic into custom hooks

### State Management
- [Describe your state management approach]
- [e.g., React Context, Redux, Zustand, etc.]

### API/Data Fetching
- [Describe your data fetching patterns]
- [e.g., React Query, SWR, fetch, etc.]

### Styling
- [Describe your styling approach]
- [e.g., Tailwind, CSS Modules, styled-components, etc.]

## Gotchas & Known Issues

### Issue 1: [Description]
- **Problem**: [What goes wrong]
- **Solution**: [How to fix it]

### Issue 2: [Description]
- **Problem**: [What goes wrong]
- **Solution**: [How to fix it]

## Testing Guidelines

- Write tests for business logic and critical paths
- Use [test framework, e.g., Jest, Vitest]
- Mock external dependencies
- Aim for meaningful tests, not just coverage

## Common Tasks

### Adding a New Feature
1. Create feature branch: `git checkout -b feature/feature-name`
2. Implement feature
3. Write tests
4. Update this AGENTS.md if you learn something new
5. Commit and push

### Debugging
- Use browser DevTools for frontend issues
- Check console for errors
- Use debugger statements or breakpoints
- Check network tab for API issues

## Dependencies

### Key Dependencies
- [List important dependencies and why they're used]

### Development Dependencies
- [List dev dependencies and their purpose]

## Notes for Nelson

- Always run tests before marking a task complete
- Update this file when you discover new patterns or gotchas
- Check `@IMPLEMENTATION_PLAN.md` for current priorities
- Commit frequently with descriptive messages

## Last Updated

[DATE] - [What was learned/added]
