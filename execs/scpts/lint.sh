#!/usr/bin/env bash
set -euo pipefail

# execs/scpts/lint.sh — deterministic manuscript checks (conventions §3, §9).
# Judgment lives in skills; this script only reports what a grep can prove.
# Hard failures (exit 1): undefined citations/references, todo markers,
# page count over the venue limit, identity leaks while ANON=true.

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

if [[ -f "${ENV_FILE}" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "${ENV_FILE}"
    set +a
fi
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

# ---- 6. word counts (informational) -----------------------------------------
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
