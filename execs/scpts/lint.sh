#!/usr/bin/env bash
set -euo pipefail

# execs/scpts/lint.sh — deterministic manuscript checks (conventions §3, §9).
# Judgment lives in skills; this script only reports what a grep can prove.
# Hard failures (exit 1): undefined citations/references, todo markers,
# page count over the venue limit, identity leaks while ANON=true, and an ANON
# that is neither true nor false.
# Prose-pattern findings are advisory prompts for human review, never authorship
# classification and never a submission gate. File names off conventions §10.6
# are warnings too: a name cannot break the build, only the order a directory
# lists in and the tie between an asset and the file that includes it.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
ENV_FILE="${ROOT_DIR}/.env"
MANU_DIR="${ROOT_DIR}/manus"
BUILD_DIR="${ROOT_DIR}/wkdrs/builds"
LOG_FILE="${BUILD_DIR}/main.log"
PDF_FILE="${BUILD_DIR}/main.pdf"

NO_BUILD=false
HARD=0
WARNS=0

log() {
    printf '[STAGE lint] %s\n' "$*"
}

warn() {
    log "warn: $*"
    WARNS=$(( WARNS + 1 ))
}

fail() {
    printf '[STAGE lint] ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: bash execs/scpts/lint.sh [--no-build]

Build the manuscript (execs/run.sh), then run the deterministic checks:

  hard failures (exit 1):
    - undefined citations or references in the latexmk log
    - todo markers anywhere under manus/ (§9a: an unsourced number stays a
      visible todo — lint fails until evidence lands)
    - page count over page_limit_main in the active cycle's venue.yml: pages
      through the one the references start on, or every page when its
      references_in_limit is true or the build has no reference list
    - identity leaks while ANON=true in .env
    - an ANON value other than true or false (an inline comment after it is
      part of the value), which runs no identity scan at all

  warnings and notes (reported, exit 0):
    - a *.tex or *.sty file under manus/ that cannot be read, which no check
      sees into
    - overfull hboxes
    - sources newer than a reused build (--no-build only)
    - manuscript sources that no longer read one sentence per line
      (execs/scpts/fmt.sh --check; where a line breaks cannot move a page)
    - file names in manus/secs, figs, figs/srcs, and tabs off conventions
      §10.6: a name off <nn>_<slug>, a directory that lists in a different
      order in git and ls than in VS Code, Overleaf, and Finder, a figure or
      table key no section carries, or an include whose key is not its
      includer's (00 for main.tex); stage-outl-planner renames
    - high-confidence chatbot residue or paragraphs containing multiple
      formulaic-prose patterns (advisory; not proof of AI authorship); a
      section or table file that is not valid UTF-8 is left out of this scan
      with a warning naming it, while every other check still reads it
    - per-file word counts (when texcount is installed)

A todo marker inside a LaTeX comment is not a failure: each file is read the
way TeX reads it, comments cut, so only markers that would reach the PDF count
— \todo{x}, \todo {x}, and a \todo whose brace opens the next line all do. A
comment opens at a % that an even run of backslashes precedes: \% is a percent
sign, and \\% is a line break followed by a comment.

Options:
  --no-build    Reuse the latest wkdrs/builds/ output instead of rebuilding;
                a last build that failed is a hard error.
  -h, --help    Show this help message.

The active cycle is `cycle:` in notes/story.md frontmatter; when it, its
venue.yml, or page_limit_main cannot be resolved, the page-limit check is
skipped with a note.
EOF
}

while (( $# > 0 )); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --no-build)
            NO_BUILD=true
            ;;
        *)
            fail "Unknown argument: $1. Run 'bash execs/scpts/lint.sh --help' for usage."
            ;;
    esac
    shift
done

# One value out of .env, without sourcing the file: sourcing would overwrite a
# variable the caller set on the command line, and the precedence every STAGE
# entrypoint follows is environment, then .env, then the default (conventions
# §3.1) — the same order execs/update.sh uses for STAGE_REPOSITORY.
env_value() {
    local key="$1" val
    [[ -f "${ENV_FILE}" ]] || return 0
    val="$(LC_ALL=C sed -n "s/^[[:space:]]*${key}=//p" "${ENV_FILE}" | tail -1)"
    val="${val%$'\r'}"                   # tolerate a CRLF .env
    val="${val%\"}"; val="${val#\"}"     # and a quoted value
    val="${val%\'}"; val="${val#\'}"
    printf '%s' "${val}"
}

# Byte-wise: a .env line saved in Latin-1 would stop tr under a UTF-8 locale.
# A value other than true or false is step 5's hard failure.
ANON="${ANON:-$(env_value ANON)}"
ANON="$(printf '%s' "${ANON:-false}" | LC_ALL=C tr '[:upper:]' '[:lower:]')"

count_lines() {
    if [[ -n "$1" ]]; then
        printf '%s\n' "$1" | wc -l | tr -d '[:space:]'
    else
        printf '0'
    fi
}

show_hits() {
    printf '%s\n' "$1" | LC_ALL=C sed -e "s|${ROOT_DIR}/||" -e 's/^/      /'
}

append_lines() {
    # append_lines VAR "new lines" — grows a newline-separated list variable.
    local var="$1"
    local add="$2"
    local cur
    [[ -n "${add}" ]] || return 0
    eval "cur=\"\${${var}}\""
    if [[ -n "${cur}" ]]; then
        eval "${var}=\"\${cur}
\${add}\""
    else
        eval "${var}=\"\${add}\""
    fi
}

# How TeX reads a source line, shared by every awk program below that reads
# manuscript source (prepended to its program text):
#   tex_code(s)  s up to its comment, which opens at the first % that an even
#                run of backslashes precedes: \% prints a percent sign, while
#                \\% breaks the line and then opens a comment. tex_comment is 1
#                when a comment was cut.
#   tex_line(s)  what one input line adds to the text TeX reads: trailing
#                spaces dropped, leading spaces and tabs skipped, the comment
#                cut, then nothing when a comment was cut (the % takes the end
#                of line with it) and one space when none was (the end of line
#                reads as a space). Lines joined with it read
#                '\includegraphics{figs/%' and '  01_x}' as figs/01_x.
TEX_AWK='
function tex_code(s) {
    tex_comment = 0
    if (match(s, /^([^\\%]|\\.)*%/)) {
        tex_comment = 1
        return substr(s, 1, RLENGTH - 1)
    }
    return s
}
function tex_line(s) {
    sub(/[ \r]+$/, "", s)
    sub(/^[ \t]+/, "", s)
    s = tex_code(s)
    return tex_comment ? s : s " "
}
'

# is_utf8 FILE — whether FILE's bytes are well-formed UTF-8 (RFC 3629; plain
# ASCII is): Perl, which latexmk needs, strips every well-formed sequence and
# the file passes when no byte is left, so an overlong form, a surrogate, and a
# code point past U+10FFFF all fail it, on every platform alike. iconv decides
# only where Perl is absent, and with neither the answer is yes: the prose
# review reads each file on its own (check_prose_patterns), so a file this lets
# through that awk cannot decode still stops only its own scan.
is_utf8() {
    if command -v perl >/dev/null 2>&1; then
        perl -C0 -0777 -ne '
            s/(?:[\x00-\x7F]|[\xC2-\xDF][\x80-\xBF]|\xE0[\xA0-\xBF][\x80-\xBF]|[\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}|\xED[\x80-\x9F][\x80-\xBF]|\xF0[\x90-\xBF][\x80-\xBF]{2}|[\xF1-\xF3][\x80-\xBF]{3}|\xF4[\x80-\x8F][\x80-\xBF]{2})+//g;
            exit(length($_) ? 1 : 0)' < "$1" 2>/dev/null
    elif command -v iconv >/dev/null 2>&1; then
        iconv -f UTF-8 -t UTF-8 < "$1" >/dev/null 2>&1
    fi
}

# The prose review's awk program: one paragraph at a time, flagged when it
# holds chatbot residue or two or more formulaic patterns. table_file (-v) is
# 1 for a file under manus/tabs/, where only captions are prose.
PROSE_AWK='
    function add_pattern(name) {
        if (patterns != "") patterns = patterns ","
        patterns = patterns name
        pattern_count++
    }
    function flush_paragraph(    lower, stock_text, stock_count, chatbot, excerpt) {
        if (paragraph == "") return

        lower = tolower(paragraph)
        patterns = ""
        pattern_count = 0
        chatbot = 0

        if (lower ~ /(i hope this helps|would you like me to|let me know if|up to my last training|let.s (dive|explore|break this down)|without further ado)/ ||
            paragraph ~ /(希望这对(您|你)有帮助|如果(您|你).*(请告诉我|告诉我)|让我们(深入探讨|来看看|分析一下)|根据我最后的训练)/) {
            add_pattern("chatbot-residue")
            chatbot = 1
        }
        if (lower ~ /(stands? as (a )?(testament|reminder)|pivotal (role|moment)|underscores? (the )?(importance|significance)|evolving landscape|lays? (a |the )?foundation|sets? the stage)/ ||
            paragraph ~ /(具有[^。；;.]*(重要|深远)[^。；;.]*意义|标志着[^。；;.]*(转折|转变|里程碑)|(彰显|凸显)[^。；;.]*(重要性|意义)|奠定[^。；;.]*基础|不断演变的[^。；;.]*格局)/) {
            add_pattern("inflated-significance")
        }
        if (lower ~ /((experts?|observers?|critics?) (argue|believe|suggest|note)|industry reports? (show|suggest|indicate)|studies have shown)/ ||
            paragraph ~ /((专家|学者|业内人士)(普遍)?(认为|指出|表示)|行业报告(显示|指出|表明)|已有研究(认为|指出|表明|显示)|一些批评者认为)/) {
            add_pattern("vague-attribution")
        }
        if (lower ~ /(not (only|merely|just)[^.;]*but( also)?|not just[^.;]*it is)/ ||
            paragraph ~ /(不仅[^。；;.]*而且|不仅[^。；;.]*还|不仅[^。；;.]*更|不只是[^。；;.]*而是|不是[^。；;.]*而是)/) {
            add_pattern("formulaic-contrast")
        }
        if (lower ~ /(it is (important|worth) to note|it should be noted|this (section|chapter) (delves into|explores|examines)|in order to|the following section)/ ||
            paragraph ~ /(值得注意的是|需要指出的是|不难发现|本(节|章|文)将(深入)?(探讨|分析|研究)|为了实现这一(目标|目的))/) {
            add_pattern("stock-signposting")
        }
        if (lower ~ /, (highlighting|underscoring|showcasing|ensuring|reflecting|demonstrating) / ||
            paragraph ~ /(从而(彰显|体现|确保|促进|说明)|进而(彰显|体现|推动|促进|说明)|这(充分)?(彰显|体现|凸显))/) {
            add_pattern("shallow-analysis")
        }
        if (lower ~ /(despite (these|the) challenges|future outlook|future looks bright|continues? to (thrive|flourish))/ ||
            paragraph ~ /(尽管[^。；;.]*(挑战|困难)|未来展望|前景(十分|非常)?(广阔|光明)|继续(蓬勃发展|迈向))/) {
            add_pattern("generic-outlook")
        }
        if (lower ~ /(at its core|what really matters|the real question is|the heart of the matter)/ ||
            paragraph ~ /(归根结底|从本质上说|真正重要的是|真正的问题是|问题的核心在于)/) {
            add_pattern("manufactured-depth")
        }

        stock_text = lower
        stock_count = gsub(/(crucial|pivotal|intricate|landscape|delve|underscore|showcase|foster|tapestry)/, "&", stock_text)
        stock_text = paragraph
        stock_count += gsub(/(至关重要|深入探讨|不断演变|格局|彰显|赋能|协同|多维度)/, "&", stock_text)
        if (stock_count >= 3) add_pattern("stock-diction")

        if (chatbot || pattern_count >= 2) {
            excerpt = paragraph
            gsub(/[[:space:]]+/, " ", excerpt)
            sub(/^[[:space:]]+/, "", excerpt)
            sub(/[[:space:]]+$/, "", excerpt)
            printf "%s:%d\t%s\t%s\n", current_file, paragraph_start, patterns, excerpt
        }
        paragraph = ""
    }
    FNR == 1 {
        if (NR > 1) flush_paragraph()
        current_file = FILENAME
        paragraph = ""
        caption_active = 0
        caption_depth = 0
    }
    {
        line = tex_code($0)
        gsub(/\r/, "", line)

        caption_ends = 0
        if (table_file) {
            if (!caption_active && line !~ /\\caption(\[[^]]*\])?[[:space:]]*\{/) next
            if (!caption_active) {
                flush_paragraph()
                caption_active = 1
                caption_depth = 0
            }
            brace_text = line
            opens = gsub(/\{/, "", brace_text)
            brace_text = line
            closes = gsub(/\}/, "", brace_text)
            caption_depth += opens - closes
            if (caption_depth <= 0) {
                caption_active = 0
                caption_ends = 1
            }
        }

        trimmed = line
        sub(/^[[:space:]]+/, "", trimmed)
        sub(/[[:space:]]+$/, "", trimmed)

        if (trimmed == "" || trimmed ~ /^\\(begin|end|section|subsection|subsubsection|paragraph|label|input|include|bibliography|bibliographystyle)[*]?[[:space:]]*\{/) {
            flush_paragraph()
            next
        }

        clean = line
        gsub(/\\(cite|citep|citet|citeauthor|parencite|textcite|ref|eqref|autoref|label|url)(\[[^]]*\])?\{[^}]*\}/, " ", clean)
        gsub(/\$[^$]*\$/, " ", clean)
        gsub(/\\[[:alpha:]@]+[*]?/, " ", clean)
        gsub(/[{}]/, " ", clean)
        gsub(/[[:space:]]+/, " ", clean)
        sub(/^[[:space:]]+/, "", clean)
        sub(/[[:space:]]+$/, "", clean)
        if (clean == "") next

        if (paragraph == "") paragraph_start = FNR
        paragraph = paragraph " " clean
        if (caption_ends) flush_paragraph()
    }
    END { flush_paragraph() }
'

# The one check that matches non-ASCII text on purpose (the Chinese patterns),
# so it reads in the caller's locale. Under a UTF-8 locale a byte that is not
# UTF-8 stops macOS awk outright and hides the line from other tools, so a file
# holding one is left out of the scan with a warning instead. Each file is read
# by its own awk: whatever stops one — a byte sequence awk cannot decode that
# is_utf8 let through — stops only that file's scan, with a warning naming it,
# and every other file is still read. Whether a file is a table is decided
# from its place under manus/, never from a pattern over the whole path, so a
# repository that sits under a directory called tabs/ reads its sections as
# prose. An unreadable file was named once already, with the source list.
check_prose_patterns() {
    local file out rc table location patterns snippet
    local prose_output="" prose_count=0 candidates=0 scanned=0 stopped=0

    if (( ${#MANU_TEX[@]} > 0 )); then
        for file in "${MANU_TEX[@]}"; do
            case "${file}" in
                "${MANU_DIR}/secs/"*) table=0 ;;
                "${MANU_DIR}/tabs/"*) table=1 ;;
                *) continue ;;
            esac
            candidates=$(( candidates + 1 ))
            if ! is_utf8 "${file}"; then
                warn "${file#"${ROOT_DIR}"/} is not valid UTF-8, so its prose was not checked for formulaic patterns — re-save it as UTF-8."
                continue
            fi
            rc=0
            out="$(awk -v table_file="${table}" "${TEX_AWK}${PROSE_AWK}" "${file}" 2>/dev/null)" || rc=$?
            scanned=$(( scanned + 1 ))
            if (( rc != 0 )); then
                warn "the prose review stopped in ${file#"${ROOT_DIR}"/} (awk exited ${rc}), so the rest of that file was not checked for formulaic patterns."
                stopped=1
            fi
            append_lines prose_output "${out}"
        done
    fi

    if (( candidates == 0 )); then
        log "note: prose review skipped — no readable section or table TeX files found."
        return
    fi
    (( scanned > 0 )) || return 0

    if [[ -z "${prose_output}" ]]; then
        if (( stopped == 0 )); then
            log "ok: prose review found no high-confidence chatbot residue or clustered formulaic prose."
        fi
        return
    fi

    while IFS=$'\t' read -r location patterns snippet; do
        [[ -n "${location}" ]] || continue
        location="${location#"${ROOT_DIR}"/}"
        if (( ${#snippet} > 140 )); then
            snippet="${snippet:0:137}..."
        fi
        warn "${location}: prose review (${patterns}); ${snippet}"
        prose_count=$(( prose_count + 1 ))
    done <<< "${prose_output}"
    log "prose review: ${prose_count} passage(s) need human review; findings are advisory, not proof of AI authorship."
}

# Names on stdin, one per line, in the numeric (natural) order VS Code, Overleaf,
# and Finder show: every digit run is zero-padded to 20 places before a byte
# sort. A directory lists identically there and in git and ls (byte order) iff
# LC_ALL=C sort equals this over its names, provided the names follow the
# §10.6 grammar and no two differ only in a number's leading zeros. The grammar
# check catches an underscore inside a slug, the one grammar case the model
# misses; natural_key_ties catches the leading zeros (seed1 beside seed01),
# which the two sorts agree on and Finder orders the other way.
natural_key_sort() {
    awk '{
        s = $0; k = ""
        while (match(s, /[0-9]+/)) {
            d = substr(s, RSTART, RLENGTH)
            while (length(d) < 20) d = "0" d
            k = k substr(s, 1, RSTART - 1) d
            s = substr(s, RSTART + RLENGTH)
        }
        printf "%s%s\t%s\n", k, s, $0
    }' | LC_ALL=C sort -t "$(printf '\t')" -k1,1 -k2,2 | cut -f2
}

# Names on stdin, one per line; prints the first two whose natural_key_sort keys
# are equal, tab-separated — names that differ only in a number's leading zeros.
natural_key_ties() {
    awk '{
        s = $0; k = ""
        while (match(s, /[0-9]+/)) {
            d = substr(s, RSTART, RLENGTH)
            while (length(d) < 20) d = "0" d
            k = k substr(s, 1, RSTART - 1) d
            s = substr(s, RSTART + RLENGTH)
        }
        k = k s
        if (k in seen) { print seen[k] "\t" $0; exit }
        seen[k] = $0
    }'
}

# list_names DIR KIND — the entry names directly under DIR, one per line, in
# byte order; KIND f lists files, fd files and directories, a symlink counting
# as either, the way git tracks it. Hidden entries (.gitkeep, .DS_Store,
# .ipynb_checkpoints) are not the manuscript's, and neither, inside a git work
# tree, is a name git ignores (a latexindent backup, an editor's build output).
# Never fails: an unreadable directory lists as empty.
list_names() {
    local names ignored
    [[ -d "$1" ]] || return 0
    names="$(if [[ "$2" == fd ]]; then
            find "$1" -mindepth 1 -maxdepth 1 \( -type f -o -type d -o -type l \) ! -name '.*' -print
        else
            find "$1" -mindepth 1 -maxdepth 1 \( -type f -o -type l \) ! -name '.*' -print
        fi 2>/dev/null | LC_ALL=C sed 's|.*/||' | LC_ALL=C sort || true)"
    [[ -n "${names}" ]] || return 0
    if [[ "${IN_WORK_TREE}" == true ]]; then
        # NUL-separated both ways: without -z, git quotes a non-ASCII name on
        # output and rejects a name that opens with a double quote on input.
        ignored="$(printf '%s\n' "${names}" | tr '\n' '\0' |
            git -C "$1" check-ignore -z --stdin 2>/dev/null | tr '\0' '\n' || true)"
        if [[ -n "${ignored}" ]]; then
            names="$(LC_ALL=C awk 'NR == FNR { skip[$0] = 1; next } !($0 in skip)' \
                <(printf '%s\n' "${ignored}") - <<< "${names}")"
        fi
    fi
    [[ -z "${names}" ]] || printf '%s\n' "${names}"
}

# Conventions §10.6 over manus/secs, figs, figs/srcs, and tabs, in four passes:
# the <nn>_<slug> grammar, byte order against natural order, an owner for every
# asset key, and an includer key for every keyed include. Warnings only; reads
# the file tree and the includes, never the build, so it runs before it.
check_file_names() {
    local slug='[a-z][a-z0-9]*(-[a-z0-9]+)*'
    local spec rel kind pattern names bad name byte nat pair key keys asset
    local includer ikey hits target tkey graphicspath=0 unread=0
    local seen candidate found matches
    local -a preamble_files=()
    local secs_pattern="^[0-9]{2}_${slug}\\.tex\$"
    local before="${WARNS}"
    local -a specs=(
        "secs|f|${secs_pattern}"
        "figs|f|^[0-9]{2}_${slug}(\\.[a-z0-9]+)+\$"
        "figs/srcs|fd|^[0-9]{2}_${slug}(\\.[a-z0-9]+)*\$"
        "tabs|f|^[0-9]{2}_${slug}\\.tex\$"
    )

    # 1-2. grammar, then byte order against natural order, per directory.
    for spec in "${specs[@]}"; do
        rel="${spec%%|*}"
        kind="${spec#*|}"; kind="${kind%%|*}"
        pattern="${spec##*|}"
        if [[ -d "${MANU_DIR}/${rel}" && ! ( -r "${MANU_DIR}/${rel}" && -x "${MANU_DIR}/${rel}" ) ]]; then
            warn "manus/${rel} cannot be read, so its file names went unchecked (conventions §10.6)."
            continue
        fi
        names="$(list_names "${MANU_DIR}/${rel}" "${kind}")"
        [[ -n "${names}" ]] || continue
        bad="$(printf '%s\n' "${names}" | LC_ALL=C grep -Ev -- "${pattern}" || true)"
        while IFS= read -r name; do
            [[ -n "${name}" ]] || continue
            warn "manus/${rel}/${name} is off the <nn>_<slug> grammar — a two-digit key, one '_', a lowercase kebab-case slug, lowercase extensions (conventions §10.6)."
        done <<< "${bad}"
        byte="$(printf '%s\n' "${names}" | LC_ALL=C sort)"
        nat="$(printf '%s\n' "${names}" | LC_ALL=C natural_key_sort)"
        if [[ "${byte}" != "${nat}" ]]; then
            pair="$(paste -d '\t' <(printf '%s\n' "${byte}") <(printf '%s\n' "${nat}") |
                LC_ALL=C awk -F '\t' '$1 != $2 { print $1 "\t" $2; exit }')"
            warn "manus/${rel} lists in a different order in git and ls than in VS Code, Overleaf, and Finder: ${pair%%$'\t'*} comes before ${pair#*$'\t'} in byte order but after it in natural order — use one key width and pad digit runs inside slugs (conventions §10.6)."
        else
            pair="$(printf '%s\n' "${byte}" | LC_ALL=C natural_key_ties)"
            if [[ -n "${pair}" ]]; then
                warn "manus/${rel} lists in a different order in git and ls than in Finder: ${pair%%$'\t'*} and ${pair#*$'\t'} differ only in a number's leading zeros — pad every number inside a slug to one width across the directory (conventions §10.6)."
            fi
        fi
    done

    # 3. every asset key names an owner: a section's key, or 00 for main.tex.
    # Only a .tex file under secs/ is a section. While secs/ cannot be read,
    # the keys are unknown and no asset is called ownerless.
    keys="00"
    if [[ -d "${MANU_DIR}/secs" && ! ( -r "${MANU_DIR}/secs" && -x "${MANU_DIR}/secs" ) ]]; then
        keys=''
    fi
    while IFS= read -r name; do
        if [[ "${name}" =~ ^([0-9]+)_.*\.tex$ ]]; then
            keys="${keys} ${BASH_REMATCH[1]}"
        fi
    done <<< "$(list_names "${MANU_DIR}/secs" f)"
    for spec in "figs|f" "figs/srcs|fd" "tabs|f"; do
        [[ -n "${keys}" ]] || break
        rel="${spec%%|*}"
        while IFS= read -r name; do
            [[ "${name}" =~ ^([0-9]+)_ ]] || continue
            key="${BASH_REMATCH[1]}"
            case " ${keys} " in
                *" ${key} "*) ;;
                *) warn "manus/${rel}/${name} has key ${key}, but no manus/secs/${key}_*.tex exists and main.tex's key is 00 — an asset takes the key of the one file that includes it (conventions §10.6)." ;;
            esac
        done <<< "$(list_names "${MANU_DIR}/${rel}" "${spec#*|}")"
    done

    # 4. every keyed include under figs/ or tabs/ carries its includer's key. A
    # bare \includegraphics name is under figs/ only where \graphicspath sets it.
    # Each file is read as TeX reads it (tex_line above): its comments cut, a
    # line whose comment was cut running straight into the next, and any other
    # line ending in one space. So a \graphicspath whose path list, or an
    # include whose options or target, continue on the next line is still read,
    # and '\includegraphics{figs/%' then '  01_x}' names figs/01_x. \\ is
    # masked after the join, so '\\input' is a line break and then text. A
    # \graphicspath counts only when {figs/} is one of its own brace groups.
    # An includer whose slug is off the grammar has had its own warning and
    # still lends its key; one whose key is not two digits lends none. A file
    # that cannot be read was named with the source list and is skipped here —
    # awk stops at a file it cannot open — and the ok line below, which it
    # would make untrue, is not printed.
    for name in "${MANU_DIR}/main.tex" "${MANU_DIR}"/stys/*.sty "${MANU_DIR}"/stys/*.cls; do
        [[ -f "${name}" ]] || continue
        if [[ -r "${name}" ]]; then
            preamble_files+=("${name}")
        else
            unread=1
        fi
    done
    if (( ${#preamble_files[@]} > 0 )); then
        graphicspath="$(LC_ALL=C awk "${TEX_AWK}"'
            FNR == 1 { text = text " " }
            { text = text tex_line($0) }
            END {
                gsub(/\\\\/, "\001", text)
                if (text ~ /\\graphicspath[[:space:]]*\{([[:space:]]*\{([^{}]|\{[^{}]*\})*\})*[[:space:]]*\{(\.\/)?figs\/?\}/) print 1
                else print 0
            }' "${preamble_files[@]}" 2>/dev/null || true)"
    fi
    [[ "${graphicspath}" == 1 ]] || graphicspath=0
    for includer in "${MANU_DIR}/main.tex" "${MANU_DIR}"/secs/*.tex; do
        [[ -f "${includer}" ]] || continue
        if [[ ! -r "${includer}" ]]; then
            unread=1
            continue
        fi
        name="${includer##*/}"
        if [[ "${includer}" == "${MANU_DIR}/main.tex" ]]; then
            ikey="00"
        elif [[ "${name}" =~ ^([0-9]{2})_ ]]; then
            ikey="${BASH_REMATCH[1]}"
        else
            continue
        fi
        hits="$(LC_ALL=C awk -v key="${ikey}" -v gp="${graphicspath}" "${TEX_AWK}"'
            { text = text tex_line($0) }
            END {
                gsub(/\\\\/, "\001", text)
                gsub(/\\%/, "\002", text)
                while (match(text, /\\(includegraphics|input)[*]?([[:space:]]*\[([^]{}]|\{[^}]*\})*\])*[[:space:]]*\{[^}]*\}/)) {
                    m = substr(text, RSTART, RLENGTH)
                    text = substr(text, RSTART + RLENGTH)
                    g = (m ~ /^\\includegraphics/)
                    match(m, /\{[^}]*\}$/)
                    t = substr(m, RSTART + 1, RLENGTH - 2)
                    gsub(/[[:space:]]+/, " ", t)
                    gsub(/^ | $/, "", t)
                    sub(/^\.\//, "", t)
                    dir = ""; base = t
                    if (index(t, "/")) { dir = t; sub(/\/[^\/]*$/, "", dir); sub(/.*\//, "", base) }
                    if (dir == "" && gp && g) { dir = "figs"; t = "figs/" t }
                    if (dir != "figs" && dir != "figs/srcs" && dir != "tabs") continue
                    b = base; sub(/\..*/, "", b)
                    if (!match(b, /^[0-9]+_/)) continue
                    k = substr(b, 1, RLENGTH - 1)
                    if (k != key) print t "\t" k "\t" (g ? "g" : "i")
                }
            }' "${includer}" 2>/dev/null || true)"
        # Name the file on disk: \input reads the target's .tex when it exists,
        # and \includegraphics the one file that adds an extension to it; with
        # none or several, the target is named as written. One warning per
        # file, however many includes name it.
        seen=$'\n'
        while IFS=$'\t' read -r target tkey kind; do
            [[ -n "${target}" ]] || continue
            if [[ "${kind}" == i && "${target}" != *.tex && -f "${MANU_DIR}/${target}.tex" ]]; then
                target="${target}.tex"
            elif [[ "${kind}" == g && ! -f "${MANU_DIR}/${target}" ]]; then
                found=''; matches=0
                for candidate in "${MANU_DIR}/${target}".*; do
                    if [[ -f "${candidate}" ]]; then
                        matches=$(( matches + 1 )); found="${candidate#"${MANU_DIR}"/}"
                    fi
                done
                if (( matches == 1 )); then
                    target="${found}"
                fi
            fi
            case "${seen}" in
                *$'\n'"${target}"$'\n'*) continue ;;
            esac
            seen="${seen}${target}"$'\n'
            asset="${target##*/}"
            warn "manus/${target} is included from ${includer#"${ROOT_DIR}"/} with key ${tkey}, where its includer's key is ${ikey} — expected ${ikey}_${asset#*_}; re-key it with stage-outl-planner (conventions §10.6)."
        done <<< "${hits}"
    done

    if (( WARNS == before && unread == 0 )); then
        log "ok: manuscript file names follow <nn>_<slug>, list in one order everywhere, and carry their includer's key."
    fi
}

# ---- manuscript sources (warning when one cannot be read) -------------------
# Every *.tex and *.sty file under manus/ that the checks below read — the todo
# count, the identity scan, the prose review — listed once, in byte order, and
# handed to awk as file arguments, never piped through grep's path:line: text,
# where a % in the repository's path would read as a comment. Regular files
# only, so a named pipe never blocks a reader; readable ones only, because awk
# stops at the first file it cannot open and takes every later file with it.
# Each file that cannot be read (a class file too) is named here, once: no
# check below sees into it, so none can vouch for it.
MANU_SOURCES=()
MANU_TEX=()
while IFS= read -r -d '' file; do
    if [[ ! -r "${file}" ]]; then
        warn "${file#"${ROOT_DIR}"/} cannot be read, so no check read it — its todo markers, includes, identity leaks, and prose went unchecked; restore its read permission."
    elif [[ "${file}" == *.tex ]]; then
        MANU_SOURCES+=("${file}")
        MANU_TEX+=("${file}")
    elif [[ "${file}" == *.sty ]]; then
        MANU_SOURCES+=("${file}")
    fi
done < <(find "${MANU_DIR}" -type f \( -name '*.tex' -o -name '*.sty' -o -name '*.cls' \) -print0 2>/dev/null |
    LC_ALL=C sort -z)

# ---- 0. file names and keys (warning; §10.6) --------------------------------
# Reads the file tree and the includes, never the build, so it runs first
# and still reports when the build fails. Every file under secs/, figs/ (files
# only; srcs/ is its own directory), figs/srcs/, and tabs/ is <nn>_<slug>.<ext>;
# each directory then lists in one order in git and ls and in VS Code, Overleaf,
# and Finder, provided every number inside a slug is padded to one width; every
# figure, figure source, and table carries the key of a section, or 00 for
# main.tex; and every keyed include under figs/ or tabs/ carries its includer's
# key. A warning on purpose: a name cannot move a page or a reference, and
# renaming is stage-outl-planner's. Never scans cycls/ (the poster reuses
# manus/figs/ by relative path) or wkdrs/.
IN_WORK_TREE=false
if git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    IN_WORK_TREE=true
fi
check_file_names

# ---- build ------------------------------------------------------------------
if [[ "${NO_BUILD}" == true ]]; then
    # run.sh leaves this marker when latexmk fails; a PDF and log can outlive
    # that failure, so they alone do not prove the last build finished.
    [[ ! -f "${BUILD_DIR}/main.failed" ]] || \
        fail "--no-build: the last build failed (execs/run.sh exited non-zero; see wkdrs/builds/main.log and main.blg). Fix the source, then run 'bash execs/run.sh'."
    [[ -f "${LOG_FILE}" && -f "${PDF_FILE}" ]] || \
        fail "--no-build: no finished build under wkdrs/builds/. Run 'bash execs/run.sh' first."
    log "Reusing the existing build in wkdrs/builds/ (--no-build)."
    # Build freshness is the one place mtime is the right signal. §8 bars mtime
    # for evidence staleness, where the question is whether upstream bytes moved;
    # here the question is only whether this PDF predates the sources the checks
    # below describe. Reporting a reused build as current is the failure mode.
    STALE_SRC="$(find "${MANU_DIR}" -type f \
        \( -name '*.tex' -o -name '*.sty' -o -name '*.bib' \) \
        -newer "${PDF_FILE}" 2>/dev/null || true)"
    if [[ -n "${STALE_SRC}" ]]; then
        log "warn: these sources changed after the reused build — the checks below describe an older PDF:"
        show_hits "${STALE_SRC}"
        WARNS=$(( WARNS + 1 ))
    fi
else
    bash "${ROOT_DIR}/execs/run.sh" || \
        fail "build failed — fix the manuscript first (see ${LOG_FILE})."
fi

# ---- 1. undefined citations / references (hard) -----------------------------
UNDEF="$(LC_ALL=C grep -a -E '(LaTeX|Package natbib|Package biblatex) Warning: (Citation|Reference) .* undefined' "${LOG_FILE}" | LC_ALL=C sort -u || true)"
if [[ -z "${UNDEF}" ]]; then
    UNDEF="$(LC_ALL=C grep -a 'There were undefined' "${LOG_FILE}" || true)"
fi
n="$(count_lines "${UNDEF}")"
if (( n > 0 )); then
    log "FAIL: ${n} undefined citation/reference warning(s):"
    show_hits "${UNDEF}"
    HARD=$(( HARD + 1 ))
else
    log "ok: no undefined citations or references."
fi

# ---- 2. overfull hboxes (warning) -------------------------------------------
OVERFULL="$(LC_ALL=C grep -a -c '^Overfull \\hbox' "${LOG_FILE}" || true)"
OVERFULL="${OVERFULL:-0}"
if (( OVERFULL > 0 )); then
    log "warn: ${OVERFULL} overfull hbox(es) — see ${LOG_FILE}."
    WARNS=$(( WARNS + 1 ))
else
    log "ok: no overfull hboxes."
fi

# ---- 3. todo markers (hard; §9a) --------------------------------------------
# A marker counts only where LaTeX would typeset it. Each source file is read
# as TeX reads it (tex_line above): its comments cut — from the first % that an
# even run of backslashes precedes (\% is a percent sign, \\% a line break and
# then a comment) — a line whose comment was cut running straight into the
# next, and any other line ending in one space. So a commented-out marker, or
# a comment that merely names the macro, does not fail the gate, while
# \todo {x}, and a \todo whose brace opens the next line after a comment or a
# plain line end, do. \\ is masked after the join, so \\todo is a line break
# and then text. Each hit names the line its \todo starts on. Only what ships
# in the PDF is a §9a violation. The files are the source list above, so
# neither a % in the repository's path nor a named pipe can hide a marker, and
# an unreadable file was named there. Bytes are read as bytes (LC_ALL=C): under
# a UTF-8 locale a line holding a byte that is not UTF-8 would drop out, and
# its marker with it.
TODOS=""
if (( ${#MANU_SOURCES[@]} > 0 )); then
    TODOS="$(LC_ALL=C awk "${TEX_AWK}"'
        # \\ becomes two bytes, not one, so a match offset in the masked text
        # is its offset in the joined text, and at[] maps it to a line.
        function report(    s, off, p, i, l) {
            s = text
            gsub(/\\\\/, "\001\001", s)
            off = 0
            while (match(s, /\\todo[[:space:]]*\{/)) {
                p = off + RSTART
                l = 1
                for (i = 1; i <= lines; i++) if (at[i] <= p) l = i
                print file ":" l ":" src[l]
                off += RSTART + RLENGTH - 1
                s = substr(s, RSTART + RLENGTH)
            }
        }
        FNR == 1 {
            if (NR > 1) report()
            file = FILENAME; text = ""; lines = 0
            split("", at); split("", src)
        }
        { lines = FNR; at[FNR] = length(text) + 1; src[FNR] = $0; text = text tex_line($0) }
        END { if (NR > 0) report() }' "${MANU_SOURCES[@]}" 2>/dev/null || true)"
fi
n="$(count_lines "${TODOS}")"
if (( n > 0 )); then
    log "FAIL: ${n} todo marker(s) in manus/ — each is a number or passage still lacking evidence:"
    show_hits "${TODOS}"
    HARD=$(( HARD + 1 ))
else
    log "ok: no todo markers in manus/."
fi

# ---- 4. page count vs the active cycle's limit ------------------------------
PAGES=""
if command -v pdfinfo >/dev/null 2>&1; then
    PAGES="$(pdfinfo "${PDF_FILE}" 2>/dev/null | LC_ALL=C awk '/^Pages:/ {print $2}' || true)"
fi
if [[ -z "${PAGES}" ]]; then
    PAGES="$(LC_ALL=C sed -n 's/.*(\([0-9][0-9]*\) page.*/\1/p' "${LOG_FILE}" | tail -1 || true)"
fi
if ! [[ "${PAGES}" =~ ^[0-9]+$ ]]; then
    PAGES=""
fi
if [[ -n "${PAGES}" ]]; then
    log "build: wkdrs/builds/main.pdf (${PAGES} pages)"
else
    log "warn: could not determine the page count."
    WARNS=$(( WARNS + 1 ))
fi

STORY="${ROOT_DIR}/notes/story.md"
CYCLE=""
if [[ -f "${STORY}" ]]; then
    CYCLE="$(LC_ALL=C awk -F': *' '/^cycle:/ {print $2; exit}' "${STORY}" | tr -d ' \t\r' || true)"
fi
if [[ ! -f "${STORY}" ]]; then
    log "note: page-limit check skipped — notes/story.md absent (no active cycle yet)."
elif [[ -z "${CYCLE}" ]]; then
    log "note: page-limit check skipped — no 'cycle:' in notes/story.md frontmatter."
elif [[ ! -f "${ROOT_DIR}/cycls/${CYCLE}/venue.yml" ]]; then
    log "note: page-limit check skipped — cycls/${CYCLE}/venue.yml absent."
else
    LIMIT="$(LC_ALL=C awk -F': *' '/^page_limit_main:/ {print $2; exit}' "${ROOT_DIR}/cycls/${CYCLE}/venue.yml" | LC_ALL=C sed 's/#.*//' | tr -d ' \t\r' || true)"
    REFS_IN="$(LC_ALL=C awk -F': *' '/^references_in_limit:/ {print $2; exit}' "${ROOT_DIR}/cycls/${CYCLE}/venue.yml" | LC_ALL=C sed 's/#.*//' | tr -d ' \t\r' || true)"
    # stage.cls labels the page the reference list starts on (stage@refs).
    # Counting that page as content is the conservative reading. No label — no
    # bibliography yet, or a stage.cls or kernel without the hook — means total pages.
    COUNT="${PAGES}"
    COUNTED="${PAGES} pages"
    TOTAL_NOTE="; count is total PDF pages, references included"
    if [[ "${REFS_IN}" != "true" && -f "${BUILD_DIR}/main.aux" ]]; then
        REFS_PAGE="$(LC_ALL=C sed -n 's/^\\newlabel{stage@refs}{{[^}]*}{\([0-9][0-9]*\)}.*/\1/p' "${BUILD_DIR}/main.aux" | head -1 || true)"
        if [[ -n "${REFS_PAGE}" ]]; then
            COUNT="${REFS_PAGE}"
            COUNTED="${REFS_PAGE} content pages (through the page the references start on; ${PAGES:-?} total)"
            TOTAL_NOTE=""
        fi
    fi
    if ! [[ "${LIMIT}" =~ ^[0-9]+$ ]]; then
        log "note: page-limit check skipped — no numeric page_limit_main in cycls/${CYCLE}/venue.yml."
    elif [[ -z "${COUNT}" ]]; then
        log "note: page-limit check skipped — page count unknown."
    elif (( COUNT > LIMIT )); then
        log "FAIL: ${COUNTED} exceeds page_limit_main ${LIMIT} (cycle ${CYCLE}${TOTAL_NOTE})."
        HARD=$(( HARD + 1 ))
    else
        log "ok: ${COUNTED} within page_limit_main ${LIMIT} (cycle ${CYCLE})."
    fi
fi

# ---- 5. identity leaks (hard; only while ANON=true) -------------------------
# The scan reads what LaTeX would typeset: each line has its comment stripped —
# from the first unescaped % to end of line (tex_code) — before any pattern is
# tested, so a commented-out \author or \thanks block, the standard way to
# anonymize, does not fail the gate (the todo check above strips comments for
# the same reason). Every pattern is ASCII, so the scan reads bytes (LC_ALL=C)
# and a byte that is not UTF-8 hides no line from it.
# A comment still ships with a source upload: a real name in one is the
# author's to delete, and no check here sees it.
# A hard hit is an \author, a title-panel macro (\affiliation, \correspondence,
# \email, the links row and the \metadata under it), or an e-mail address (not
# a file name such as figs/teaser@2x.png) that does not say anonymous; a
# \thanks; an acknowledgments heading or environment (the heading, because the
# word alone is ordinary prose); and a \documentclass{stys/stage} in main.tex
# without the anon option, whose title panel prints what that option hides.
# github.com links are a warning, not a failure: citing third-party code by URL
# is routine in a paper, and only a human can tell facebookresearch from the
# authors' own account — the warning names each link so that read happens.
# The files are the source list's *.tex (an unreadable one was named there).
# ANON is true or false, as .env.example has it: any other value — a typo, or
# an inline comment, which env_value keeps as part of the value — is a hard
# failure, since which scan the author meant cannot be known, and a scan that
# silently did not run would pass the gate.
if [[ "${ANON}" == "true" ]]; then
    ANON_OUT=""
    if (( ${#MANU_TEX[@]} > 0 )); then
        ANON_OUT="$(LC_ALL=C awk "${TEX_AWK}"'
            # An address anywhere on the line; a match ending in a file
            # extension is a density-suffixed file name (teaser@2x.png) and
            # is skipped.
            function has_addr(s,   m) {
                while (match(s, /[A-Za-z0-9._+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z][A-Za-z]+/)) {
                    m = tolower(substr(s, RSTART, RLENGTH))
                    if (m !~ /\.(png|jpe?g|pdf|eps|svg|tex)$/) return 1
                    s = substr(s, RSTART + RLENGTH)
                }
                return 0
            }
            {
                code = tex_code($0)
                low = tolower(code)
                loc = FILENAME ":" FNR ":"
                if (code ~ /\\author/ && low !~ /anonymous/) print "H " loc $0
                else if (code ~ /\\(affiliation|correspondence|email|code|project|dataset|demo|metadata)(\[[^]]*\])?\{/ && low !~ /anonymous/) print "H " loc $0
                else if (has_addr(code) && low !~ /anonymous/) print "H " loc $0
                else if (code ~ /\\thanks\{/) print "H " loc $0
                else if (low ~ /\\((sub)*section|paragraph)\*?\{[^}]*acknowledg/ || low ~ /\\begin\{ack/ || low ~ /\\acks/) print "H " loc $0
                if (code ~ /github\.com\/[A-Za-z0-9_.-]+/) print "W " loc $0
            }' "${MANU_TEX[@]}" 2>/dev/null | LC_ALL=C sort -u || true)"
    fi
    LEAKS="$(printf '%s\n' "${ANON_OUT}" | LC_ALL=C sed -n 's/^H //p')"
    LINKS="$(printf '%s\n' "${ANON_OUT}" | LC_ALL=C sed -n 's/^W //p')"
    # The PDF half: read the first uncommented \documentclass up to its
    # closing brace, joined from the line it starts on as TeX joins lines
    # (tex_line), so a class name or option list split by a comment inside its
    # brackets or braces ('{stys/%' then '  stage}') still reads as one; \\ is
    # masked, since \\documentclass is a line break and then text. Every byte
    # outside printable ASCII then becomes ?, since bash's =~ below matches
    # nothing in a string that holds a byte that is not UTF-8 before the
    # match, and the class name and options are ASCII.
    if [[ -f "${MANU_DIR}/main.tex" && -r "${MANU_DIR}/main.tex" ]]; then
        DOCCLASS="$(LC_ALL=C awk "${TEX_AWK}"'
            {
                code = tex_code($0)
                gsub(/\\\\/, "\001", code)
                if (!start && code ~ /\\documentclass/) { start = FNR; acc = "" }
                if (start) {
                    acc = acc tex_line($0)
                    masked = acc
                    gsub(/\\\\/, "\001", masked)
                    if (masked ~ /\\documentclass[[:space:]]*(\[[^]]*\])?[[:space:]]*\{[^}]*\}/) {
                        gsub(/[^[:print:][:space:]]/, "?", masked)
                        print start "\t" masked
                        exit
                    }
                }
            }' "${MANU_DIR}/main.tex" 2>/dev/null || true)"
        DOC_LINE="${DOCCLASS%%$'\t'*}"
        DOC_CODE="${DOCCLASS#*$'\t'}"
        if [[ -n "${DOCCLASS}" && "${DOC_CODE}" =~ \{[[:space:]]*stys/stage[[:space:]]*\} ]]; then
            DOC_OPTS=""
            if [[ "${DOC_CODE}" =~ \\documentclass[[:space:]]*\[([^]]*)\] ]]; then
                DOC_OPTS="${BASH_REMATCH[1]}"
            fi
            if ! printf ',%s,' "${DOC_OPTS}" | tr -d ' \t' | grep -qF ',anon,'; then
                append_lines LEAKS "${MANU_DIR}/main.tex:${DOC_LINE}: \\documentclass without the anon option, so the title panel prints what anon hides"
            fi
        fi
    fi
    n="$(count_lines "${LEAKS}")"
    if (( n > 0 )); then
        log "FAIL: ANON=true and ${n} possible identity leak(s):"
        show_hits "${LEAKS}"
        HARD=$(( HARD + 1 ))
    else
        log "ok: ANON=true and no identity leaks found."
    fi
    n="$(count_lines "${LINKS}")"
    if (( n > 0 )); then
        log "warn: ANON=true and ${n} github.com link(s) — verify none points at the authors' own account:"
        show_hits "${LINKS}"
        WARNS=$(( WARNS + 1 ))
    fi
elif [[ "${ANON}" == "false" ]]; then
    log "note: ANON=false — identity-leak scan skipped."
else
    log "FAIL: ANON is '${ANON}', neither true nor false, so no identity-leak scan ran — write ANON=true or ANON=false in .env with nothing after it, not even a space; a comment goes on a line of its own."
    HARD=$(( HARD + 1 ))
fi

# ---- 6. one sentence per line (warning; §3.7) -------------------------------
# Delegated to fmt.sh, which owns the rule and the tool. A warning on purpose:
# where a line breaks cannot move a page, a reference, or a todo count, so it
# never blocks a submission — but drift means the next diff is a paragraph
# rather than a sentence, and that is worth a line here.
FMT_SH="${ROOT_DIR}/execs/scpts/fmt.sh"
if [[ ! -f "${FMT_SH}" ]]; then
    log "note: sentence-per-line check skipped — execs/scpts/fmt.sh absent."
else
    FMT_OUT="$(bash "${FMT_SH}" --check 2>&1)" && FMT_RC=0 || FMT_RC=$?
    case "${FMT_RC}" in
        0)
            log "ok: manuscript sources read one sentence per line."
            ;;
        3)
            log "note: sentence-per-line check skipped — ${FMT_OUT#*ERROR: }"
            ;;
        4)
            log "warn: the sentence-per-line check could not read every file:"
            printf '%s\n' "${FMT_OUT}" | sed -e 's/^\[STAGE fmt\] //' -e 's/^/      /'
            WARNS=$(( WARNS + 1 ))
            ;;
        *)
            log "warn: manuscript sources are not one sentence per line:"
            printf '%s\n' "${FMT_OUT}" | sed -e 's/^\[STAGE fmt\] //' -e 's/^/      /'
            WARNS=$(( WARNS + 1 ))
            ;;
    esac
fi

# ---- 7. formulaic prose patterns (advisory warning) -------------------------
check_prose_patterns

# ---- 8. word counts (informational) -----------------------------------------
if command -v texcount >/dev/null 2>&1; then
    TC_FILES=("manus/main.tex")
    for f in "${MANU_DIR}"/secs/*.tex; do
        if [[ -f "${f}" ]]; then
            TC_FILES+=("manus/secs/$(basename -- "${f}")")
        fi
    done
    log "word counts (texcount: text+headers+captions per file):"
    (cd "${ROOT_DIR}" && texcount -brief -q "${TC_FILES[@]}" 2>/dev/null | sed 's/^/      /') || true
else
    log "note: texcount not installed — word counts skipped."
fi

# ---- verdict ----------------------------------------------------------------
if (( HARD > 0 )); then
    log "${HARD} hard failure(s), ${WARNS} warning(s) — fix the failures above."
    exit 1
fi
log "clean: 0 hard failures, ${WARNS} warning(s)."
