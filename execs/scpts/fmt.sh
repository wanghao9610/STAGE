#!/usr/bin/env bash
set -euo pipefail

# execs/scpts/fmt.sh — one sentence per line, mechanically (conventions §3.7).
#
# latexindent does the rewriting, configured by .latexindent.yaml at the
# repository root. This script decides what it is allowed to touch and — the
# part that matters — refuses any rewrite that would change the typeset text.
# Line breaks are free in LaTeX, so a correct reformat leaves the PDF identical
# byte for byte; a reformat that does not is a tool bug, and the manuscript is
# left as it was rather than rebuilt to find out.
#
# Exit codes:
#   0  every file already reads one sentence per line (or was just made to)
#   1  --check: at least one file would be reformatted
#   2  at least one file was refused — the rewrite would have altered the text
#   3  cannot run: no latexindent, no config, or a path this script may not touch

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
CONFIG="${ROOT_DIR}/.latexindent.yaml"

CHECK=false
TARGETS=""

log() {
    printf '[STAGE fmt] %s\n' "$*"
}

fail() {
    printf '[STAGE fmt] ERROR: %s\n' "$*" >&2
    exit 3
}

usage() {
    cat <<'EOF'
Usage: bash execs/scpts/fmt.sh [--check] [PATH ...]

Reformat the manuscript's LaTeX to one sentence per line — latexindent's
oneSentencePerLine, configured by .latexindent.yaml at the repository root.

With no PATH, the manuscript's own sources: manus/main.tex, manus/secs/,
manus/tabs/. A PATH may be a file or a directory; directories are searched for
*.tex.

Two trees are never formatted, named or not: manus/stys/ and any venue or
poster kit under cycls/*/template/. Those are byte-for-byte copies of what an
organizer shipped (conventions §10.4), and reformatting one is editing it.

Every rewrite is checked before it is kept. LaTeX collapses each whitespace run
to a single space, so a reformat that only moves line breaks leaves the typeset
text identical; the file is compared before and after under exactly that
normalization, and a file that fails is reported and left untouched. It needs a
hand fix — usually a sentence latexindent misread, such as a lowercase
abbreviation ("std.", "et al.") that ends a line and is better written with a
tie or an escaped space.

Options:
  --check       Report what would change; write nothing. Exit 1 on drift.
  -h, --help    Show this help message.

No build is run: formatting cannot move a page, a reference, or a todo count.
EOF
}

while (( $# > 0 )); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --check)
            CHECK=true
            ;;
        -*)
            fail "Unknown option: $1. Run 'bash execs/scpts/fmt.sh --help' for usage."
            ;;
        *)
            TARGETS="${TARGETS}$1
"
            ;;
    esac
    shift
done

command -v latexindent >/dev/null 2>&1 || \
    fail "latexindent not found. It ships with TeX Live and MacTeX; install it, or install the Perl script from https://github.com/cmhughes/latexindent.pl. No script here installs anything (conventions §3.5)."
[[ -f "${CONFIG}" ]] || \
    fail "no .latexindent.yaml at the repository root — the line-break rule has no definition to apply."

# A tree whose bytes are somebody else's. Matched on the repository-relative
# path, so it holds however the path was spelled on the command line.
is_protected() {
    case "$1" in
        manus/stys/*)                       return 0 ;;
        cycls/*/template/*|cycls/*/*/template/*) return 0 ;;
    esac
    return 1
}

# A repository-relative path for anything the caller spells: absolute, relative
# to the current directory, file or directory alike.
relative_to_root() {
    local arg="$1" dir base abs
    dir="$(dirname -- "${arg}")"
    base="$(basename -- "${arg}")"
    dir="$(cd -- "${dir}" 2>/dev/null && pwd -P)" || fail "No such path: ${arg}"
    abs="${dir%/}/${base}"
    case "${abs}" in
        "${ROOT_DIR}"/*) printf '%s' "${abs#"${ROOT_DIR}"/}" ;;
        "${ROOT_DIR}")   printf '%s' "." ;;
        *) fail "Outside this repository: ${arg}" ;;
    esac
}

# Repository-relative *.tex under one path, one per line.
expand_target() {
    local rel="$1" abs="${ROOT_DIR}/$1"
    if [[ -d "${abs}" ]]; then
        find "${abs}" -type f -name '*.tex' 2>/dev/null | sort | sed "s|^${ROOT_DIR}/||"
    elif [[ -f "${abs}" ]]; then
        printf '%s\n' "${rel}"
    fi
}

# ---- the file list ----------------------------------------------------------
FILES=""
if [[ -z "${TARGETS}" ]]; then
    for t in "manus/main.tex" "manus/secs" "manus/tabs"; do
        FILES="${FILES}$(expand_target "${t}")
"
    done
else
    while IFS= read -r arg; do
        [[ -n "${arg}" ]] || continue
        rel="$(relative_to_root "${arg}")"
        # Named explicitly, a protected path is refused rather than skipped: the
        # caller asked for something this script must not do.
        if is_protected "${rel}/"; then
            fail "${rel} is a byte-for-byte copy (conventions §10.4) and is never reformatted."
        fi
        [[ -e "${ROOT_DIR}/${rel}" ]] || fail "No such path: ${arg}"
        FILES="${FILES}$(expand_target "${rel}")
"
    done <<< "${TARGETS}"
fi

# Drop blanks, protected trees, and duplicates, keeping the order stable.
KEPT=""
while IFS= read -r rel; do
    [[ -n "${rel}" ]] || continue
    is_protected "${rel}" && continue
    case "
${KEPT}" in
        *"
${rel}
"*) continue ;;
    esac
    KEPT="${KEPT}${rel}
"
done <<< "${FILES}"
FILES="${KEPT}"

if [[ -z "${FILES}" ]]; then
    log "note: no .tex files to format."
    exit 0
fi

# ---- the guard --------------------------------------------------------------
# Everything TeX collapses: any run of whitespace is one space, a blank line is
# a paragraph break, and a space at a group edge is discarded. What survives
# this normalization is what the PDF shows — so two files that normalize alike
# typeset alike, whatever their line breaks, and two that do not are not the
# same document.
normalized() {
    perl -0777 -ne '
        s/\r\n/\n/g;
        my @paragraphs = split /\n[ \t]*\n[ \t\n]*/, $_;
        for (@paragraphs) {
            s/\s+/ /g;
            s/^ //;
            s/ $//;
            s/ +([}\]])/$1/g;
            s/([{\[]) +/$1/g;
        }
        print join("\n\n", @paragraphs);
    ' "$1"
}

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

DRIFT=""
UNSAFE=""
BROKE=""
CHANGED=0
CLEAN=0

while IFS= read -r rel; do
    [[ -n "${rel}" ]] || continue
    src="${ROOT_DIR}/${rel}"
    cand="${WORK}/$(printf '%s' "${rel}" | tr '/' '_')"
    cp "${src}" "${cand}"

    # latexindent's own regexes make Perl warn about experimental lookbehind on
    # every run; that noise is not this script's to relay.
    if ! latexindent -m -l="${CONFIG}" -s -w -c "${WORK}" -g "${WORK}/indent.log" \
        "${cand}" >/dev/null 2>&1; then
        BROKE="${BROKE}${rel}
"
        continue
    fi

    if cmp -s "${src}" "${cand}"; then
        CLEAN=$(( CLEAN + 1 ))
        continue
    fi

    if [[ "$(normalized "${src}")" != "$(normalized "${cand}")" ]]; then
        UNSAFE="${UNSAFE}${rel}
"
        continue
    fi

    if [[ "${CHECK}" == true ]]; then
        DRIFT="${DRIFT}${rel}
"
    else
        cp "${cand}" "${src}"
        CHANGED=$(( CHANGED + 1 ))
    fi
done <<< "${FILES}"

# ---- verdict ----------------------------------------------------------------
show() {
    printf '%s' "$1" | sed '/^$/d; s/^/      /'
}

count() {
    printf '%s' "$1" | sed '/^$/d' | wc -l | tr -d '[:space:]'
}

STATUS=0

if [[ -n "${BROKE}" ]]; then
    log "warn: latexindent failed on $(count "${BROKE}") file(s), left untouched:"
    show "${BROKE}"
    log "      reproduce with: latexindent -m -l=.latexindent.yaml -s <file>"
fi

if [[ -n "${UNSAFE}" ]]; then
    log "REFUSED: $(count "${UNSAFE}") file(s) whose reformat would have changed the typeset text — left untouched:"
    show "${UNSAFE}"
    log "      fix the sentence latexindent misread (a lowercase abbreviation before a capital is the usual one: write 'et al.\\ ' or 'Fig.~'), then run again."
    STATUS=2
fi

# The all-clear is only that when nothing was refused: a file left untouched is
# not a file that reads one sentence per line.
if [[ "${CHECK}" == true ]]; then
    if [[ -n "${DRIFT}" ]]; then
        log "$(count "${DRIFT}") file(s) are not one sentence per line:"
        show "${DRIFT}"
        log "      fix with: bash execs/scpts/fmt.sh"
        if (( STATUS == 0 )); then STATUS=1; fi
    elif [[ -z "${UNSAFE}${BROKE}" ]]; then
        log "ok: ${CLEAN} file(s) already read one sentence per line."
    fi
elif (( CHANGED > 0 )); then
    log "reformatted ${CHANGED} file(s); ${CLEAN} already clean."
elif [[ -z "${UNSAFE}${BROKE}" ]]; then
    log "ok: ${CLEAN} file(s) already read one sentence per line."
fi

exit "${STATUS}"
