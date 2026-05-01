#!/usr/bin/env bash
# Symlink the canonical AGENTS.md into each AI agent's expected location.
# Idempotent: safe to re-run.

set -euo pipefail

CANON="$HOME/dev/lifesupport/AGENTS.md"
LOG() { printf '\033[1;34m[install-agents]\033[0m %s\n' "$*"; }

[[ -f "$CANON" ]] || { echo "missing $CANON"; exit 1; }

mkdir -p "$HOME/.claude" "$HOME/.kiro/steering"

ln -sfn "$CANON" "$HOME/AGENTS.md"                  # OpenCode
ln -sfn "$CANON" "$HOME/.claude/CLAUDE.md"          # Claude Code
ln -sfn "$CANON" "$HOME/.kiro/steering/AGENTS.md"   # Kiro

LOG "linked:"
LOG "  ~/AGENTS.md                  -> $CANON"
LOG "  ~/.claude/CLAUDE.md          -> $CANON"
LOG "  ~/.kiro/steering/AGENTS.md   -> $CANON"
