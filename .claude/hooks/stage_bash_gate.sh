#!/usr/bin/env bash
# Skip Claude's permission prompt for shell commands while the project runs at
# involve=low (writing workflow conventions §7.7) — the shell counterpart of
# stage_involve_gate.sh, so a low run is not parked at a prompt for every
# lint.sh, grep, latexmk, or `git add` by name. STAGE's red lines keep their
# prompt at every level, and this gate stays silent on them so the normal
# permission flow takes over:
#
#   - deletion: rm and its kin, find -delete / -exec, git rm, git clean, git
#     worktree remove / prune;
#   - an overwrite of a tracked file: a forced mv / cp / ln, an install, one
#     landing on a tracked file or pouring a directory's contents over one, a
#     `>` redirection in any spelling (`>|`, `>!`, `>&file`), a tee, a curl or
#     wget download, or an rsync onto one, git checkout, a git restore of the
#     working tree, execs/update.sh outside --diff;
#   - a write, move, or delete naming mates/ other than through
#     execs/scpts/import.sh, its sanctioned writer (§10.1), or run from inside
#     it; anything but a read naming a venue kit under cycls/*/template/ (§10.4)
#     or .env, or run from inside a kit;
#   - git push and pull, git stash drop / clear, branch switches, every tag
#     operation but listing (§1.4), reflog expiry and object pruning, and the
#     commands stage_commit_guard.sh declines — history rewrites, blanket or
#     forced staging, forced branch operations;
#   - installs (§3.5): sudo and system or TeX package managers (tlmgr), and a
#     language package manager's install;
#   - what crosses the STOP line on its face (§2): outward sends (scp, ssh,
#     rsync to a host, a curl or wget upload, gh beyond reading, mail) and job
#     launches (sbatch, srun, qsub, bsub);
#   - disk and device writes, process kills, service control, kernel modules,
#     crontab, and a shell reading its commands from a pipe or a process
#     substitution (`curl … | bash`, `source <(curl …)`).
#
# Confirmation points are untouched: the STOP line, deletions and overwrites,
# and every venue.yml value entering as confirmed (§9c) are questions a skill
# asks, not permission prompts a hook can answer. stage_commit_guard.sh runs
# beside this gate on the same matcher and its deny outranks this allow.
#
# A floor, not a proof. It reads one shell line at a time and resolves quoting
# only far enough to find a heredoc; a path reached through a variable, an
# alias, or a script's own code is not seen, so `python3 x.py` that writes
# under mates/ passes when its command line names no protected path, and an
# archive unpacked into the tree (`unzip -o`, `tar -x`) can overwrite tracked
# files unseen. After a `cd` it
# cannot follow — into `$(…)`, a variable other than $CLAUDE_PROJECT_DIR, or
# `-` — every relative path counts as tracked, so a redirection or a landing
# there keeps its prompt. A heredoc body is data, but one that names a
# protected path makes every command on its line that is not a reader keep its
# prompt. Write and Edit reach mates/ through stage_involve_gate.sh, which
# keeps its prompt there too, and stage-evid-curator `check` re-hashes every
# registered file. Silence means "no decision", so every red line, every other
# level, a payload it cannot read, and a project that sets no level all fall
# through to the normal permission flow. The level comes from
# stage_involve_level.sh — the `involve=` token of the session's most recent
# STAGE command, or `.env`'s INVOLVE when it carried none — and is resolved on
# each call, so a new invocation, or an edit to .env, takes effect without a
# restart.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-${PWD}}"

# The payload is read before the level is tested: it carries the transcript path
# the level is resolved from, and a hook that exits without reading stdin leaves
# the runtime's write to fail.
input=$(cat)

. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/stage_involve_level.sh"
involve="$(stage_involve_level "${input}" "${root}")"
[[ "${involve}" == "low" ]] || exit 0

# A payload field: the shell command (tool_input.command) or the directory it
# runs in (cwd). No parser on PATH: an allow read out of a misparsed payload
# could cover a red line, so an unreadable command keeps its prompt.
payload() { # $1 = command | cwd
    if command -v jq >/dev/null 2>&1; then
        case "$1" in
            command) printf '%s' "${input}" | jq -r '.tool_input.command // empty' 2>/dev/null ;;
            cwd) printf '%s' "${input}" | jq -r '.cwd // empty' 2>/dev/null ;;
        esac
    elif command -v python3 >/dev/null 2>&1; then
        printf '%s' "${input}" | python3 -c 'import sys, json
try:
    d = json.load(sys.stdin)
    v = (d.get("tool_input") or {}).get("command") if sys.argv[1] == "command" else d.get("cwd")
    print(v or "")
except Exception:
    print("")' "$1" 2>/dev/null
    fi
}

cmd="$(payload command)"
[[ -n "${cmd}" ]] || exit 0

# Relative paths resolve against the directory the command runs in; a `cd` on
# the line moves it, and one this gate cannot follow leaves it unknown.
base="$(payload cwd)"
[[ -n "${base}" && -d "${base}" ]] || base="${root}"

# A heredoc body is data, not commands — a commit-message line reading "rm old
# code" is not the rm it spells. Drop each body through its delimiter before
# the segments are read, keeping the bodies aside. Only a `<<` the shell would
# read as an operator opens one: not inside quotes, not after a comment's `#`,
# and not a here-string's <<<. Quotes are followed across lines and into a
# `$(…)` inside double quotes, where a commit message's heredoc sits. Only a
# bare-word delimiter (EOF-shaped) counts, so an arithmetic x<<2 cannot swallow
# the lines after it and hide a real command, and a body that never meets its
# delimiter is read again line by line; anything malformed errs toward the
# prompt, never past it.
bodies=""
strip_heredocs() {
    # st is a stack of quoting contexts, innermost last: n unquoted (the line,
    # or a `$(…)` / `(…)` inside it), b a backtick substitution, d double
    # quotes, s single quotes, a an ANSI-C $'…'.
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
                        '$') [[ "${line:i+1:1}" == '(' ]] && { st="${st}n"; i=$((i + 1)); } ;;
                    esac ;;
                *)
                    case "${c}" in
                        '\') i=$((i + 1)) ;;
                        "'") st="${st}s" ;;
                        '"') st="${st}d" ;;
                        '`') if [[ "${st: -1}" == b ]]; then st="${st%?}"; else st="${st}b"; fi ;;
                        '$')
                            case "${line:i+1:1}" in
                                '(') st="${st}n"; i=$((i + 1)) ;;
                                "'") st="${st}a"; i=$((i + 1)) ;;
                            esac ;;
                        '(') st="${st}n" ;;
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
# A backslash-newline continues the line, so `git \⏎ push` is one push. Joined
# after the bodies are dropped: a quoted body may end a line with a backslash.
bsnl=$'\\\n'
cmd="${cmd//"${bsnl}"/ }"
[[ -n "${cmd//[[:space:]]/}" ]] || exit 0
# The overwriting redirections the segment split below would tear apart: `>|`
# (past noclobber) and zsh's `>!` are a plain `>`, and `>&` keeps a marker in
# place of its `&`, so `>&file` is read as the write it is while `2>&1` stays a
# descriptor.
dup=$'\x1f'
cmd="${cmd//'>|'/>}"
cmd="${cmd//'>!'/>}"
cmd="${cmd//'>&'/>${dup}}"

# The protected paths: the evidence under mates/ (§10.1), a venue kit under
# cycls/<cycle>/template/ (§10.4), and .env. A word counts from after its last
# `=` or `:`, so --data=mates/x and HEAD:mates/x are the path they carry.
protected() { # $1 = a word, quotes shed
    local p="${1##*[=:]}"
    case "${p}" in
        mates|mates/*|*/mates|*/mates/*) return 0 ;;
        cycls/*/template|cycls/*/template/*|*/cycls/*/template|*/cycls/*/template/*) return 0 ;;
        .env|*/.env) return 0 ;;
    esac
    return 1
}
protected_re='(^|[^[:alnum:]_.-])mates(/|[^[:alnum:]_.-]|$)|cycls/[^[:space:]/]+/template(/|[^[:alnum:]_.-]|$)|(^|[^[:alnum:]_.-])\.env([^[:alnum:]_.-]|$)'
line_names=0
[[ "${cmd}" =~ ${protected_re} ]] && line_names=1
body_names=0
[[ -n "${bodies}" && "${bodies}" =~ ${protected_re} ]] && body_names=1

# A path git tracks, read from the directory the command runs in. A glob is
# read as git's pathspec, which errs toward "tracked".
tracked() { # $1 = path
    [[ -n "$1" ]] || return 1
    local p="$1" dir="${base}"
    if [[ -z "${dir}" ]]; then
        # A `cd` this gate could not follow: a relative path may be tracked.
        [[ "${p}" == /* ]] || return 0
        dir="${root}"
    fi
    [[ "${p}" == /* ]] || p="${dir}/${p}"
    git -C "${dir}" ls-files --error-unmatch -- "${p}" >/dev/null 2>&1
}

# A tracked file, not a directory: what a `>` or a tee would overwrite.
tracked_file() { # $1 = path
    local p="$1"
    [[ "${p}" == /* || -z "${base}" ]] || p="${base}/${p}"
    [[ -d "${p}" ]] && return 1
    tracked "$1"
}

# Where a download lands: stdout (-), or a path it overwrites or writes into.
writes_over() { # $1 = curl's -o or wget's -O path
    [[ -n "$1" && "$1" != - ]] || return 1
    protected "$1" || tracked_file "$1"
}

# Where a mv, cp, ln, install, or rsync lands, one path per line: the last
# operand, or -t's directory, and inside a directory each source under its own
# name. A copy's source ending in `/` (or naming `.`) pours its contents into
# the directory — rsync's rule, and BSD cp -R's — so the directory itself is
# where it lands, and any tracked file in it may be overwritten.
landing() { # $1 = entry | contents | install, then the command's words after its name
    local mode="$1" a dest="" want_t=0 want_v=0 opts=1 d n last
    local -a ops=()
    shift
    for a in "$@"; do
        if (( want_t )); then dest="${a}"; want_t=0; continue; fi
        if (( want_v )); then want_v=0; continue; fi
        if (( opts )); then
            case "${a}" in
                --) opts=0; continue ;;
                -t|--target-directory) want_t=1; continue ;;
                --target-directory=*) dest="${a#*=}"; continue ;;
                -m|-o|-g) [[ "${mode}" == install ]] && want_v=1; continue ;;
                -*) continue ;;
            esac
        fi
        ops+=("${a}")
    done
    n=${#ops[@]}
    if [[ -z "${dest}" ]]; then
        (( n >= 2 )) || return 0
        last=$((n - 1))
        dest="${ops[last]}"
        unset "ops[last]"
    fi
    d="${dest}"
    [[ "${d}" == /* || -z "${base}" ]] || d="${base}/${d}"
    if [[ -d "${d}" ]]; then
        for a in ${ops[@]+"${ops[@]}"}; do
            if [[ "${mode}" == contents ]]; then
                case "${a}" in */|.|..|*/.|*/..) printf '%s\n' "${dest}"; continue ;; esac
            fi
            a="${a%/}"
            printf '%s\n' "${dest%/}/${a##*/}"
        done
    else
        printf '%s\n' "${dest}"
    fi
}

# Commands that only read the paths they name. A protected path passes through
# these; any other command naming one keeps its prompt.
reads_only() { # $1 = command name, then its words
    local name="$1" a
    shift
    case "${name}" in
        cat|head|tail|less|more|grep|egrep|fgrep|rg|diff|cmp|comm|ls|tree|du|wc|file|stat|jq|cut|column|nl|od|xxd|hexdump|strings|shasum|sha1sum|sha256sum|sha512sum|md5|md5sum|cksum|b2sum|pdfinfo|pdffonts|texcount|test|'['|realpath|readlink|basename|dirname|cd|pushd|popd|echo|printf|true|false|:|source|.)
            return 0 ;;
        sed)
            for a in "$@"; do case "${a}" in --in-place*) return 1 ;; --*) ;; -i*|-[!-]*i*) return 1 ;; esac; done
            return 0 ;;
        awk|gawk)
            for a in "$@"; do case "${a}" in -i*|--include*) return 1 ;; esac; done
            return 0 ;;
        sort)
            for a in "$@"; do case "${a}" in -o*|--output*) return 1 ;; esac; done
            return 0 ;;
        find)
            for a in "$@"; do case "${a}" in -fprint*|-fls) return 1 ;; esac; done
            return 0 ;;
    esac
    return 1
}

# A directory inside a protected path, read against the project root — the
# logical path first, then the physical one, since the payload's cwd and
# $CLAUDE_PROJECT_DIR need not spell the root alike.
root_p="$(cd "${root}" 2>/dev/null && pwd -P)" || root_p="${root}"
dir_protected() { # $1 = a directory a command runs in
    local d="$1"
    [[ -n "${d}" ]] || return 1
    case "${d}" in
        "${root}"/*) protected "${d#"${root}"/}" && return 0 ;;
    esac
    d="$(cd "${d}" 2>/dev/null && pwd -P)" || return 1
    case "${d}" in
        "${root_p}"/*) protected "${d#"${root_p}"/}" ;;
        *) return 1 ;;
    esac
}

# The command runs inside a protected directory: the session's cwd is one (a
# Claude shell keeps the directory an earlier call moved it to), or a `cd`
# earlier on the line entered one. Every relative path then lands there.
in_protected=0
dir_protected "${base}" && in_protected=1

# One shell line can carry several commands, so each is read on its own:
# `cd x && sudo make install` is the sudo it looks like, and a `$(…)` or
# backtick substitution is a command of its own.
while IFS= read -r segment; do
    read -ra tok <<< "${segment}"
    [[ ${#tok[@]} -gt 0 ]] || continue
    # Quotes cling to the words they open and close (`bash -c "rm x"` splits as
    # `"rm x"`), and the shell drops every quote and backslash before it runs a
    # word: `\rm` (the usual way past an alias), `r''m`, and `"r"m` are all rm.
    # So each word read below sheds them all, and the `$` of a `$'…'` with them.
    word=()
    for w in "${tok[@]}"; do
        w="${w//\$\'/\'}"; w="${w//\$\"/\"}"
        w="${w//[\'\"\\]/}"
        word+=("${w}")
    done

    # A redirection's target: `> f`, `>f`, `2>f`, `>>f`. Into a protected path
    # it is a write there; `>` onto a tracked file overwrites it, while `>>` only
    # appends.
    for ((k = 0; k < ${#word[@]}; k++)); do
        w="${word[k]}"
        [[ "${w}" == *'>'* ]] || continue
        rest="${w#*>}"
        append=0
        [[ "${rest}" == '>'* ]] && { append=1; rest="${rest#>}"; }
        to_fd=0
        [[ "${rest}" == "${dup}"* ]] && { to_fd=1; rest="${rest#"${dup}"}"; }
        if [[ -z "${rest}" ]]; then
            rest="${word[k + 1]:-}"
            k=$((k + 1))
        fi
        [[ -n "${rest}" ]] || continue
        # `>&2`, `>&-`, `>&3-` duplicate or close a descriptor; any other word
        # after `>&` is a file.
        (( to_fd )) && [[ "${rest}" =~ ^[0-9]*-?$ ]] && continue
        protected "${rest}" && exit 0
        (( in_protected )) && [[ "${rest}" != /* ]] && exit 0
        (( append )) || ! tracked_file "${rest}" || exit 0
    done

    # Walk past wrappers, shell keywords, assignments, flags and the values they
    # take, redirections, and a timeout's duration to the command itself, so
    # `env rm`, `timeout -s KILL 30 rm`, `if rm`, and `xargs -I {} rm` are the
    # rm they carry.
    i=0
    via_shell=0
    via_xargs=0
    prev=""
    while [[ ${i} -lt ${#word[@]} ]]; do
        t="${word[i]}"
        case "${t}" in
            '<'|'>'|'>>'|'<<<'|[0-9]'>'|[0-9]'>>'|[0-9]'<'|">${dup}"|[0-9]">${dup}")
                i=$((i + 2)); continue ;;
            '<'*|'>'*|'')
                # An empty word — the `)"` closing a substitution, once its
                # quote is shed — names no command.
                i=$((i + 1)); continue ;;
        esac
        # A wrapper's option that takes a value: the value is not the command.
        # env -S is not among them: its value is the command line it runs.
        case "${prev}:${t}" in
            xargs:-I|xargs:-a|xargs:-d|xargs:-E|xargs:-L|xargs:-n|xargs:-P|xargs:-s|timeout:-s|timeout:-k|env:-u|env:-C|nice:-n|exec:-a|stdbuf:-i|stdbuf:-o|stdbuf:-e|time:-f|time:-o)
                i=$((i + 2)); continue ;;
        esac
        case "${t##*/}" in
            sh|bash|zsh)
                via_shell=1; i=$((i + 1)) ;;
            xargs)
                via_xargs=1; prev=xargs; i=$((i + 1)) ;;
            env|command|exec|eval|nohup|time|nice|caffeinate|stdbuf|timeout|if|then|else|elif|do|while|until|'!'|'{')
                prev="${t##*/}"; i=$((i + 1)) ;;
            coproc)
                # `coproc NAME { …; }` names the coprocess before its command.
                prev=coproc; i=$((i + 1))
                [[ "${word[i + 1]:-}" == '{' ]] && i=$((i + 1)) ;;
            *=*|-*|[0-9]*)
                i=$((i + 1)) ;;
            *)
                break ;;
        esac
    done
    if [[ ${i} -ge ${#word[@]} ]]; then
        # A shell with no script to run reads its commands from a pipe —
        # `curl … | bash` — and runs text this gate never sees.
        (( via_shell )) && exit 0
        continue
    fi
    # The walk left this word in t.
    name="${t##*/}"
    args=("${word[@]:i+1}")

    # Every word counts, the command's own included: interpreter code split at
    # its parentheses leaves `'mates/x','w'` as the first word of a segment.
    touches=$(( in_protected || body_names || (via_xargs && line_names) ))
    for a in "${word[@]}"; do
        [[ "${a}" =~ ${protected_re} ]] && { touches=1; break; }
    done

    case "${name}" in
        rm|rmdir|unlink|shred|srm|trash)
            exit 0 ;;
        sudo|su|doas)
            exit 0 ;;
        dd|mkfs*|fdisk|parted|diskutil|truncate)
            exit 0 ;;
        shutdown|reboot|halt|poweroff|launchctl|systemctl|service)
            exit 0 ;;
        kill|pkill|killall)
            exit 0 ;;
        modprobe|insmod|kextload|kextunload)
            exit 0 ;;
        apt|apt-get|aptitude|yum|dnf|pacman|zypper|brew|port|softwareupdate|installer|tlmgr)
            exit 0 ;;
        crontab)
            exit 0 ;;
        source|.)
            # `source <(curl …)` is `curl … | bash` by another spelling.
            [[ "${args[0]:-}" == '<'* ]] && exit 0 ;;
        pip|pip3|pipx|uv|conda|mamba|micromamba|npm|pnpm|yarn|gem|cargo|go|poetry|bundle)
            for a in ${args[@]+"${args[@]}"}; do
                case "${a}" in install|i|add|ci|sync|uninstall|remove|update|upgrade|create|get) exit 0 ;; esac
            done
            ;;
        python|python3|python3.*)
            # `python3 -m pip install` is the pip it runs.
            for ((j = 0; j + 1 < ${#args[@]}; j++)); do
                if [[ "${args[j]}" == -m ]]; then
                    case "${args[j + 1]}" in
                        pip|pip3|ensurepip|conda)
                            for a in "${args[@]}"; do [[ "${a}" == install || "${a}" == uninstall ]] && exit 0; done ;;
                    esac
                fi
            done
            ;;
        scp|sftp|ftp|ssh|mosh|mail|mailx|sendmail|mutt)
            exit 0 ;;
        sbatch|srun|salloc|qsub|bsub)
            exit 0 ;;
        rsync)
            for a in ${args[@]+"${args[@]}"}; do
                case "${a}" in --del|--delete*|--remove-source-files) exit 0 ;; -*) ;; *:*) exit 0 ;; esac
            done
            # A local copy lands like cp's.
            while IFS= read -r a; do
                [[ -n "${a}" ]] || continue
                protected "${a}" && exit 0
                tracked "${a}" && exit 0
            done < <(landing contents ${args[@]+"${args[@]}"})
            ;;
        curl)
            # A GET — stage-refs-curator's DOI content negotiation — only reads,
            # unless its -o lands on a tracked file.
            for ((j = 0; j < ${#args[@]}; j++)); do
                case "${args[j]}" in
                    -o|--output)
                        writes_over "${args[j + 1]:-}" && exit 0 ;;
                    --output=*)
                        writes_over "${args[j]#*=}" && exit 0 ;;
                    -o?*)
                        writes_over "${args[j]#-o}" && exit 0 ;;
                    -T*|--upload-file*|-F*|--form*|-d*|--data*|--json*|-XPOST|-XPUT|-XPATCH|-XDELETE|--request=POST|--request=PUT|--request=PATCH|--request=DELETE)
                        exit 0 ;;
                    -X|--request)
                        case "${args[j + 1]:-}" in POST|PUT|PATCH|DELETE) exit 0 ;; esac ;;
                    -[!-]*[dFT])
                        # `-sLd body`: an upload flag closing a group of short ones.
                        exit 0 ;;
                    -[!-]*o)
                        # `-sSLo file`, likewise; read after the upload arm, which
                        # -dfoo would match too.
                        writes_over "${args[j + 1]:-}" && exit 0 ;;
                esac
            done
            ;;
        wget)
            for ((j = 0; j < ${#args[@]}; j++)); do
                case "${args[j]}" in
                    --post-data*|--post-file*|--method*|--body-data*|--body-file*) exit 0 ;;
                    -O|--output-document|-[!-]*O) writes_over "${args[j + 1]:-}" && exit 0 ;;
                    --output-document=*) writes_over "${args[j]#*=}" && exit 0 ;;
                    -O?*|-[!-]*O?*) writes_over "${args[j]#*O}" && exit 0 ;;
                esac
            done
            ;;
        gh)
            # No skill drives gh; reading a PR, an issue, or a run is harmless,
            # and anything else acts on the remote.
            case "${args[1]:-}" in view|list|status|diff|checks) ;; *) exit 0 ;; esac
            ;;
        update.sh|stage-update.sh)
            # Rewrites the managed docs, skill trees, and hooks in place;
            # --diff and --help only read.
            preview=0
            for a in ${args[@]+"${args[@]}"}; do
                case "${a}" in --diff|-h|--help) preview=1 ;; esac
            done
            (( preview )) || exit 0
            ;;
        import.sh)
            # The evidence's sanctioned writer (§10.1), which asks its own
            # questions: it passes with the mates/ path it names.
            [[ "${t}" == execs/scpts/import.sh || "${t}" == */execs/scpts/import.sh ]] && continue
            ;;
        cd|pushd)
            dir=""
            for a in ${args[@]+"${args[@]}"}; do
                case "${a}" in -) dir="-"; break ;; -*) ;; *) dir="${a}"; break ;; esac
            done
            [[ -n "${dir}" ]] || dir="${HOME:-}"
            protected "${dir}" && in_protected=1
            dir="${dir/\$\{CLAUDE_PROJECT_DIR\}/${root}}"
            dir="${dir/\$CLAUDE_PROJECT_DIR/${root}}"
            case "${dir}" in
                *'$'*|*'`'*|-) base="" ;;
                '~'*) base="${HOME:-}${dir#\~}" ;;
                /*) base="${dir}" ;;
                *) [[ -n "${base}" ]] && base="${base}/${dir}" ;;
            esac
            dir_protected "${base}" && in_protected=1
            continue
            ;;
        find)
            # A find that deletes or executes is whatever it carries.
            for a in ${args[@]+"${args[@]}"}; do
                case "${a}" in
                    -delete|-exec|-execdir|-ok|-okdir) exit 0 ;;
                esac
            done
            ;;
        tee)
            append=0
            for a in ${args[@]+"${args[@]}"}; do
                case "${a}" in -a|--append) append=1 ;; esac
            done
            for a in ${args[@]+"${args[@]}"}; do
                case "${a}" in -*) ;; *) (( append )) || ! tracked_file "${a}" || exit 0 ;; esac
            done
            ;;
        mv|cp|ln|install)
            # The forced form, and one landing on a tracked file, overwrite it.
            # A plain move or copy stays open: stage-proj-adopt's confirmed moves
            # and stage-subm-packer's copies into its generated tree run as them.
            # install copies as cp -f does.
            for a in ${args[@]+"${args[@]}"}; do
                case "${a}" in
                    --) break ;;
                    -f|--force) exit 0 ;;
                    --*) ;;
                    -*f*) exit 0 ;;
                esac
            done
            case "${name}" in cp) lmode=contents ;; install) lmode=install ;; *) lmode=entry ;; esac
            while IFS= read -r a; do
                [[ -n "${a}" ]] || continue
                protected "${a}" && exit 0
                tracked "${a}" && exit 0
            done < <(landing "${lmode}" ${args[@]+"${args[@]}"})
            # A copy reads its sources: out of mates/ or a kit is not a write there.
            # install -d copies nothing: it creates every operand as a directory,
            # so it goes on to the rule for any command naming a protected path,
            # as mkdir does.
            if [[ "${name}" == cp || "${name}" == install ]]; then
                (( in_protected || (via_xargs && line_names) )) && exit 0
                makes_dirs=0
                if [[ "${name}" == install ]]; then
                    for a in ${args[@]+"${args[@]}"}; do
                        case "${a}" in --) break ;; --directory) makes_dirs=1 ;; --*) ;; -*d*) makes_dirs=1 ;; esac
                    done
                fi
                (( makes_dirs )) || continue
            fi
            ;;
        git)
            # Walk past git's own options — `git -C dir push` names its
            # subcommand third.
            j=0
            while [[ ${j} -lt ${#args[@]} ]]; do
                case "${args[j]}" in
                    -C|-c|--git-dir|--work-tree|--namespace|--exec-path) j=$((j + 2)) ;;
                    -*) j=$((j + 1)) ;;
                    *) break ;;
                esac
            done
            [[ ${j} -lt ${#args[@]} ]] || continue
            sub="${args[j]}"
            sargs=("${args[@]:j+1}")
            case "${sub}" in
                push)
                    # Goes outward and is hard to retract (§1.3).
                    exit 0 ;;
                clean)
                    # Removes untracked files — mates/ imports left in `git
                    # status` for the user to commit among them — and, with -x,
                    # git-ignored ones: .env, wkdrs/, .stage/memory/local/.
                    exit 0 ;;
                rm|rebase|filter-branch|filter-repo|update-ref|replace|pull|prune)
                    # pull moves the user's branch from the remote (§1.3), and
                    # --rebase rewrites it; prune drops unreachable history.
                    exit 0 ;;
                worktree)
                    case "${sargs[0]:-}" in remove|prune) exit 0 ;; esac ;;
                reflog)
                    # Expired or deleted entries are how a rewrite is undone.
                    case "${sargs[0]:-}" in expire|delete) exit 0 ;; esac ;;
                gc)
                    for a in ${sargs[@]+"${sargs[@]}"}; do
                        case "${a}" in --prune*) exit 0 ;; esac
                    done ;;
                switch|checkout)
                    # A branch switch (§1.3), or a checkout of paths that
                    # overwrites their uncommitted content; no skill runs either.
                    exit 0 ;;
                restore)
                    # Only unstaging (--staged without --worktree) leaves the
                    # working tree alone.
                    staged=0; worktree=0
                    for a in ${sargs[@]+"${sargs[@]}"}; do
                        case "${a}" in
                            --) break ;;
                            -S|--staged) staged=1 ;;
                            -W|--worktree) worktree=1 ;;
                            --*) ;;
                            -*)
                                [[ "${a}" == *S* ]] && staged=1
                                [[ "${a}" == *W* ]] && worktree=1 ;;
                        esac
                    done
                    (( staged && !worktree )) || exit 0
                    ;;
                stash)
                    # drop and clear throw stashed work away for good.
                    case "${sargs[0]:-}" in drop|clear) exit 0 ;; esac
                    ;;
                reset)
                    # `git reset [HEAD] [-- paths]` only unstages; a mode flag or
                    # any other commit moves the branch or discards work.
                    for a in ${sargs[@]+"${sargs[@]}"}; do
                        case "${a}" in
                            --) break ;;
                            --hard|--soft|--merge|--keep) exit 0 ;;
                            -*|HEAD) ;;
                            *) exit 0 ;;
                        esac
                    done
                    ;;
                tag)
                    # Listing reads; every other form creates, moves, or deletes
                    # a tag, and exactly one skill creates a freeze tag (§1.4).
                    case "${sargs[0]:-}" in
                        ''|-l|--list|-l*|-n*|--contains*|--no-contains*|--points-at*|--merged*|--no-merged*|--sort=*|--column*) ;;
                        *) exit 0 ;;
                    esac
                    ;;
                branch)
                    for a in ${sargs[@]+"${sargs[@]}"}; do
                        case "${a}" in
                            --) break ;;
                            -d|-D|--delete|-f|--force|-m|-M|--move|-c|-C|--copy) exit 0 ;;
                            --*) ;;
                            -*[dDfmMcC]*) exit 0 ;;
                        esac
                    done
                    ;;
                add)
                    for a in ${sargs[@]+"${sargs[@]}"}; do
                        case "${a}" in
                            -A|--all|-u|--update|--no-ignore-removal|.|./|:/|:/*|'*'|-f|--force) exit 0 ;;
                            --*) ;;
                            -*[Auf]*) exit 0 ;;
                        esac
                    done
                    ;;
                commit)
                    # Every word is read, the message's included: the guard stops
                    # at -m, and `commit -m x --amend` is still an amend.
                    for a in ${sargs[@]+"${sargs[@]}"}; do
                        case "${a}" in
                            --amend|--all) exit 0 ;;
                            --*) ;;
                            -*a*) exit 0 ;;
                        esac
                    done
                    ;;
                mv)
                    for a in ${sargs[@]+"${sargs[@]}"}; do
                        case "${a}" in
                            --) break ;;
                            -f|--force) exit 0 ;;
                            --*) ;;
                            -*f*) exit 0 ;;
                        esac
                    done
                    ;;
            esac
            # A protected path reaches git only through the subcommands that read
            # or stage; committing evidence stays the user's review (§1).
            case "${sub}" in
                status|diff|log|show|blame|annotate|ls-files|ls-tree|grep|cat-file|rev-parse|shortlog|describe|whatchanged|diff-tree|diff-index|diff-files|check-ignore|check-attr|add|commit) ;;
                *) (( touches )) && exit 0 ;;
            esac
            continue
            ;;
    esac

    # Any other command naming a protected path keeps its prompt unless it
    # only reads.
    (( touches )) && ! reads_only "${name}" ${args[@]+"${args[@]}"} && exit 0
done < <(printf '%s\n' "${cmd}" | tr ';&|()`' '\n\n\n\n\n\n')

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"involve=low (stage_bash_gate.sh)"}}\n'
