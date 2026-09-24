#!/usr/bin/env bash
# Resolve the involve level a gate hook should act on: the `involve=<level>`
# token of the session's most recent STAGE command, or `.env`'s INVOLVE when that
# invocation carried none, or `medium` when .env sets no valid level either
# (writing workflow conventions §7.7, §7.13).
#
# Sourced by stage_involve_gate.sh; it decides nothing itself. Prints one of
# low / medium / high, and the caller acts only on low.
#
# Why the transcript. The token rides in the invocation the user typed, which
# reaches the model and not the hook: a hook is a separate process, and its
# payload carries the tool call, never the words that started the run. What the
# payload does carry is `transcript_path`, and the transcript records a slash
# command as <command-name>/stage-sect-drafter</command-name> beside a
# <command-args> block holding what was typed after it, and a skill dispatched
# through the Skill tool as a tool_use block carrying that skill's `args`. Those
# two blocks are the only places read here. Plain chat text is ignored on
# purpose: a message *about* the level — "set involve=low for the drafter" — is
# discussion, and a grep over loose text would take it for a setting.
#
# Scope. The most recent STAGE command wins for as long as it is the most recent:
# answering a question mid-run leaves it in force, and the next STAGE command
# replaces it — with .env when that one names no level. A run's level therefore
# outlives the run itself, until the next command; .env stays the standing level
# and the token is the temporary one.

# The invocation's involve token: the last whitespace-separated word that is
# exactly involve=low, involve=medium or involve=high.
stage__involve_token() { # $1 = the invocation's argument text
    local token
    token="$(printf '%s\n' "$1" | tr -s '[:space:]' '\n' \
        | grep -xE 'involve=(low|medium|high)' | tail -1)"
    printf '%s' "${token#involve=}"
}

stage__payload_field() { # $1 = payload JSON, $2 = top-level field name
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$1" | jq -r --arg k "$2" '.[$k] // empty' 2>/dev/null
    else
        printf '%s' "$1" \
            | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
            | head -1 | sed -E 's/.*"([^"]*)"$/\1/'
    fi
}

# The argument text of the last STAGE invocation in the transcript, read from
# two forms and taking whichever comes last in the file:
#
#   - a command the user typed, recorded as a user entry whose
#     <command-name> starts with stage, its token read from <command-args>;
#   - a Skill tool call dispatching a stage skill, recorded as a tool_use block
#     in an assistant entry, its token read from the call's `args`.
#
# The second form exists because a skill often reaches the model wrapped in
# another command — `/goal /stage-sect-drafter 3_method involve=low` records
# <command-name>/goal and nothing else — and because the /stage router passes
# the request, token included, to the skill it picks. Both are the user's token
# travelling on; a /goal wrapper never shows up as a STAGE <command-name>.
#
# The two forms count differently, on purpose. A typed STAGE command always
# counts, token or none — and with no <command-args> block at all, which some
# clients record for a bare command — so a bare `/stage-sect-drafter` falls back
# to .env: the user retracting the level by not repeating it. A Skill call counts only
# when its args carry an involve token: the model dispatching a skill on its own
# is not the user speaking, and a `stage-flow-status` it starts with no args
# must not reset a level the user set.
#
# Sidechain turns are skipped in both: a delegated subagent's invocation, and
# whatever it dispatches, is not the user's. A multi-line <command-args> block is
# read whole — jq's "m" flag is the one that lets `.` cross a newline — and comes
# back on one line, so the tail below keeps the whole block, not its last line.
stage__latest_stage_command_args() { # $1 = transcript path
    local transcript="$1"
    [ -n "${transcript}" ] && [ -r "${transcript}" ] || return 0
    if command -v jq >/dev/null 2>&1; then
        jq -r 'select(.isSidechain | not)
               | if .type == "user" then
                   ((.message.content) as $c
                    | (if ($c | type) == "string" then $c
                       else ([$c[]? | select(.type? == "text") | .text] | join(" ")) end)
                    | select(test("<command-name>[[:space:]]*/?stage"))
                    | ((capture("<command-args>(?<a>.*?)</command-args>"; "m").a) // ""))
                 elif .type == "assistant" then
                   (.message.content[]?
                    | select(.type? == "tool_use" and .name? == "Skill")
                    | select((.input.skill // "") | test("^stage"))
                    | (.input.args // "")
                    | select(test("(^|\\s)involve=(low|medium|high)(\\s|$)")))
                 else empty end
               | gsub("\\s+"; " ")' \
            "${transcript}" 2>/dev/null | tail -1
    elif command -v python3 >/dev/null 2>&1; then
        python3 - "${transcript}" <<'PY' 2>/dev/null
import json, re, sys

name = re.compile(r"<command-name>\s*/?stage")
args = re.compile(r"<command-args>(.*?)</command-args>", re.S)
token = re.compile(r"(?:^|\s)involve=(?:low|medium|high)(?:\s|$)")
last = ""
with open(sys.argv[1], errors="replace") as fh:
    for line in fh:
        try:
            entry = json.loads(line)
        except Exception:
            continue
        if entry.get("isSidechain"):
            continue
        content = (entry.get("message") or {}).get("content")
        if entry.get("type") == "user":
            if isinstance(content, str):
                text = content
            elif isinstance(content, list):
                text = " ".join(b.get("text", "") for b in content
                                if isinstance(b, dict) and b.get("type") == "text")
            else:
                continue
            if not name.search(text):
                continue
            found = args.search(text)
            last = found.group(1) if found else ""
        elif entry.get("type") == "assistant" and isinstance(content, list):
            for block in content:
                if not (isinstance(block, dict)
                        and block.get("type") == "tool_use"
                        and block.get("name") == "Skill"):
                    continue
                params = block.get("input") or {}
                if (str(params.get("skill") or "").startswith("stage")
                        and token.search(str(params.get("args") or ""))):
                    last = str(params.get("args") or "")
print(re.sub(r"\s+", " ", last))
PY
    fi
}

# `.env`'s INVOLVE when it names a level, and nothing when it is absent, unset,
# or invalid.
stage__env_involve() { # $1 = project root
    local line value
    line="$(grep -sE '^INVOLVE=' "$1/.env" | tail -1)"
    value="${line#INVOLVE=}"
    value="${value%%#*}"
    value="$(printf '%s' "${value}" | tr -cd '[:alpha:]')"
    case "${value}" in
        low|medium|high) printf '%s' "${value}" ;;
    esac
}

stage_involve_level() { # $1 = hook payload, $2 = project root
    local args level
    args="$(stage__latest_stage_command_args "$(stage__payload_field "$1" transcript_path)")"
    if [ -n "${args}" ]; then
        level="$(stage__involve_token "${args}")"
        [ -n "${level}" ] && { printf '%s' "${level}"; return 0; }
    fi
    level="$(stage__env_involve "$2")"
    printf '%s' "${level:-medium}"
}
