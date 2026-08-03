#!/usr/bin/env bash
set -euo pipefail

# execs/run.sh — the STAGE build entrypoint: latexmk, out-of-tree.
#
# Sources .env when present (LATEX_ENGINE selects the engine), then builds
# manus/main.tex into wkdrs/builds/ so no LaTeX byproduct ever lands next to
# the sources. Extra arguments are forwarded to latexmk unchanged.
#
# --main points the build at another entry point — the generated venue package
# under wkdrs/builds/ that stage-subm-packer has to prove compiles standalone.
# It is the same code path and the same LATEX_ENGINE, which is the whole reason
# it lives here rather than in an ad-hoc latexmk line inside a skill.

EXEC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${EXEC_DIR}/.." && pwd -P)"
ENV_FILE="${ROOT_DIR}/.env"
MAIN_TEX="${ROOT_DIR}/manus/main.tex"
BUILD_DIR=""            # resolved below; empty = derive from the entry point

log() {
    printf '[STAGE run] %s\n' "$*"
}

fail() {
    printf '[STAGE run] ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: bash execs/run.sh [--main <file.tex>] [--outdir <dir>] [latexmk-args...]

Build manus/main.tex with latexmk into wkdrs/builds/ (out-of-tree: the sources
stay clean). The engine comes from LATEX_ENGINE in .env — pdflatex | xelatex |
lualatex, default pdflatex. Anything else on the command line is forwarded to
latexmk unchanged.

Options:
  --main <file.tex>   Build this entry point instead of manus/main.tex. Used to
                      prove a generated package compiles standalone; the build
                      runs with the file's own directory as the working
                      directory and that directory's stys/ on TEXINPUTS.
  --outdir <dir>      Write build products here. Default: wkdrs/builds/ for the
                      manuscript, <entry-point-dir>/.build/ for any other entry
                      point — so a package build never clobbers the manuscript
                      build lint.sh reuses.
  -h, --help          Show this help message.

Examples:
  bash execs/run.sh            # incremental build
  bash execs/run.sh -gg        # force a full rebuild
  bash execs/run.sh -C         # clean wkdrs/builds/
  bash execs/run.sh --main wkdrs/builds/cvpr_2027_cvpr/main.tex
EOF
}

# Only these three options are consumed here; everything from the first
# unrecognized argument on is latexmk's, untouched.
while (( $# > 0 )); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --main)
            [[ $# -ge 2 ]] || fail "--main needs a path to a .tex entry point."
            MAIN_TEX="$2"
            [[ "${MAIN_TEX}" == /* ]] || MAIN_TEX="${PWD}/${MAIN_TEX}"
            shift 2
            ;;
        --outdir)
            [[ $# -ge 2 ]] || fail "--outdir needs a directory path."
            BUILD_DIR="$2"
            [[ "${BUILD_DIR}" == /* ]] || BUILD_DIR="${PWD}/${BUILD_DIR}"
            shift 2
            ;;
        *)
            break
            ;;
    esac
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

# .env is optional here: a fresh clone must build with the pdflatex default.
LATEX_ENGINE="${LATEX_ENGINE:-$(env_value LATEX_ENGINE)}"
LATEX_ENGINE="${LATEX_ENGINE:-pdflatex}"
case "${LATEX_ENGINE}" in
    pdflatex) ENGINE_FLAG="-pdf" ;;
    xelatex)  ENGINE_FLAG="-xelatex" ;;
    lualatex) ENGINE_FLAG="-lualatex" ;;
    *) fail "Unsupported LATEX_ENGINE '${LATEX_ENGINE}': use pdflatex, xelatex, or lualatex." ;;
esac

command -v latexmk >/dev/null 2>&1 || \
    fail "latexmk not found. Install TeX Live (MacTeX on macOS) first."
[[ -f "${MAIN_TEX}" ]] || fail "Entry point not found: ${MAIN_TEX}."

# Everything below is derived from the entry point, so the default path — no
# --main, no --outdir — resolves to exactly what this script always did.
MAIN_DIR="$(cd -- "$(dirname -- "${MAIN_TEX}")" && pwd -P)"
MAIN_BASE="$(basename -- "${MAIN_TEX}")"
MAIN_BASE="${MAIN_BASE%.tex}"

if [[ -z "${BUILD_DIR}" ]]; then
    if [[ "${MAIN_DIR}" == "${ROOT_DIR}/manus" ]]; then
        BUILD_DIR="${ROOT_DIR}/wkdrs/builds"
    else
        # A generated package builds beside itself, not into wkdrs/builds/ —
        # that directory holds the manuscript build lint.sh reuses with
        # --no-build, and a package overwriting main.pdf there would make the
        # next lint report the wrong document.
        BUILD_DIR="${MAIN_DIR}/.build"
    fi
fi

mkdir -p "${BUILD_DIR}"

# The entry point's own stys/ goes on TEXINPUTS so venue classes sitting beside
# it can load their sibling files by bare name; the skeleton itself needs only
# the -cd below, because it loads the package by path (\usepackage{stys/stage}).
# For the manuscript this is manus/stys/; for a generated package it is that
# package's stys/, which is what makes the package self-contained.
export TEXINPUTS="${MAIN_DIR}/stys:${TEXINPUTS:-}"

log "Engine: ${LATEX_ENGINE}; output: ${BUILD_DIR}"

# -cd compiles with the entry point's directory as the working directory so
# relative \input and stys/ paths resolve; the absolute -outdir keeps every
# generated file out of the tree.
if ! latexmk "${ENGINE_FLAG}" -interaction=nonstopmode -halt-on-error \
        -cd -outdir="${BUILD_DIR}" ${1+"$@"} "${MAIN_TEX}"; then
    fail "latexmk failed — see ${BUILD_DIR}/${MAIN_BASE}.log."
fi

PDF_FILE="${BUILD_DIR}/${MAIN_BASE}.pdf"
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
