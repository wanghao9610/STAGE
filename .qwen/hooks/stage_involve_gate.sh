#!/usr/bin/env bash
# Skip Qwen Code's permission prompt for file edits while the project runs at
# INVOLVE=low (.env, workflow conventions §7.7). Confirmation points are
# untouched: the STOP line, deletions and plan approval are questions a skill
# asks, not permission prompts a hook can answer.
#
# Silence means "no decision", so every other level, every path this declines,
# and a project with no .env fall through to the normal permission flow. INVOLVE
# is read on each call, so editing .env takes effect without a restart.
set -uo pipefail

root="${QWEN_PROJECT_DIR:-${PWD}}"

# The payload is read before the level is tested: the runtime writes it to this
# hook's stdin, and a hook that exits without reading leaves that write to fail.
input=$(cat)

line="$(grep -sE '^INVOLVE=' "${root}/.env" | tail -1)"
value="${line#INVOLVE=}"
value="${value%%#*}"
involve="$(printf '%s' "${value}" | tr -cd '[:alpha:]')"
[[ "${involve}" == "low" ]] || exit 0

# The edited path, from edit/write_file (file_path) or notebook_edit
# (notebook_path).
edited_path() {
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "${input}" \
            | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null
    else
        printf '%s' "${input}" \
            | grep -oE '"(file_path|notebook_path)"[[:space:]]*:[[:space:]]*"[^"]*"' \
            | head -1 | sed -E 's/.*"([^"]*)"$/\1/'
    fi
}

path="$(edited_path)"
case "${path}" in
    "${root}"/*) rel="${path#"${root}"/}" ;;
    *) exit 0 ;;
esac

# Dot-directories at the project root — .git, .qwen, .stage, the other tool
# trees — keep their prompt, the way auto-edit mode keeps one for protected
# paths. Their contents are project machinery, not the code a run is editing.
# mates/ keeps its prompt too: the evidence is read-only, written only through
# execs/scpts/import.sh and stage-evid-curator. So does a venue kit under
# cycls/<cycle>/template/, poster kits included: it is unpacked whole and never
# edited (§10.4). A `..` segment can climb back out of the root, and a doubled
# slash hides mates/ from the test (`<root>//mates/x`), so a path carrying either
# keeps its prompt as well.
[[ "${rel}" == .* || "${rel}" == mates/* || "${rel}" == cycls/*/template/* || "${rel}" == */../* || "${rel}" == */.. ]] && exit 0
[[ "${rel}" == /* || "${rel}" == *//* ]] && exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"INVOLVE=low"}}\n'
