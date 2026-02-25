#!/usr/bin/env bash
set -euo pipefail

die() {
  echo "g: $*" >&2
  exit 1
}

usage_main() {
  cat <<'USAGE'
g - simplified git wrapper

Usage:
  g help [command]

Status:
  g status [--long]
  g diff [file]

Commit:
  g commit [message]
  g amend [--no-edit]

Undo/Move:
  g undo file <file>
  g undo commit
  g move <commit> [--keep]

Branch:
  g branch list
  g branch new <name>
  g branch go <name>
  g branch del <name>
  g branch rename <old> <new>

Remote:
  g fetch
  g pull
  g push
  g sync
  g init
  g clone <url> [dir]

History:
  g log [--last N] [--graph] [--oneline] [file]
USAGE
}

usage_status() { echo "Usage: g status [--long]"; }
usage_diff() { echo "Usage: g diff [file]"; }
usage_commit() { echo "Usage: g commit [message]"; }
usage_amend() { echo "Usage: g amend [--no-edit]"; }
usage_undo() { echo "Usage: g undo file <file> | g undo commit"; }
usage_move() { echo "Usage: g move <commit> [--keep]"; }
usage_branch() {
  cat <<'USAGE'
Usage:
  g branch list
  g branch new <name>
  g branch go <name>
  g branch del <name>
  g branch rename <old> <new>
USAGE
}
usage_sync() { echo "Usage: g sync (mode: G_SYNC_MODE=rebase|merge, default rebase)"; }
usage_init() { echo "Usage: g init"; }
usage_clone() { echo "Usage: g clone <url> [dir]"; }
usage_log() { echo "Usage: g log [--last N] [--graph] [--oneline] [file]"; }

cmd="${1:-help}"
shift || true

case "$cmd" in
  help|-h|--help)
    if [[ $# -eq 0 ]]; then
      usage_main
      exit 0
    fi
    case "$1" in
      status) usage_status ;;
      diff) usage_diff ;;
      commit) usage_commit ;;
      amend) usage_amend ;;
      undo) usage_undo ;;
      move) usage_move ;;
      branch) usage_branch ;;
      sync) usage_sync ;;
      init) usage_init ;;
      clone) usage_clone ;;
      log) usage_log ;;
      *) die "unknown command '$1'" ;;
    esac
    exit 0
    ;;

  status)
    if [[ $# -gt 1 ]]; then usage_status; exit 2; fi
    if [[ "${1:-}" == "--long" ]]; then
      git status
    else
      git status -sb
    fi
    ;;

  diff)
    if [[ $# -gt 1 ]]; then usage_diff; exit 2; fi
    if [[ $# -eq 1 ]]; then
      git diff HEAD -- "$1"
    else
      git diff HEAD
    fi
    ;;

  commit)
    git add -A
    if [[ $# -gt 0 ]]; then
      msg="$*"
      git commit -m "$msg"
    else
      git commit
    fi
    ;;

  amend)
    if [[ "${1:-}" == "--no-edit" ]]; then
      git commit --amend --no-edit
    elif [[ $# -eq 0 ]]; then
      git commit --amend
    else
      usage_amend; exit 2
    fi
    ;;

  undo)
    sub="${1:-}"
    shift || true
    case "$sub" in
      file)
        if [[ $# -eq 0 ]]; then usage_undo; exit 2; fi
        git restore -- "$@"
        ;;
      commit)
        if [[ $# -ne 0 ]]; then usage_undo; exit 2; fi
        git revert HEAD
        ;;
      *)
        usage_undo; exit 2 ;;
    esac
    ;;

  move)
    if [[ $# -lt 1 ]]; then usage_move; exit 2; fi
    target="$1"
    shift || true
    if [[ "${1:-}" == "--keep" ]]; then
      git reset --mixed "$target"
    elif [[ $# -eq 0 ]]; then
      git reset --hard "$target"
    else
      usage_move; exit 2
    fi
    ;;

  branch)
    sub="${1:-}"
    shift || true
    case "$sub" in
      list)
        git branch
        ;;
      new)
        [[ $# -eq 1 ]] || { usage_branch; exit 2; }
        git branch "$1"
        ;;
      go)
        [[ $# -eq 1 ]] || { usage_branch; exit 2; }
        git switch "$1"
        ;;
      del)
        [[ $# -eq 1 ]] || { usage_branch; exit 2; }
        current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
        if [[ -n "$current_branch" && "$1" == "$current_branch" ]]; then
          die "refusing to delete current branch '$current_branch'"
        fi
        git branch -d "$1"
        ;;
      rename)
        [[ $# -eq 2 ]] || { usage_branch; exit 2; }
        git branch -m "$1" "$2"
        ;;
      *)
        usage_branch; exit 2 ;;
    esac
    ;;

  fetch) git fetch ;;
  pull) git pull ;;
  push) git push ;;
  sync)
    if [[ $# -ne 0 ]]; then usage_sync; exit 2; fi
    mode="${G_SYNC_MODE:-rebase}"
    if [[ "$mode" == "merge" ]]; then
      git pull
    else
      git pull --rebase
    fi
    ;;

  init)
    if [[ $# -ne 0 ]]; then usage_init; exit 2; fi
    git init -b main
    ;;

  clone)
    if [[ $# -lt 1 || $# -gt 2 ]]; then usage_clone; exit 2; fi
    git clone "$@"
    ;;

  log)
    last=10
    graph=0
    oneline=0
    file=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --last)
          shift || true
          [[ $# -gt 0 ]] || { usage_log; exit 2; }
          last="$1"
          ;;
        --graph) graph=1 ;;
        --oneline) oneline=1 ;;
        --help|-h) usage_log; exit 0 ;;
        *)
          if [[ -z "$file" ]]; then
            file="$1"
          else
            usage_log; exit 2
          fi
          ;;
      esac
      shift || true
    done
    args=(--max-count "$last")
    if [[ $oneline -eq 1 ]]; then args+=(--oneline); fi
    if [[ $graph -eq 1 ]]; then args+=(--graph --decorate); fi
    if [[ -n "$file" ]]; then args+=(-- "$file"); fi
    git log "${args[@]}"
    ;;

  *)
    die "unknown command '$cmd' (try 'g help')"
    ;;
esac
