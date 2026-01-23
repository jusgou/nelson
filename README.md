```
███╗   ██╗███████╗██╗     ███████╗ ██████╗ ███╗   ██╗
████╗  ██║██╔════╝██║     ██╔════╝██╔═══██╗████╗  ██║
██╔██╗ ██║█████╗  ██║     ███████╗██║   ██║██╔██╗ ██║
██║╚██╗██║██╔══╝  ██║     ╚════██║██║   ██║██║╚██╗██║
██║ ╚████║███████╗███████╗███████║╚██████╔╝██║ ╚████║
╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝
```

# Nelson

Autonomous AI development with quality control. Nelson builds your features and reviews its own work to catch bugs before they compound.

## Requirements

- [Claude Code CLI](https://github.com/anthropics/claude-code) (`claude` command)
- jq (`sudo dnf install jq` or `brew install jq`)

## Install

```bash
git clone git@github.com:jusgou/nelson.git ~/.nelson
sudo ln -sf ~/.nelson/bin/nelson-* /usr/local/bin/
```

Verify: `nelson-init --help`

## Usage

```bash
cd your-project
nelson-init      # Setup + define tasks
nelson-run       # Start building
```

Monitor in another terminal:
```bash
nelson-status --watch
```

## Two Modes

**Full Nelson** - Builds + reviews. After every N stories, Nelson reviews all completed work, checks for compounding errors, and creates fix tasks if needed.

**Classic Ralph** - Builds only. Faster, no review phases.

Choose during `nelson-init`.

## Multiple Task Lists

Need more tasks? Run `nelson-init` again:

```
> Found existing setup. What would you like to do?
>   [1] Create another PRD
>   [2] Reconfigure settings
>   [3] Start fresh
```

Run multiple Nelsons in parallel on different task lists - locking prevents conflicts.

## Tips

- **Small stories** - Each task should complete in one iteration
- **Testable criteria** - "Returns 400 if email invalid" not "handles errors"
- **Update AGENTS.md** - Add project-specific commands and patterns

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Repeats same task | Make acceptance criteria more specific |
| Implements placeholders | Add "No TODOs or placeholders" to criteria |
| Appears stuck | Check `nelson-status`, restart if needed |

## Credits

Inspired by the work of:

- **Geoffrey Huntley** ([@ghuntley](https://github.com/ghuntley)) - Ralph autonomous development technique
- **Snarktank** ([@snarktank](https://github.com/snarktank)) - PRD-based implementation
- **Mike O'Brien** ([@mikeyobrien](https://github.com/mikeyobrien)) - Ralph Orchestrator
- **Clayton Farr** ([@ClaytonFarr](https://github.com/ClaytonFarr)) - Ralph Playbook

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
