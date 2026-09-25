#!/usr/bin/env bash
# STAGE tool_call hook (Pi) — decline the git commands that break the writing
# workflow conventions §1 in the ways that are expensive to undo. It is the floor
# under INVOLVE=low, which answers the commit offer itself (§1.6, §7.7): with
# nobody reading the staged file list, blanket staging and history rewrites are
# what turn a cheap local commit into one that needs surgery to unpick.
#
# Declined: blanket or forced staging (add -A / . / ./ / * / :/ / -u / -f,
# commit -a / .), the history rewrites §1.3 names (commit --amend, rebase,
# reset --hard, filter-branch, filter-repo), the forced branch operations §1.3
# makes costly (branch -D / -f, switch -C / -f / --discard-changes,
# checkout -B / -f), the whole-tree discards that lose the same uncommitted work
# (checkout or restore of . / :/ / *, clean -f, stash drop / clear), any
# deletion or move of a tag (§1.4 — a freeze tag is the immutable record of what
# was submitted, and exactly one skill creates one), and an add or a commit that
# would stage a file over 10 MB — a build PDF, a raw figure export, or an
# evidence blob in history is a paper repository's one costly mistake, since
# clearing it back out needs exactly those rewrites. `push` is deliberately
# absent, except where it deletes or moves a tag on the remote (push --delete of
# a tag, a :<tag> refspec, a forced push of a tag or of --tags, a pruned or
# forced tag wildcard, --mirror) — a tag being a refs/tags/ or freeze/ name or
# one this clone holds: no rule here makes a skill likelier to push, and a user
# who asks for one directly should get it.
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
# runs, since Pi has no prompt to fall through to. The other way, a `;`, `&`,
# `|`, or parenthesis inside a quoted message still ends a segment, so a message
# quoting a declined command after one is declined with the line; a heredoc
# message (`git commit -F- <<'EOF'`) is read as data. The size check resolves
# pathspecs against the project root, so `cd manus && git add figs/x.pdf` is not
# sized, and reads a commit's `-- <paths>` only on the commit's own segment,
# which a `$(…)` message ends before them. What it declines is the user's to run.
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
# A quote or backslash may sit inside the word (`g''it`), so the letters are
# matched apart.
case "${cmd}" in
    *g*i*t*) ;;
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

# Paths over the limit, as a printable list; empty when none are. With no
# argument, the staged paths; with pathspecs, the files `git add` would stage
# for them, read before the line runs, since this hook fires first — a superset
# of what a commit naming those paths takes from the working tree, which leaves
# untracked files out. Pathspecs resolve against the project root.
staged_oversize() {
    local f size out=""
    while IFS= read -r -d '' f; do
        [[ -f "${root}/${f}" ]] || continue
        size="$(wc -c < "${root}/${f}" 2>/dev/null)" || continue
        size="${size//[[:space:]]/}"
        case "${size}" in ''|*[!0-9]*) continue ;; esac
        (( size > size_limit )) && out="${out:+${out}, }${f} ($((size / 1024 / 1024)) MB)"
    done < <(if [[ $# -gt 0 ]]; then
                 git -C "${root}" ls-files -z --others --modified --exclude-standard -- "$@"
             else
                 git -C "${root}" diff --cached --name-only -z
             fi 2>/dev/null)
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
        # A comment is not read: the line is kept up to its `#`.
        out="${out}${line:0:i}"$'\n'
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
# A body fed to a shell (`bash <<'EOF'`, `cat <<EOF | sh`) is that shell's
# commands, not data: when a shell stands in command position with no script to
# run, the bodies are read as commands too.
feeds_shell='(^|[;&|(])[[:space:]]*([^[:space:];&|()]*/)?(ba|z)?sh([[:space:]]+-[A-Za-z]+)*[[:space:]]*(<<|[;&|)]|$)'
[[ "${cmd//$'\n'/;}" =~ ${feeds_shell} ]] && cmd="${cmd}"$'\n'"${bodies}"
# A backslash-newline continues the line, so `git push --delete origin \⏎ tag`
# is one push — joined after the bodies are dropped, as stage_bash_gate.sh does.
bsnl=$'\\\n'
cmd="${cmd//"${bsnl}"/ }"

# Whether a word a push names is a tag: spelled as one (`refs/tags/…`), or the
# name of a tag here. A `+` (force) prefix and a refspec's source side are
# dropped first — `:freeze/x` and `+HEAD:freeze/x` both name freeze/x.
names_tag() { # $1 = one word of a push command line
    local name="${1#+}"
    name="${name##*:}"
    [[ -n "${name}" ]] || return 1
    case "${name}" in
        refs/tags/*|tags/*|freeze/*) return 0 ;;
        # A wildcard over the whole of refs/ reaches every tag.
        refs/\**) return 0 ;;
        refs/*) return 1 ;;
    esac
    [[ -n "$(git -C "${root}" tag -l -- "${name}" 2>/dev/null)" ]]
}

# Sets vq to the quote a raw word opens and does not close, so the words a
# quoted option value spans are skipped with it.
open_quote() { # $1 = one word as written, quotes kept
    local pre="${1%%[\"\']*}" q
    q="${1:${#pre}:1}"
    [[ -n "${q}" ]] || return 0
    [[ "${1:${#pre}+1}" == *"${q}"* ]] || vq="${q}"
}

# One shell line can carry several commands, so each is read on its own: `cd x &&
# git add -A` is the add it looks like.
while IFS= read -r segment; do
    read -ra tok <<< "${segment}"
    [[ ${#tok[@]} -gt 0 ]] || continue
    raw=("${tok[@]}")
    # The shell drops every quote and backslash before it runs a word: `\git`
    # (the usual way past an alias), `g''it`, and `"git"` are all git, and
    # `add "."` is the add `add .` is. Each word sheds them, and the `$` of a
    # `$'…'` with them.
    for ((k = 0; k < ${#tok[@]}; k++)); do
        tok[k]="${tok[k]//\$\'/\'}"; tok[k]="${tok[k]//\$\"/\"}"
        tok[k]="${tok[k]//[\'\"\\]/}"
    done
    # Walk past what runs a command without being one — an assignment
    # (`GIT_SEQUENCE_EDITOR=: git rebase -i`, the usual non-interactive
    # spelling), a wrapper and the value its option takes, a shell keyword — as
    # stage_bash_gate.sh does, so `env git add -A` is the add it carries, and
    # `sudo git add -A` or `xargs git add -A` too.
    w=0
    prev=""
    dur=""
    while [[ ${w} -lt ${#tok[@]} ]]; do
        case "${prev}:${tok[w]}" in
            env:-u|env:-C|nice:-n|exec:-a|time:-f|time:-o) w=$((w + 2)); continue ;;
            sudo:-[ugCDphrtTUR]|sudo:--user|sudo:--group|sudo:--host|sudo:--prompt|sudo:--chdir|sudo:--role|sudo:--type)
                w=$((w + 2)); continue ;;
            xargs:-[IJLnPsEdaRS]|xargs:--max-args|xargs:--max-procs|xargs:--max-lines|xargs:--arg-file|xargs:--delimiter|xargs:--eof|xargs:--replace)
                w=$((w + 2)); continue ;;
            timeout:-[sk]|timeout:--signal|timeout:--kill-after|stdbuf:-[ioe]) w=$((w + 2)); continue ;;
            sudo:--close-from|sudo:--command-timeout|sudo:--other-user|sudo:--chroot|doas:-[aCu]|caffeinate:-[tw])
                w=$((w + 2)); continue ;;
        esac
        # timeout's duration is its first operand, not the command.
        if [[ "${prev}" == timeout && -z "${dur}" && "${tok[w]}" != -* ]]; then
            dur=1; w=$((w + 1)); continue
        fi
        case "${tok[w]}" in
            *=*|-*) w=$((w + 1)); continue ;;
        esac
        case "${tok[w]##*/}" in
            env|command|exec|nohup|time|nice|sudo|doas|xargs|timeout|gtimeout|stdbuf|caffeinate|eval|sh|bash|zsh|if|then|else|elif|do|while|until|'!'|'{')
                prev="${tok[w]##*/}"; [[ "${prev}" == gtimeout ]] && prev=timeout; w=$((w + 1)) ;;
            *) break ;;
        esac
    done
    tok=("${tok[@]:w}")
    raw=("${raw[@]:w}")
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
                arg="${tok[j]}"
                case "${arg}" in
                    -A|--all|-u|--update|--no-ignore-removal|.|./|:/|:/*|'*')
                        deny "STAGE conventions §1.1: a blanket add stages work this run did not do, and it sweeps in build litter, half-registered evidence, and the user's own uncommitted edits. Stage the paths this run wrote, by name." ;;
                    -f|--force)
                        deny "STAGE conventions §1.2: a force-add puts a git-ignored path — .env, a build under wkdrs/ — into history. Stage a tracked path instead." ;;
                    --*) ;;
                    -*[Auf]*)
                        deny "STAGE conventions §1.1 and §1.2: this flag cluster carries a blanket or forced add. Stage the paths this run wrote, by name." ;;
                esac
            done
            if [[ ${#tok[@]} -gt $((i + 1)) ]]; then
                big="$(staged_oversize "${tok[@]:i+1}")"
                [[ -n "${big}" ]] && \
                    deny "STAGE conventions §1.2: over 10 MB — ${big}. Builds and large assets belong in wkdrs/ or in mates/ by import, and clearing one back out of history needs a rewrite §1.3 forbids, so leave it unstaged."
            fi
            ;;
        commit)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    -m|--message|-F|--file|-t|--template|--fixup|--squash|-C|--reuse-message|--reedit-message|-m*|--message=*|--file=*)
                        break ;;
                    .|./|:/)
                        deny "STAGE conventions §1.1: a commit naming the whole tree commits every tracked modification under it, including work this run did not do. Stage the paths this run wrote, by name, then commit without it." ;;
                    --am*)
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
            # A commit naming its paths (`commit -m x -- <paths>`, the form §1.5
            # asks for) takes them from the working tree, staged or not, so the
            # index alone does not show what it commits.
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                [[ "${tok[j]}" == -- ]] || continue
                if [[ ${#tok[@]} -gt $((j + 1)) ]]; then
                    big="$(staged_oversize "${tok[@]:j+1}")"
                    [[ -n "${big}" ]] && \
                        deny "STAGE conventions §1.2: over 10 MB — ${big}. A commit naming a path takes it from the working tree, staged or not. Builds and large assets belong in wkdrs/ or in mates/ by import, and clearing one back out of history needs a rewrite §1.3 forbids, so leave it out of the commit."
                fi
                break
            done
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
        push)
            # Pushing stays the user's and the prompt's, except where the push
            # deletes or moves a tag on the remote, which §1.4 closes as firmly
            # as a local `tag -d`: `--delete` of a tag, a `:<tag>` refspec, a
            # forced or `+` push of a tag, a forced or pruning `--tags` or tag
            # wildcard, and `--mirror`, which force-updates and prunes every
            # remote tag at once. Git takes any unambiguous prefix of a long
            # option (`--del`, `--mirr`), so those are read by prefix. The
            # first operand is the remote, never a ref; a value option's word
            # is skipped.
            del=0; force=0; tags=0; prune=0; want_v=0; dry=0; mirror=0; vq=""
            refs=()
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                # A quoted option value can span words (`-o "title=Fix tag x"`).
                if [[ -n "${vq}" ]]; then [[ "${raw[j]}" == *"${vq}"* ]] && vq=""; continue; fi
                if (( want_v )); then want_v=0; open_quote "${raw[j]}"; continue; fi
                case "${arg}" in
                    -o|--push-option|--repo|--receive-pack|--exec) want_v=1 ;;
                    -o*|--push-option=*|--repo=*|--receive-pack=*|--exec=*) open_quote "${raw[j]}" ;;
                    -n|--dr*) dry=1 ;;
                    -d|--de*) del=1 ;;
                    # --force-if-includes forces nothing alone; a lease with a
                    # value forces only the ref it names.
                    --force-i*) ;;
                    --force-w*=*:*) lease="${arg#*=}"; names_tag "${lease%%:*}" && force=1 ;;
                    -f|--forc*) force=1 ;;
                    --ta*) tags=1 ;;
                    --pru*) prune=1 ;;
                    --m*) mirror=1 ;;
                    --*) ;;
                    -*) [[ "${arg}" == *d* ]] && del=1; [[ "${arg}" == *f* ]] && force=1; [[ "${arg}" == *n* ]] && dry=1 ;;
                    *) refs+=("${arg}") ;;
                esac
            done
            # A dry run changes nothing on the remote.
            (( dry )) && continue
            (( mirror )) && \
                deny "STAGE conventions §1.4: push --mirror force-updates and prunes every tag on the remote, and a freeze tag is the immutable record of what was submitted. Push the branch by name."
            [[ ${tags} -eq 1 && ( ${force} -eq 1 || ${prune} -eq 1 ) ]] && \
                deny "STAGE conventions §1.4: a forced or pruning push of --tags moves or deletes tags on the remote, and a freeze tag is the immutable record of what was submitted. Push new tags without forcing."
            for ((j = 1; j < ${#refs[@]}; j++)); do
                arg="${refs[j]}"
                # `tag <name>` names a tag, but refs[0] is the remote.
                [[ ${j} -ge 2 && "${refs[j - 1]}" == tag ]] || names_tag "${arg}" || continue
                if [[ ${del} -eq 1 || "${arg}" == :* || ( ${prune} -eq 1 && "${arg}" == *'*'* ) ]]; then
                    deny "STAGE conventions §1.4: this push deletes a tag on the remote — ${arg} — and a freeze tag is the immutable record of what was submitted. Leave it in place."
                fi
                if [[ ${force} -eq 1 || "${arg}" == +* ]]; then
                    deny "STAGE conventions §1.4: a forced push of a tag moves it on the remote — ${arg} — and a freeze tag is the immutable record of what was submitted. Leave it where it is."
                fi
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
                    --*) ;;
                    -*[Cf]*)
                        deny "STAGE conventions §1.3: this flag cluster carries a forced switch or a branch reset. The user owns the branch." ;;
                esac
            done
            ;;
        checkout)
            paths=0
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    .|./|:/|'*')
                        deny "STAGE conventions §1.3: a checkout of the whole tree discards uncommitted work, including anything the user had in the tree. Name the paths to restore." ;;
                esac
                # After `--` every word is a path, never a flag.
                [[ ${paths} -eq 1 ]] && continue
                case "${arg}" in
                    --) paths=1 ;;
                    -B)
                        deny "STAGE conventions §1.3: checkout -B resets an existing branch to another commit — a history rewrite in effect. Pick a fresh branch name." ;;
                    -f|--force)
                        deny "STAGE conventions §1.3: a forced checkout discards uncommitted work, including anything the user had in the tree." ;;
                    --*) ;;
                    -*[fB]*)
                        deny "STAGE conventions §1.3: this flag cluster carries a forced checkout or a branch reset. The user owns the branch." ;;
                esac
            done
            ;;
        restore)
            # Only unstaging (--staged without --worktree) leaves the tree alone.
            staged=0; worktree=0; paths=0
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                arg="${tok[j]}"
                case "${arg}" in
                    .|./|:/|'*') paths=1 ;;
                    -S|--staged) staged=1 ;;
                    -W|--worktree) worktree=1 ;;
                    --*) ;;
                    -*) [[ "${arg}" == *S* ]] && staged=1; [[ "${arg}" == *W* ]] && worktree=1 ;;
                esac
            done
            [[ ${paths} -eq 1 && ( ${worktree} -eq 1 || ${staged} -eq 0 ) ]] && \
                deny "STAGE conventions §1.3: restoring the whole working tree discards uncommitted work, including anything the user had in the tree. Name the paths to restore; restore --staged alone only unstages."
            ;;
        clean)
            for ((j = i + 1; j < ${#tok[@]}; j++)); do
                case "${tok[j]}" in
                    --force)
                        deny "STAGE conventions §2: git clean deletes untracked files for good — mates/ imports stage-evid-curator leaves uncommitted for the user (§1), and with -x .env." ;;
                    --*) ;;
                    -*f*)
                        deny "STAGE conventions §2: git clean deletes untracked files for good — mates/ imports stage-evid-curator leaves uncommitted for the user (§1), and with -x .env." ;;
                esac
            done
            ;;
        stash)
            case "${tok[i + 1]:-}" in
                drop|clear)
                    deny "STAGE conventions §1.5: a dropped stash is gone for good, and the user's own uncommitted work is what §1.5 sends there." ;;
            esac
            ;;
    esac
done < <(printf '%s\n' "${cmd}" | tr ';&|()' '\n\n\n\n\n')

exit 0
