#!/usr/bin/env bash
set -euo pipefail

# execs/run.sh — the STAGE build entrypoint: latexmk, out-of-tree.
#
# Sources .env when present (LATEX_ENGINE selects the engine), then builds
# manus/main.tex into wkdrs/builds/ so no LaTeX byproduct ever lands next to
# the sources. Extra arguments are forwarded to latexmk unchanged.

EXEC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${EXEC_DIR}/.." && pwd -P)"
ENV_FILE="${ROOT_DIR}/.env"
MAIN_TEX="${ROOT_DIR}/manus/main.tex"
BUILD_DIR="${ROOT_DIR}/wkdrs/builds"

log() {
    printf '[STAGE run] %s\n' "$*"
}

fail() {
    printf '[STAGE run] ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: bash execs/run.sh [latexmk-args...]

Build manus/main.tex with latexmk into wkdrs/builds/ (out-of-tree: the sources
stay clean). The engine comes from LATEX_ENGINE in .env — pdflatex | xelatex |
lualatex, default pdflatex. Anything else on the command line is forwarded to
latexmk unchanged.

Options:
  -h, --help    Show this help message.

Examples:
  bash execs/run.sh            # incremental build
  bash execs/run.sh -gg        # force a full rebuild
  bash execs/run.sh -C         # clean wkdrs/builds/
EOF
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

# .env is optional here: a fresh clone must build with the pdflatex default.
if [[ -f "${ENV_FILE}" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "${ENV_FILE}"
    set +a
fi

LATEX_ENGINE="${LATEX_ENGINE:-pdflatex}"
case "${LATEX_ENGINE}" in
    pdflatex) ENGINE_FLAG="-pdf" ;;
    xelatex)  ENGINE_FLAG="-xelatex" ;;
    lualatex) ENGINE_FLAG="-lualatex" ;;
    *) fail "Unsupported LATEX_ENGINE '${LATEX_ENGINE}': use pdflatex, xelatex, or lualatex." ;;
esac

command -v latexmk >/dev/null 2>&1 || \
    fail "latexmk not found. Install TeX Live (MacTeX on macOS) first."
[[ -f "${MAIN_TEX}" ]] || fail "Manuscript not found: ${MAIN_TEX}."

mkdir -p "${BUILD_DIR}"

# manus/stys/ goes on TEXINPUTS so venue classes dropped there can load their
# sibling files by bare name; the skeleton itself needs only the -cd below,
# because it loads the package by path (\usepackage{stys/stage}).
export TEXINPUTS="${ROOT_DIR}/manus/stys:${TEXINPUTS:-}"

log "Engine: ${LATEX_ENGINE}; output: ${BUILD_DIR}"

# -cd compiles with manus/ as the working directory so relative \input and
# stys/ paths resolve; the absolute -outdir keeps every generated file out of
# the tree.
if ! latexmk "${ENGINE_FLAG}" -interaction=nonstopmode -halt-on-error \
        -cd -outdir="${BUILD_DIR}" ${1+"$@"} "${MAIN_TEX}"; then
    fail "latexmk failed — see ${BUILD_DIR}/main.log."
fi

PDF_FILE="${BUILD_DIR}/main.pdf"
if [[ -f "${PDF_FILE}" ]]; then
    if command -v pdfinfo >/dev/null 2>&1; then
        PAGES="$(pdfinfo "${PDF_FILE}" 2>/dev/null | awk '/^Pages:/ {print $2}')"
        log "Built ${PDF_FILE} (${PAGES:-?} pages)"
    else
        log "Built ${PDF_FILE} (install pdfinfo for a page count)"
    fi
else
    log "latexmk finished without producing ${PDF_FILE} (expected for clean runs like -C)."
fi
