#!/usr/bin/env bash
# Register STAGE's Kimi hook — the project-memory index injected from
# .stage/memory/ — in Kimi's GLOBAL config, idempotently.
#
# Kimi has no project-level hook config, so the [[hooks]] entry must live in the
# global config at $KIMI_CODE_HOME/config.toml (default ~/.kimi-code/config.toml).
# This is one-time-per-machine setup: because the command path is relative and
# Kimi runs hooks from the project root, that one entry then covers every STAGE
# paper repository with no per-project editing.
#
# Safe to re-run: the hook is registered only when it is not there already. It
# backs the config up before modifying it, and appends a new [[hooks]] table
# array (valid TOML) rather than rewriting anything.
set -euo pipefail

cfg="${KIMI_CODE_HOME:-$HOME/.kimi-code}/config.toml"
script="stage_memory.sh"
label="STAGE project-memory hook"

# Make sure this repo's hook script is executable.
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
[ -f "$here/${script}" ] && chmod +x "$here/${script}" 2>/dev/null || true

mkdir -p "$(dirname "$cfg")"
[ -f "$cfg" ] || : > "$cfg"

if grep -qF "${script}" "$cfg" 2>/dev/null; then
  echo "${label} already registered in $cfg — nothing to do."
  exit 0
fi

cp "$cfg" "$cfg.stage-bak"
{
  printf '\n# --- %s (added by .kimi-code/hooks/install.sh) ---\n' "${label}"
  printf '[[hooks]]\n'
  printf 'event = "UserPromptSubmit"\n'
  printf 'command = ".kimi-code/hooks/%s"\n' "${script}"
  printf 'timeout = 10\n'
} >> "$cfg"

echo "Registered ${label} in $cfg"
echo "  backup written to $cfg.stage-bak"
echo "  it now runs in every STAGE paper repository — no per-project setup needed."
