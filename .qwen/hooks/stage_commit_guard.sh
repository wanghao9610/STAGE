#!/usr/bin/env bash
# STAGE PreToolUse hook (Qwen Code) — decline the git commands that break the
# writing workflow conventions §1 in the ways that are expensive to undo. It is
# the floor under INVOLVE=low, which answers the commit offer itself (§1.6,
# §7.7): with nobody reading the staged file list, blanket staging and history
# rewrites are what turn a cheap local commit into one that needs surgery to
# unpick.
#
# Declined: blanket or forced staging (add -A / . / * / :/ / -u / -f, commit -a),
# the history rewrites §1.3 names (commit --amend, rebase, reset --hard,
# filter-branch, filter-repo), the forced branch operations §1.3 makes costly
# (branch -D / -f, switch -C / -f / --discard-changes, checkout -B / -f), any
# deletion or move of a tag (§1.4 — a freeze tag is the immutable record of what
# was submitted, and exactly one skill creates one), and a commit whose staged
# files exceed 10 MB — a build PDF, a raw figure export, or an evidence blob in
# history is a paper repository's one costly mistake, since clearing it back out
# needs exactly those rewrites. `push` is deliberately absent: no rule here makes
# a skill likelier to push, and a user who asks for one directly should get it.
#
# Registered under PreToolUse matching run_shell_command in .qwen/settings.json —
# the matcher names the tool identifier, not the display name, so `Shell` there
# would match nothing and say nothing. One of seven copies — Claude, Codex and
# Kimi Code carry the same guard on their own PreToolUse, Cursor on
# beforeShellExecution, DSH through its Claude Code hook bridge, and Pi on
# tool_call — differing only in how each harness names the command on the way in
# and the decision on the way out.
#
# A floor, not a proof. It reads one shell line at a time and cannot resolve
# quoting, so a flag written after a commit message (`commit -m x --amend`) is
# past where it stops reading. Silence means "no decision", so that case, an
# unfamiliar spelling, and a payload no branch below can read all fall through to
# the normal permission flow. What it declines is the user's to run.
set -uo pipefail

# Every harness registers this script by its own path inside the project, so the
# project root is two levels up from the script itself — no environment variable
# and no payload field, which differ per harness.
root="$(cd -- "$(dirname -- "$0")/../.." 2>/dev/null && pwd -P)" || exit 0

input=$(cat)

# The shell command, from run_shell_command's tool_input.
command_text() {
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "${input}" | jq -r '.tool_input.command // empty' 2>/dev/null
    elif command -v python3 >/dev/null 2>&1; then
        printf '%s' "${input}" | python3 -c 'import sys, json
try:
    print((json.load(sys.stdin).get("tool_input") or {}).get("command") or "")
except Exception:
    print("")' 2>/dev/null
    else
        # No parser on PATH. Reading the field out of the raw JSON stops at the
        # first escaped quote, so a command carrying one is read only up to it —
        # shorter than the truth, never different from it, and the flags this
        # guard matches sit in the leading tokens of each segment. Without this
        # branch the guard reads an empty command and declines nothing.
        printf '%s' "${input}" \
            | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' \
            | head -1 | sed -E 's/.*"([^"]*)"$/\1/'
    fi
}

cmd="$(command_text)"
# A quote or backslash may sit inside the word (`g''it`), so the letters are
# matched apart.
case "${cmd}" in
    *g*i*t*) ;;
    *) exit 0 ;;
esac

# The reason reaches the agent as JSON, so it carries no quote and no backslash.
deny() { # $1 = one-line reason
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s (declined by .qwen/hooks/stage_commit_guard.sh — hand it to the user to run)"}}\n' "$1"
    exit 0
}

# 10 MB. No tex source, note, or bibliography comes near it; a build PDF or a
# raw figure export clears it easily.
size_limit=$((10 * 1024 * 1024))

# Staged paths over the limit, as a printable list. Empty when none are.
staged_oversize() {
    local f size out=""
    while IFS= read -r -d '' f; do
        [[ -f "${root}/${f}" ]] || continue
        size="$(wc -c < "${root}/${f}" 2>/dev/null)" || continue
        size="${size//[[:space:]]/}"
        case "${size}" in ''|*[!0-9]*) continue ;; esac
        (( size > size_limit )) && out="${out:+${out}, }${f} ($((size / 1024 / 1024)) MB)"
    done < <(git -C "${root}" diff --cached --name-only -z 2>/dev/null)
    printf '%s' "${out}"
}

# A heredoc body is data, not commands: a commit message's line that reads like
# a declined git command is not that command. Each body is dropped through its
# delimiter before the segments are read, by the reader stage_bash_gate.sh uses
# (CI holds the two copies equal); a `<<` it cannot place leaves the lines after
# it to be read as commands, never hidden.
bodies=""
strip_heredocs() {
    # st is a stack of quoting contexts, innermost last: n unquoted (the line,
    # or a `$(…)` / `(…)` inside it), b a backtick substitution, d double
    # quotes, s single quotes, a an ANSI-C $'…', m arithmetic (`$((…))` or
    # `((…))`), r a parenthesis inside it, p a parameter expansion `${…}`.
    local line rest delim="" body=0 out="" held="" st="n" found i n c
    while IFS= read -r line; do
        if (( body )); then
            if [[ "${line}" == "${delim}" || "${line//$'\t'/}" == "${delim}" ]]; then
                body=0
                bodies="${bodies}${held}"
                held=""
            else
                held="${held}${line}"$'\n'
            fi
            continue
        fi
        out="${out}${line}"$'\n'
        found=0
        rest=""
        n=${#line}
        for ((i = 0; i < n; i++)); do
            c="${line:i:1}"
            case "${st: -1}" in
                s)
                    [[ "${c}" == "'" ]] && st="${st%?}" ;;
                a)
                    if [[ "${c}" == '\' ]]; then i=$((i + 1))
                    elif [[ "${c}" == "'" ]]; then st="${st%?}"; fi ;;
                d)
                    case "${c}" in
                        '\') i=$((i + 1)) ;;
                        '"') st="${st%?}" ;;
                        '`') st="${st}b" ;;
                        '$')
                            case "${line:i+1:2}" in
                                '((') st="${st}m"; i=$((i + 2)) ;;
                                '('*) st="${st}n"; i=$((i + 1)) ;;
                                '{'*) st="${st}p"; i=$((i + 1)) ;;
                            esac ;;
                    esac ;;
                m|r|p)
                    # A `<<` in here is a shift or a pattern: it opens nothing.
                    case "${c}" in
                        '\') i=$((i + 1)) ;;
                        "'") st="${st}s" ;;
                        '"') st="${st}d" ;;
                        '`') st="${st}b" ;;
                        '$')
                            case "${line:i+1:2}" in
                                '((') st="${st}m"; i=$((i + 2)) ;;
                                '('*) st="${st}n"; i=$((i + 1)) ;;
                                '{'*) st="${st}p"; i=$((i + 1)) ;;
                                "'"*) st="${st}a"; i=$((i + 1)) ;;
                            esac ;;
                        '(') [[ "${st: -1}" == p ]] || st="${st}r" ;;
                        ')')
                            case "${st: -1}" in
                                r) st="${st%?}" ;;
                                m) [[ "${line:i+1:1}" == ')' ]] && { st="${st%?}"; i=$((i + 1)); } ;;
                            esac ;;
                        '}') [[ "${st: -1}" == p ]] && st="${st%?}" ;;
                    esac ;;
                *)
                    case "${c}" in
                        '\') i=$((i + 1)) ;;
                        "'") st="${st}s" ;;
                        '"') st="${st}d" ;;
                        '`') if [[ "${st: -1}" == b ]]; then st="${st%?}"; else st="${st}b"; fi ;;
                        '$')
                            case "${line:i+1:2}" in
                                '((') st="${st}m"; i=$((i + 2)) ;;
                                '('*) st="${st}n"; i=$((i + 1)) ;;
                                '{'*) st="${st}p"; i=$((i + 1)) ;;
                                "'"*) st="${st}a"; i=$((i + 1)) ;;
                            esac ;;
                        '(')
                            if [[ "${line:i+1:1}" == '(' ]]; then st="${st}m"; i=$((i + 1)); else st="${st}n"; fi ;;
                        ')') [[ ${#st} -gt 1 && "${st: -1}" == n ]] && st="${st%?}" ;;
                        '#')
                            # A comment runs to the end of the line.
                            (( i == 0 )) && break
                            case "${line:i-1:1}" in [[:space:]]|';'|'&'|'|'|'('|')'|'<'|'>') break ;; esac ;;
                        '<')
                            if [[ "${line:i+1:1}" == '<' ]]; then
                                if [[ "${line:i+2:1}" == '<' ]]; then
                                    i=$((i + 2))
                                else
                                    found=1; rest="${line:i+2}"; i=$((i + 1))
                                fi
                            fi ;;
                    esac ;;
            esac
        done
        (( found )) || continue
        rest="${rest#-}"
        read -r delim rest <<< "${rest}" || delim=""
        delim="${delim#\'}"; delim="${delim%\'}"; delim="${delim#\"}"; delim="${delim%\"}"
        case "${delim}" in
            [A-Za-z_]*[!A-Za-z0-9_]*) ;;
            [A-Za-z_]*) body=1 ;;
        esac
    done <<< "${cmd}"
    cmd="${out}${held}"
}
strip_heredocs

# One shell line can carry several commands, so each is read on its own: `cd x &&
# git add -A` is the add it looks like.
while IFS= read -r segment; do
    read -ra tok <<< "${segment}"
    [[ ${#tok[@]} -gt 0 ]] || continue
    # The shell drops every quote and backslash before it runs a word: `\git`
    # (the usual way past an alias), `g''it`, and `"git"` are all git, and
    # `add "."` is the add `add .` is. Each word sheds them, and the `$` of a
    # `$'…'` with them.
    for ((k = 0; k < ${#tok[@]}; k++)); do
        tok[k]="${tok[k]//\$\'/\'}"; tok[k]="${tok[k]//\$\"/\"}"
        tok[k]="${tok[k]//[\'\"\\]/}"
    done
    case "${tok[0]}" in
        git|*/git) ;;
        *) continue ;;
    esac

    # Walk past git's own options — `git -C dir add` names its subcommand third.
    i=1
    while [[ ${i} -lt ${#tok[@]} ]]; do
        case "${tok[i]}" in
            -C|-c|--git-dir|--work-tree|--namespace|--exec-path) i=$((i + 2)) ;;
            -*) i=$((i + 1)) ;;
            *) break ;;
        esac
    done
    [[ ${i} -lt ${#tok[@]} ]] || continue

    case "${tok[i]}" in
        add)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    -A|--all|-u|--update|--no-ignore-removal|.|:/|:/*|'*')
                        deny "STAGE conventions §1.1: a blanket add stages work this run did not do, and it sweeps in build litter, half-registered evidence, and the user's own uncommitted edits. Stage the paths this run wrote, by name." ;;
                    -f|--force)
                        deny "STAGE conventions §1.2: a force-add puts a git-ignored path — .env, a build under wkdrs/ — into history. Stage a tracked path instead." ;;
                    --*) ;;
                    -*[Auf]*)
                        deny "STAGE conventions §1.1 and §1.2: this flag cluster carries a blanket or forced add. Stage the paths this run wrote, by name." ;;
                esac
            done
            ;;
        commit)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    -m|--message|-F|--file|-t|--template|--fixup|--squash|-C|--reuse-message|--reedit-message|-m*|--message=*|--file=*)
                        break ;;
                    --amend)
                        deny "STAGE conventions §1.3: no history rewrites — the user owns the branch and the remote, and a freeze tag points at a commit that must not move. Make a new commit instead." ;;
                    --all)
                        deny "STAGE conventions §1.1: commit --all stages every tracked modification, including work this run did not do. Stage the paths this run wrote, by name, then commit without it." ;;
                    --*) ;;
                    -*a*)
                        deny "STAGE conventions §1.1: commit -a stages every tracked modification, including work this run did not do. Stage the paths this run wrote, by name, then commit without -a." ;;
                esac
            done
            big="$(staged_oversize)"
            [[ -n "${big}" ]] && \
                deny "STAGE conventions §1.2: staged over 10 MB — ${big}. Builds and large assets belong in wkdrs/ or in mates/ by import, and clearing one back out of history needs a rewrite §1.3 forbids, so unstage it first."
            ;;
        rebase)
            deny "STAGE conventions §1.3: no history rewrites — the user owns the branch and the remote." ;;
        filter-branch|filter-repo)
            deny "STAGE conventions §1.3: no history rewrites — the user owns the branch and the remote." ;;
        reset)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                [[ "${tok[j]}" == --hard ]] && \
                    deny "STAGE conventions §1.3: reset --hard discards uncommitted work, including anything the user had in the tree."
            done
            ;;
        tag)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    -d|--delete)
                        deny "STAGE conventions §1.4: a freeze tag is the immutable record of what was submitted — no skill deletes one." ;;
                    -f|--force)
                        deny "STAGE conventions §1.4: moving a tag rewrites what a submission record points at. Leave the freeze tag where it is." ;;
                    --*) ;;
                    -*[df]*)
                        deny "STAGE conventions §1.4: this flag cluster deletes or moves a tag, and a freeze tag is the immutable record of what was submitted." ;;
                esac
            done
            ;;
        branch)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    -D|--delete-force)
                        deny "STAGE conventions §1.3: a force-deleted branch takes its unmerged commits with it, and the branch is the user's. A merged branch deletes with -d." ;;
                    -f|--force)
                        deny "STAGE conventions §1.3: forcing a branch onto another commit rewrites where its history points. Create a new branch instead." ;;
                    --*) ;;
                    -*[Df]*)
                        deny "STAGE conventions §1.3: this flag cluster carries a forced branch delete or move. The user owns the branch." ;;
                esac
            done
            ;;
        switch)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    -C|--force-create)
                        deny "STAGE conventions §1.3: switch -C resets an existing branch to another commit — a history rewrite in effect. Pick a fresh branch name." ;;
                    -f|--force|--discard-changes)
                        deny "STAGE conventions §1.3: a forced switch discards uncommitted work, including anything the user had in the tree." ;;
                esac
            done
            ;;
        checkout)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    --) break ;;
                    -B)
                        deny "STAGE conventions §1.3: checkout -B resets an existing branch to another commit — a history rewrite in effect. Pick a fresh branch name." ;;
                    -f|--force)
                        deny "STAGE conventions §1.3: a forced checkout discards uncommitted work, including anything the user had in the tree." ;;
                esac
            done
            ;;
    esac
done < <(printf '%s\n' "${cmd}" | tr ';&|()' '\n\n\n\n\n')

exit 0
