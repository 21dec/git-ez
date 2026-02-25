# g: a simplified git wrapper

`g` is a minimal, opinionated CLI that wraps `git` with a smaller set of commands and consistent verbs.

## Goals

- Reduce confusion around `reset`, `revert`, `checkout`, and staging.
- Provide predictable defaults.
- Keep the command surface small and readable.

## Install

```bash
chmod +x ./g
```

Optional: add to PATH (from the repo root).

```bash
echo 'export PATH="$(pwd):$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Usage

```bash
g help [command]
```

### State

- `g state`
- `g state --short`
- `g diff` (always compares against `HEAD`)

### Staging

- `g stage <file>`
- `g stage --all`
- `g unstage <file>`
- `g unstage --all`

### Commit

- `g commit "message"` (stages all, then commits)
- `g commit` (opens editor)
- `g amend`
- `g amend --no-edit`

### Undo and Move

- `g undo file <file>` (restore file from `HEAD`)
- `g undo commit` (revert `HEAD` with a new commit)
- `g move <commit>` (hard reset to commit)
- `g move <commit> --keep` (mixed reset to commit, keeps working tree, clears staging)

### Branch

- `g branch list`
- `g branch new <name>`
- `g branch go <name>`
- `g branch del <name>` (refuses to delete current branch)
- `g branch rename <old> <new>`

### Remote

- `g fetch`
- `g pull`
- `g push`
- `g sync` (defaults to rebase; set `G_SYNC_MODE=merge` to use merge)
- `g init` (creates `main` as the default branch)
- `g clone <url> [dir]`

### History

- `g log`
- `g log --last <N>`
- `g log --graph`
- `g log --oneline`
- `g log <file>`

## Notes

- `g commit` always stages all changes before committing.
- `g diff` never shows staged-only differences; it always compares to `HEAD`.

## Roadmap

- Add optional safety prompts for destructive commands.
