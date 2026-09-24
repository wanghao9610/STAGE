#!/usr/bin/env bash
# Skip Claude's permission prompt for file edits while the project runs at
# involve=low (writing workflow conventions §7.7). Confirmation points are
# untouched: the STOP line, deletions and overwrites, and every venue.yml value
# entering as confirmed are questions a skill asks, not permission prompts a hook
# can answer.
#
# The level comes from stage_involve_level.sh: the `involve=` token of the
# session's most recent STAGE command, or `.env`'s INVOLVE when it carried none.
# Silence means "no decision", so every other level, every path this declines,
# and a project that sets none fall through to the normal permission flow. The
# level is resolved on each call, so a new invocation — or an edit to .env —
# takes effect without a restart.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-${PWD}}"

# The payload is read before the level is tested: it carries the transcript path
# the level is resolved from, and a hook that exits without reading stdin leaves
# the runtime's write to fail.
input=$(cat)

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/stage_involve_level.sh"
involve="$(stage_involve_level "${input}" "${root}")"
[[ "${involve}" == "low" ]] || exit 0

# The edited path, from Edit/Write (file_path) or NotebookEdit (notebook_path).
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

# Dot-directories at the project root — .git, .claude, .stage, the other tool
# trees — keep their prompt, the way acceptEdits mode keeps one for protected
# paths. Their contents are project machinery, not the manuscript, the notes, or
# the cycle files a run is writing. mates/ keeps its prompt too: the evidence is
# read-only, written only through execs/scpts/import.sh and stage-evid-curator.
# So does a venue kit under cycls/<cycle>/template/, poster kits included: it is
# unpacked whole and never edited (§10.4), as the bash gate also holds. A `..`
# segment can climb back out of the root, and a doubled slash hides mates/ from
# the test (`<root>//mates/x`), so a path carrying either keeps its prompt as
# well.
[[ "${rel}" == .* || "${rel}" == mates/* || "${rel}" == cycls/*/template/* || "${rel}" == */../* || "${rel}" == */.. ]] && exit 0
[[ "${rel}" == /* || "${rel}" == *//* ]] && exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"involve=low"}}\n'
