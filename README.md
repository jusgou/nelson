```
███╗   ██╗███████╗██╗     ███████╗ ██████╗ ███╗   ██╗
████╗  ██║██╔════╝██║     ██╔════╝██╔═══██╗████╗  ██║
██╔██╗ ██║█████╗  ██║     ███████╗██║   ██║██╔██╗ ██║
██║╚██╗██║██╔══╝  ██║     ╚════██║██║   ██║██║╚██╗██║
██║ ╚████║███████╗███████╗███████║╚██████╔╝██║ ╚████║
╚═╝  ╚═══╝╚══════╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═══╝
```

# Nelson

Autonomous AI development with quality control. Nelson builds your features and reviews its own work to catch bugs before they compound. The Nelson loop is designed to minimize the effect of compounded errors and ensure that agents are viewing projects holistically, integrating features within the context of existing schemas. 

For heavy, intensive coding processes with multi-step feature creation, a lookback of 1 might be useful; however, this is usage intensive and may result in heavy token depletion. For most projects, a lookback of 5 (reviewing completed work in the context of the project as a whole every 5 stories) is likely more than sufficient). 

Thanks to user contributions, a few updates are incoming: 
1. Moving model and lookback selection to nelson-run. This will allow users to stop and start and change parameters more easily.
2. A real-time editor that allows adjustments to be made to the instructions (essentially an agent-driven, interactive prd.json editor)
3. Paste task list to register individual items as rows
4. Token usage optimization to streamline re-contextualization at every lookback / new instance start-up

Thanks for your contributions and feedback!

## Requirements

- [Claude Code CLI](https://github.com/anthropics/claude-code) (`claude` command)
- jq (`sudo dnf install jq` or `brew install jq`)

## Install

```bash
git clone git@github.com:jusgou/nelson.git ~/.nelson
cd ~/.nelson
./install.sh
```

Add to your shell config (`~/.bashrc` or `~/.zshrc`):
```bash
export PATH="$HOME/.nelson/bin:$PATH"
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
