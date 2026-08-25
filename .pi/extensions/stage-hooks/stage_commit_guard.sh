#!/usr/bin/env bash
# STAGE tool_call hook (Pi) — decline the git commands that break the writing
# workflow conventions §1 in the ways that are expensive to undo. It is the floor
# under INVOLVE=low, which answers the commit offer itself (§1.6, §7.7): with
# nobody reading the staged file list, blanket staging and history rewrites are
# what turn a cheap local commit into one that needs surgery to unpick.
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
# Wired to Pi's tool_call event, narrowed to the bash tool, in
# .pi/extensions/stage-hooks/index.ts. One of seven copies — Claude, Codex, Kimi
# Code and Qwen Code carry the same guard on their own PreToolUse, Cursor on
# beforeShellExecution, DSH through its Claude Code hook bridge — differing only
# in how each harness names the command on the way in and the decision on the way
# out. This one is also the guard's whole job here: Pi ships no permission
# prompts at all, so nothing else stands between a git command and the
# repository.
#
# A floor, not a proof. It reads one shell line at a time and cannot resolve
# quoting, so a flag written after a commit message (`commit -m x --amend`) is
# past where it stops reading. Silence means "no decision", so that case and an
# unfamiliar spelling both let the command through — here that means it simply
# runs, since Pi has no prompt to fall through to. What it declines is the user's
# to run.
set -uo pipefail

# Every harness registers this script by its own path inside the project, so the
# project root is derived from the script itself — no environment variable and no
# payload field, which differ per harness. Three levels here, not the other trees'
# two: Pi reserves .pi/hooks/ as the old name for extensions and warns when it
# exists, so these scripts live beside the extension that runs them, one directory
# deeper (.pi/extensions/stage-hooks/).
root="$(cd -- "$(dirname -- "$0")/../../.." 2>/dev/null && pwd -P)" || exit 0

# The shell command, passed as the one argument. Pi has no command-hook protocol
# to parse a payload out of: .pi/extensions/stage-hooks/index.ts reads the bash tool's
# own input object and hands the command straight over.
cmd="${1:-}"
case "${cmd}" in
    *git*) ;;
    *) exit 0 ;;
esac

# The reason goes out on stdout and the refusal is the exit status, so this copy
# needs no encoder — the extension is what turns the pair into Pi's block result.
deny() { # $1 = one-line reason
    printf '%s (declined by .pi/extensions/stage-hooks/stage_commit_guard.sh — hand it to the user to run)\n' "$1"
    exit 1
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

# One shell line can carry several commands, so each is read on its own: `cd x &&
# git add -A` is the add it looks like.
while IFS= read -r segment; do
    read -ra tok <<< "${segment}"
    [[ ${#tok[@]} -gt 0 ]] || continue
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
                # `git add "."` is the instruction `git add .` is; word splitting
                # keeps the quotes, so one pair comes off before matching.
                arg="${tok[j]}"
                case "${arg}" in
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
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
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
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
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
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
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
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
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
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
                    \'*\'|\"*\") arg="${arg#?}"; arg="${arg%?}" ;;
                esac
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
