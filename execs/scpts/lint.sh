#!/usr/bin/env bash
set -euo pipefail

# execs/scpts/lint.sh — deterministic manuscript checks (conventions §3, §9).
# Judgment lives in skills; this script only reports what a grep can prove.
# Hard failures (exit 1): undefined citations/references, todo markers,
# page count over the venue limit, identity leaks while ANON=true.
# Prose-pattern findings are advisory prompts for human review, never authorship
# classification and never a submission gate.

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
    - page count over page_limit_main in the active cycle's venue.yml
    - identity leaks while ANON=true in .env

  warnings and notes (reported, exit 0):
    - overfull hboxes
    - sources newer than a reused build (--no-build only)
    - manuscript sources that no longer read one sentence per line
      (execs/scpts/fmt.sh --check; where a line breaks cannot move a page)
    - high-confidence chatbot residue or paragraphs containing multiple
      formulaic-prose patterns (advisory; not proof of AI authorship)
    - per-file word counts (when texcount is installed)

A todo marker inside a LaTeX comment is not a failure: each candidate line has
its comment stripped before the test, so only markers that would reach the PDF
count.

Options:
  --no-build    Reuse the latest wkdrs/builds/ output instead of rebuilding.
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
    val="$(sed -n "s/^[[:space:]]*${key}=//p" "${ENV_FILE}" | tail -1)"
    val="${val%$'\r'}"                   # tolerate a CRLF .env
    val="${val%\"}"; val="${val#\"}"     # and a quoted value
    val="${val%\'}"; val="${val#\'}"
    printf '%s' "${val}"
}

ANON="${ANON:-$(env_value ANON)}"
ANON="$(printf '%s' "${ANON:-false}" | tr '[:upper:]' '[:lower:]')"

count_lines() {
    if [[ -n "$1" ]]; then
        printf '%s\n' "$1" | wc -l | tr -d '[:space:]'
    else
        printf '0'
    fi
}

show_hits() {
    printf '%s\n' "$1" | sed -e "s|${ROOT_DIR}/||" -e 's/^/      /'
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

check_prose_patterns() {
    local file prose_output location patterns snippet
    local prose_count=0
    local -a prose_files=()

    while IFS= read -r file; do
        prose_files+=("${file}")
    done < <(find "${MANU_DIR}/secs" "${MANU_DIR}/tabs" -type f -name '*.tex' -print 2>/dev/null | sort)

    if (( ${#prose_files[@]} == 0 )); then
        log "note: prose review skipped — no section or table TeX files found."
        return
    fi

    prose_output="$(awk '
        function strip_comment(text, start) {
            start = match(text, /(^|[^\\])%/)
            if (!start) return text
            if (substr(text, start, 1) == "%") return substr(text, 1, start - 1)
            return substr(text, 1, start)
        }
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
            line = strip_comment($0)
            gsub(/\r/, "", line)

            table_file = (current_file ~ /\/tabs\//)
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
    ' "${prose_files[@]}")"

    if [[ -z "${prose_output}" ]]; then
        log "ok: prose review found no high-confidence chatbot residue or clustered formulaic prose."
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

# ---- build ------------------------------------------------------------------
if [[ "${NO_BUILD}" == true ]]; then
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
UNDEF="$(grep -E 'LaTeX Warning: (Citation|Reference) .* undefined' "${LOG_FILE}" || true)"
if [[ -z "${UNDEF}" ]]; then
    UNDEF="$(grep 'There were undefined' "${LOG_FILE}" || true)"
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
OVERFULL="$(grep -c '^Overfull \\hbox' "${LOG_FILE}" || true)"
OVERFULL="${OVERFULL:-0}"
if (( OVERFULL > 0 )); then
    log "warn: ${OVERFULL} overfull hbox(es) — see ${LOG_FILE}."
    WARNS=$(( WARNS + 1 ))
else
    log "ok: no overfull hboxes."
fi

# ---- 3. todo markers (hard; §9a) --------------------------------------------
# A marker counts only where LaTeX would typeset it. Each candidate line has its
# comment stripped — from the first unescaped % to end of line — before the test,
# so a commented-out marker, or a comment that merely names the macro, does not
# fail the gate. Only what ships in the PDF is a §9a violation.
TODOS="$(grep -rn -F '\todo{' --include='*.tex' --include='*.sty' "${MANU_DIR}" 2>/dev/null \
    | awk '{ code = $0
             gsub(/\\%/, "\002", code)
             sub(/%.*/, "", code)
             if (index(code, "\\todo{") > 0) print }' || true)"
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
    PAGES="$(pdfinfo "${PDF_FILE}" 2>/dev/null | awk '/^Pages:/ {print $2}' || true)"
fi
if [[ -z "${PAGES}" ]]; then
    PAGES="$(sed -n 's/.*(\([0-9][0-9]*\) page.*/\1/p' "${LOG_FILE}" | tail -1 || true)"
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
    CYCLE="$(awk -F': *' '/^cycle:/ {print $2; exit}' "${STORY}" | tr -d ' \t\r' || true)"
fi
if [[ ! -f "${STORY}" ]]; then
    log "note: page-limit check skipped — notes/story.md absent (no active cycle yet)."
elif [[ -z "${CYCLE}" ]]; then
    log "note: page-limit check skipped — no 'cycle:' in notes/story.md frontmatter."
elif [[ ! -f "${ROOT_DIR}/cycls/${CYCLE}/venue.yml" ]]; then
    log "note: page-limit check skipped — cycls/${CYCLE}/venue.yml absent."
else
    LIMIT="$(awk -F': *' '/^page_limit_main:/ {print $2; exit}' "${ROOT_DIR}/cycls/${CYCLE}/venue.yml" | sed 's/#.*//' | tr -d ' \t\r' || true)"
    if ! [[ "${LIMIT}" =~ ^[0-9]+$ ]]; then
        log "note: page-limit check skipped — no numeric page_limit_main in cycls/${CYCLE}/venue.yml."
    elif [[ -z "${PAGES}" ]]; then
        log "note: page-limit check skipped — page count unknown."
    elif (( PAGES > LIMIT )); then
        log "FAIL: ${PAGES} pages exceeds page_limit_main ${LIMIT} (cycle ${CYCLE}; count is total PDF pages, references included)."
        HARD=$(( HARD + 1 ))
    else
        log "ok: ${PAGES} pages within page_limit_main ${LIMIT} (cycle ${CYCLE})."
    fi
fi

# ---- 5. identity leaks (hard; only while ANON=true) -------------------------
if [[ "${ANON}" == "true" ]]; then
    LEAKS=""
    append_lines LEAKS "$(grep -rn --include='*.tex' -E '\\author' "${MANU_DIR}" 2>/dev/null | grep -vi 'anonymous' || true)"
    append_lines LEAKS "$(grep -rn --include='*.tex' -F '\thanks{' "${MANU_DIR}" 2>/dev/null || true)"
    append_lines LEAKS "$(grep -rn --include='*.tex' -E 'github\.com/[A-Za-z0-9_.-]+' "${MANU_DIR}" 2>/dev/null || true)"
    append_lines LEAKS "$(grep -rni --include='*.tex' 'acknowledg' "${MANU_DIR}" 2>/dev/null || true)"
    if [[ -n "${LEAKS}" ]]; then
        # One line can trip several detectors; report it once.
        LEAKS="$(printf '%s\n' "${LEAKS}" | sort -u)"
    fi
    n="$(count_lines "${LEAKS}")"
    if (( n > 0 )); then
        log "FAIL: ANON=true and ${n} possible identity leak(s):"
        show_hits "${LEAKS}"
        HARD=$(( HARD + 1 ))
    else
        log "ok: ANON=true and no identity leaks found."
    fi
else
    log "note: ANON=false — identity-leak scan skipped."
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
