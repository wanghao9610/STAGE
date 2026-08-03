#!/usr/bin/env bash
set -euo pipefail

# execs/scpts/import.sh — snapshot evidence from a paired STAR repo into
# read-only mates/<slug>/ and record every file in mates/MANIFEST.md.
#
# Evidence flows one way (conventions §9): numbers live upstream. To fix one,
# fix it in the STAR repo and re-import — never edit mates/ in place. Entries
# with source-type: manual belong to /stage-evid-curator and are never
# touched here.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
ENV_FILE="${ROOT_DIR}/.env"
MANIFEST="${ROOT_DIR}/mates/MANIFEST.md"

OPT_SOURCE=""
OPT_SLUG=""
DIFF=false

log() {
    printf '[STAGE import] %s\n' "$*"
}

fail() {
    printf '[STAGE import] ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: bash execs/scpts/import.sh [--source PATH] [--slug NAME] [--diff]

Snapshot evidence from a paired STAR repo into mates/<slug>/, mirroring the
upstream paths, and record every file in mates/MANIFEST.md with its
fingerprint (the first generated:/updated:/finalized: line) and the source
commit. Evidence flows one way: to fix a number, fix it upstream and
re-import — never edit mates/ in place.

Options:
  --source PATH   Source repo (default: STAR_HOME from .env).
  --slug NAME     Destination mates/<slug>/ (default: the source directory's
                  basename, lowercased).
  --diff          Read-only staleness report: compare upstream against
                  mates/<slug>/ and list stale / new upstream / missing
                  upstream files. Exits 0 when clean, 1 when anything
                  drifted. Writes nothing.
  -h, --help      Show this help message.

Imported (skipped with a note when absent upstream):
  metds/{adopt,codearc,overview,framework,dataset,training,evaluation}.md
  metds/ideas/*.md      metds/refs/**  (including reference.bib)
  wkdrs/results/*.md    wkdrs/digests/*.md

Convenience: when manus/bibs/reference.bib is absent and the source has
metds/refs/reference.bib, a copy is seeded there.

Entries with source-type: manual (hand-dropped evidence under mates/manual/)
are owned by /stage-evid-curator and never touched by this script.
EOF
}

while (( $# > 0 )); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --source)
            shift
            (( $# > 0 )) || fail "--source requires a path."
            OPT_SOURCE="$1"
            ;;
        --source=*)
            OPT_SOURCE="${1#*=}"
            [[ -n "${OPT_SOURCE}" ]] || fail "--source requires a path."
            ;;
        --slug)
            shift
            (( $# > 0 )) || fail "--slug requires a name."
            OPT_SLUG="$1"
            ;;
        --slug=*)
            OPT_SLUG="${1#*=}"
            [[ -n "${OPT_SLUG}" ]] || fail "--slug requires a name."
            ;;
        --diff)
            DIFF=true
            ;;
        *)
            fail "Unknown argument: $1. Run 'bash execs/scpts/import.sh --help' for usage."
            ;;
    esac
    shift
done

if [[ -f "${ENV_FILE}" ]]; then
    # shellcheck source=/dev/null
    source "${ENV_FILE}"
fi

SOURCE_INPUT="${OPT_SOURCE:-${STAR_HOME:-}}"
[[ -n "${SOURCE_INPUT}" ]] || \
    fail "No evidence source: pass --source PATH, or set STAR_HOME in ${ENV_FILE} (copy .env.example to .env first)."
[[ -d "${SOURCE_INPUT}" ]] || fail "Source is not a directory: ${SOURCE_INPUT}"
SOURCE_DIR="$(cd -- "${SOURCE_INPUT}" && pwd -P)"

if [[ -n "${OPT_SLUG}" ]]; then
    SLUG="$(printf '%s' "${OPT_SLUG}" | tr '[:upper:]' '[:lower:]')"
else
    SLUG="$(basename -- "${SOURCE_DIR}" | tr '[:upper:]' '[:lower:]')"
fi
[[ "${SLUG}" =~ ^[a-z0-9][a-z0-9._-]*$ ]] || \
    fail "Slug '${SLUG}' must be lowercase [a-z0-9._-] and start with a letter or digit."
[[ "${SLUG}" != "manual" ]] || \
    fail "Slug 'manual' is reserved for hand-registered evidence (mates/manual/)."

DEST_DIR="${ROOT_DIR}/mates/${SLUG}"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEMP_DIR}"' EXIT
LIST_FILE="${TEMP_DIR}/candidates"
: > "${LIST_FILE}"

note_skip() {
    log "  skip: $1 (not present upstream)"
}

# The importable artifacts are a fixed list (conventions §8), not "everything
# upstream": evidence the writing side may cite, nothing else.
collect() {
    local f
    local found

    for f in metds/adopt.md metds/codearc.md metds/overview.md \
             metds/framework.md metds/dataset.md metds/training.md \
             metds/evaluation.md; do
        if [[ -f "${SOURCE_DIR}/${f}" ]]; then
            printf '%s\n' "${f}" >> "${LIST_FILE}"
        else
            note_skip "${f}"
        fi
    done

    found=false
    for f in "${SOURCE_DIR}"/metds/ideas/*.md; do
        if [[ -f "${f}" ]]; then
            printf 'metds/ideas/%s\n' "$(basename -- "${f}")" >> "${LIST_FILE}"
            found=true
        fi
    done
    if [[ "${found}" == false ]]; then
        note_skip "metds/ideas/*.md"
    fi

    found=false
    if [[ -d "${SOURCE_DIR}/metds/refs" ]]; then
        # Dotfiles (.gitkeep, .DS_Store) are scaffolding, not evidence.
        while IFS= read -r f; do
            printf '%s\n' "${f}" >> "${LIST_FILE}"
            found=true
        done < <(cd "${SOURCE_DIR}" && find metds/refs -type f -not -name '.*' 2>/dev/null | sort)
    fi
    if [[ "${found}" == false ]]; then
        note_skip "metds/refs/**"
    fi

    found=false
    for f in "${SOURCE_DIR}"/wkdrs/results/*.md; do
        if [[ -f "${f}" ]]; then
            printf 'wkdrs/results/%s\n' "$(basename -- "${f}")" >> "${LIST_FILE}"
            found=true
        fi
    done
    if [[ "${found}" == false ]]; then
        note_skip "wkdrs/results/*.md"
    fi

    found=false
    for f in "${SOURCE_DIR}"/wkdrs/digests/*.md; do
        if [[ -f "${f}" ]]; then
            printf 'wkdrs/digests/%s\n' "$(basename -- "${f}")" >> "${LIST_FILE}"
            found=true
        fi
    done
    if [[ "${found}" == false ]]; then
        note_skip "wkdrs/digests/*.md"
    fi
}

# First generated:/updated:/finalized: line of a file, value only; n/a when
# there is none (staleness then falls back to content comparison alone).
extract_stamp() {
    local line
    line="$(LC_ALL=C grep -a -m1 -E '^[[:space:]]*(generated|updated|finalized):' "$1" 2>/dev/null || true)"
    line="$(printf '%s' "${line}" | sed -e 's/^[[:space:]]*//' -e 's/^[a-z]*:[[:space:]]*//' -e 's/[[:space:]]*$//')"
    if [[ -n "${line}" ]]; then
        printf '%s' "${line}"
    else
        printf 'n/a'
    fi
}

# One line saying what a path evidences; a curator may sharpen it later and
# re-imports keep the sharpened wording.
default_covers() {
    case "$1" in
        metds/adopt.md)           printf 'how the paired STAR project is wired up' ;;
        metds/codearc.md)         printf 'code architecture of the paired project' ;;
        metds/overview.md)        printf 'method overview' ;;
        metds/framework.md)       printf 'framework / model description' ;;
        metds/dataset.md)         printf 'dataset facts' ;;
        metds/training.md)        printf 'training setup' ;;
        metds/evaluation.md)      printf 'evaluation protocol and headline results' ;;
        metds/refs/reference.bib) printf 'upstream bibliography' ;;
        metds/ideas/*)            printf 'idea note %s' "$(basename -- "$1" .md)" ;;
        metds/refs/*)             printf 'reference material %s' "$(basename -- "$1")" ;;
        wkdrs/results/*)          printf 'experiment results %s' "$(basename -- "$1" .md)" ;;
        wkdrs/digests/*)          printf 'experiment digest %s' "$(basename -- "$1" .md)" ;;
        *)                        printf 'imported evidence %s' "$1" ;;
    esac
}

# Replace the managed block for a key in MANIFEST (the block starts at the
# exact "## <key>" heading and runs to the next "## "), or append a new one.
# The new block must already sit in ${TEMP_DIR}/block. Only the addressed key
# is touched, so manual entries survive untouched by construction.
manifest_entry_replace() {
    local key="$1"
    local tmp="${TEMP_DIR}/manifest.rewrite"

    if grep -qxF "## ${key}" "${MANIFEST}"; then
        awk -v key="## ${key}" -v blockfile="${TEMP_DIR}/block" '
            $0 == key {
                while ((getline line < blockfile) > 0) print line
                close(blockfile)
                print ""
                drop = 1
                next
            }
            /^## / { drop = 0 }
            !drop  { print }
        ' "${MANIFEST}" > "${tmp}"
    else
        awk '{ lines[NR] = $0 }
             END {
                 n = NR
                 while (n > 0 && lines[n] ~ /^[[:space:]]*$/) n--
                 for (i = 1; i <= n; i++) print lines[i]
             }' "${MANIFEST}" > "${tmp}"
        printf '\n' >> "${tmp}"
        cat "${TEMP_DIR}/block" >> "${tmp}"
    fi
    mv "${tmp}" "${MANIFEST}"
}

if [[ "${DIFF}" == true ]]; then
    log "Staleness check: ${SOURCE_DIR} vs mates/${SLUG}/ (read-only)."
else
    log "Importing from ${SOURCE_DIR} into mates/${SLUG}/."
fi

collect

if [[ "${DIFF}" == true ]]; then
    drift=0

    while IFS= read -r rel; do
        src="${SOURCE_DIR}/${rel}"
        dst="${DEST_DIR}/${rel}"
        if [[ ! -e "${dst}" ]]; then
            printf '  new upstream      %s\n' "${rel}"
            drift=$(( drift + 1 ))
        elif ! cmp -s "${src}" "${dst}"; then
            printf '  stale             %s (upstream stamp: %s; imported stamp: %s)\n' \
                "${rel}" "$(extract_stamp "${src}")" "$(extract_stamp "${dst}")"
            drift=$(( drift + 1 ))
        fi
    done < "${LIST_FILE}"

    if [[ -d "${DEST_DIR}" ]]; then
        while IFS= read -r rel; do
            if [[ ! -e "${SOURCE_DIR}/${rel}" ]]; then
                printf '  missing upstream  %s (kept locally; upstream no longer has it)\n' "${rel}"
                drift=$(( drift + 1 ))
            fi
        done < <(cd "${DEST_DIR}" && find . -type f -not -name '.*' 2>/dev/null | sed 's|^\./||' | sort)
    fi

    if (( drift > 0 )); then
        log "${drift} path(s) drifted. Re-import with: bash execs/scpts/import.sh --source ${SOURCE_DIR} --slug ${SLUG}"
        exit 1
    fi
    if [[ ! -d "${DEST_DIR}" && ! -s "${LIST_FILE}" ]]; then
        log "Nothing to compare: upstream has no importable artifacts and mates/${SLUG}/ does not exist."
        exit 0
    fi
    log "mates/${SLUG}/ is in sync with ${SOURCE_DIR}."
    exit 0
fi

# ---- import -----------------------------------------------------------------
mkdir -p "${ROOT_DIR}/mates"
if [[ ! -f "${MANIFEST}" ]]; then
    {
        printf '# Evidence manifest\n\n'
        printf 'One `##` entry per file under `mates/`. Entries with `source-type: star` are\n'
        printf 'managed by `execs/scpts/import.sh` and rewritten on re-import; entries with\n'
        printf '`source-type: manual` are written by /stage-evid-curator and never touched\n'
        printf 'here. Entry format: conventions §8.\n\n'
        printf '<!-- entries below -->\n'
    } > "${MANIFEST}"
    log "Created mates/MANIFEST.md (it was missing)."
fi

SOURCE_COMMIT="$(git -C "${SOURCE_DIR}" rev-parse HEAD 2>/dev/null || printf 'n/a')"
TODAY="$(date +%Y-%m-%d)"

# MANIFEST names the source as $STAR_HOME/<rel> when that is where it came
# from, so the ledger stays valid across machines with different paths.
SRC_PREFIX="${SOURCE_DIR}"
if [[ -n "${STAR_HOME:-}" && -d "${STAR_HOME}" ]]; then
    if [[ "$(cd -- "${STAR_HOME}" && pwd -P)" == "${SOURCE_DIR}" ]]; then
        SRC_PREFIX='$STAR_HOME'
    fi
fi

imported=0
while IFS= read -r rel; do
    src="${SOURCE_DIR}/${rel}"
    dst="${DEST_DIR}/${rel}"
    key="${SLUG}/${rel}"

    mkdir -p "$(dirname -- "${dst}")"
    cp -p "${src}" "${dst}"

    stamp="$(extract_stamp "${src}")"
    covers="$(awk -v key="## ${key}" '
        $0 == key { f = 1; next }
        /^## /    { f = 0 }
        f && sub(/^- covers:[[:space:]]*/, "") { print; exit }
    ' "${MANIFEST}")"
    if [[ -z "${covers}" ]]; then
        covers="$(default_covers "${rel}")"
    fi

    {
        printf '## %s\n' "${key}"
        printf -- '- source-type: star\n'
        printf -- '- source: %s/%s\n' "${SRC_PREFIX}" "${rel}"
        printf -- '- source-commit: %s\n' "${SOURCE_COMMIT}"
        printf -- '- source-stamp: %s\n' "${stamp}"
        printf -- '- imported: %s\n' "${TODAY}"
        printf -- '- covers: %s\n' "${covers}"
    } > "${TEMP_DIR}/block"
    manifest_entry_replace "${key}"

    log "  imported: ${rel} (stamp: ${stamp})"
    imported=$(( imported + 1 ))
done < "${LIST_FILE}"

if (( imported == 0 )); then
    log "Nothing to import: upstream has none of the importable artifacts."
    log "Evidence can still be hand-registered under mates/manual/ via /stage-evid-curator."
    exit 0
fi

# Convenience seed: a manuscript needs a bibliography before the first
# /stage-refs-curator run; the mates/ copy above stays the fingerprinted one.
if [[ ! -f "${ROOT_DIR}/manus/bibs/reference.bib" && -f "${SOURCE_DIR}/metds/refs/reference.bib" ]]; then
    mkdir -p "${ROOT_DIR}/manus/bibs"
    cp -p "${SOURCE_DIR}/metds/refs/reference.bib" "${ROOT_DIR}/manus/bibs/reference.bib"
    log "Seeded manus/bibs/reference.bib from upstream metds/refs/reference.bib."
fi

log "Imported ${imported} file(s) from commit ${SOURCE_COMMIT} into mates/${SLUG}/; mates/MANIFEST.md updated."
log "mates/ is read-only from here: fix numbers upstream and re-import (conventions §9)."
