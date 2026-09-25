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
fingerprint: the source commit, the stamp (the first
generated:/updated:/finalized: line), and the sha256 of the file as it landed.
Evidence flows one way: to fix a number, fix it upstream and re-import — never
edit mates/ in place, which the checksum is there to catch.

Options:
  --source PATH   Source repo (default: STAR_HOME from .env).
  --slug NAME     Destination mates/<slug>/ (default: the source directory's
                  basename, lowercased).
  --diff          Read-only staleness report. Bare, it checks every slug
                  mates/MANIFEST.md records as source-type: star against its
                  recorded source, a leading $STAR_HOME read as the current
                  STAR_HOME; before the first star entry exists it previews
                  STAR_HOME against mates/<its basename>/. With --source or
                  --slug it compares that one upstream against mates/<slug>/.
                  Lists stale / new upstream / missing upstream / tampered
                  files, names importable files the upstream has not
                  committed, and reports a slug whose source is not
                  reachable as unknown. Exits 0 when clean, 2 when anything
                  drifted, 1 on a hard error or an unreachable source (no
                  source configured, bad slug) — drift and misconfiguration
                  are different answers and a caller reading the exit code
                  must be able to tell them apart. Writes nothing.
  -h, --help      Show this help message.

Imported (skipped with a note when absent upstream):
  metds/{adopt,codearc,overview,framework,dataset,training,evaluation}.md
  metds/ideas/*.md      metds/refs/**  (including reference.bib)
  wkdrs/results/*.md    wkdrs/digests/*.md

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

# One value out of .env, without sourcing the file: sourcing would overwrite a
# variable the caller set on the command line, and the precedence every STAGE
# entrypoint follows is environment, then .env, then the default (conventions
# §3.1) — the same order execs/update.sh uses for STAGE_REPOSITORY. It is what
# makes a one-off `STAR_HOME=… bash execs/scpts/import.sh` mean what it says.
env_value() {
    local key="$1" val
    [[ -f "${ENV_FILE}" ]] || return 0
    val="$(sed -n "s/^[[:space:]]*${key}=//p" "${ENV_FILE}" | tail -1)"
    val="${val%$'\r'}"                   # tolerate a CRLF .env
    val="${val%\"}"; val="${val#\"}"     # and a quoted value
    val="${val%\'}"; val="${val#\'}"
    printf '%s' "${val}"
}

STAR_HOME="${STAR_HOME:-$(env_value STAR_HOME)}"

SOURCE_DIR=""
SLUG=""
DEST_DIR=""

# The one upstream an import, or a --diff given --source or --slug, works on:
# --source, else STAR_HOME; the slug from --slug, else that directory's name.
resolve_source() {
    local input="${OPT_SOURCE:-${STAR_HOME:-}}"
    [[ -n "${input}" ]] || \
        fail "No evidence source: pass --source PATH, or set STAR_HOME in ${ENV_FILE} (copy .env.example to .env first)."
    [[ -d "${input}" ]] || fail "Source is not a directory: ${input}"
    SOURCE_DIR="$(cd -- "${input}" && pwd -P)"

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
}

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

# Checksum of the file as it landed — the integrity half of a fingerprint
# (conventions §8.2). Without it /stage-evid-curator's `check` has nothing to
# compare a star entry against, and a hand-edit under mates/ is only detectable
# while STAR_HOME is reachable. A missing tool is a degraded check to report,
# never a guessed value (conventions §3.5).
file_sha256() {
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        printf 'n/a (no sha256 tool on this host)'
    fi
}

# One line saying what a path evidences; re-import rewrites it with the rest
# of the entry.
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

# One field of a MANIFEST entry ("- <field>: <value>" under "## <key>"), value
# only; nothing when the entry or the field is absent.
manifest_field() {
    [[ -f "${MANIFEST}" ]] || return 0
    awk -v key="## $1" -v field="- $2:" '
        $0 == key { f = 1; next }
        /^## /    { f = 0 }
        f && index($0, field) == 1 {
            v = substr($0, length(field) + 1)
            sub(/^[[:space:]]+/, "", v)
            sub(/[[:space:]]+$/, "", v)
            print v
            exit
        }
    ' "${MANIFEST}"
}

# Importable files the source repository has not committed, as git's porcelain
# lines: a source-commit cannot pin their bytes. Nothing for a clean tree or a
# source that is not a git work tree.
upstream_dirty() {
    local -a paths=()
    local rel
    git -C "${SOURCE_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
    while IFS= read -r rel; do
        [[ -n "${rel}" ]] && paths+=("${rel}")
    done < "${LIST_FILE}"
    (( ${#paths[@]} > 0 )) || return 0
    git -C "${SOURCE_DIR}" status --porcelain --untracked-files=all -- "${paths[@]}" 2>/dev/null || true
}

# The read-only comparison of one upstream against one mates/<slug>/. Returns
# 0 in sync, 2 drifted: 2, not 1, because fail() exits 1 for a hard error (no
# source, bad slug), and a skill reading the exit code must not mistake a
# misconfigured STAR_HOME for stale evidence — the same triad update.sh --diff
# uses.
diff_one() {
    local rel src dst want have dirty head
    local drift=0 refresh=0 tampered=0 when
    SOURCE_DIR="$1"
    SLUG="$2"
    DEST_DIR="${ROOT_DIR}/mates/${SLUG}"
    : > "${LIST_FILE}"

    log "Staleness check: ${SOURCE_DIR} vs mates/${SLUG}/ (read-only)."
    collect

    while IFS= read -r rel; do
        src="${SOURCE_DIR}/${rel}"
        dst="${DEST_DIR}/${rel}"
        if [[ ! -e "${dst}" ]]; then
            printf '  new upstream      %s\n' "${rel}"
            drift=$(( drift + 1 )); refresh=$(( refresh + 1 ))
            continue
        fi
        # The copy is checked against its own registration first: a copy
        # edited in place is not upstream drift, and re-importing over it
        # would hide the edit.
        want="$(manifest_field "${SLUG}/${rel}" sha256)"
        have=""
        if [[ "${want}" =~ ^[0-9a-f]{64}$ ]]; then
            have="$(file_sha256 "${dst}")"
        fi
        if [[ "${have}" =~ ^[0-9a-f]{64}$ && "${have}" != "${want}" ]]; then
            printf '  tampered          %s (local copy no longer matches its MANIFEST sha256; /stage-evid-curator check)\n' "${rel}"
            drift=$(( drift + 1 )); tampered=$(( tampered + 1 ))
        elif ! cmp -s "${src}" "${dst}"; then
            printf '  stale             %s (upstream stamp: %s; imported stamp: %s)\n' \
                "${rel}" "$(extract_stamp "${src}")" "$(extract_stamp "${dst}")"
            drift=$(( drift + 1 )); refresh=$(( refresh + 1 ))
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

    dirty="$(upstream_dirty)"
    if [[ -n "${dirty}" ]]; then
        head="$(git -C "${SOURCE_DIR}" rev-parse HEAD 2>/dev/null || printf 'n/a')"
        log "note: upstream has uncommitted changes in $(printf '%s\n' "${dirty}" | wc -l | tr -d ' ') importable file(s); an import would record source-commit ${head}-dirty. Commit them in the STAR repo and re-import to pin the bytes:"
        printf '%s\n' "${dirty}" | sed 's/^/      /'
    fi

    # A re-import clears stale and new files. It never removes a local copy that
    # upstream dropped, and over a tampered copy it would overwrite the edit
    # before anyone saw it, so both go to the curator's check — the tampered
    # ones before any re-import.
    if (( drift > 0 )); then
        log "${drift} path(s) drifted."
        if (( tampered > 0 )); then
            log "${tampered} tampered: run /stage-evid-curator check first — a re-import overwrites a tampered copy and hides the edit."
        fi
        if (( drift - refresh - tampered > 0 )); then
            log "$(( drift - refresh - tampered )) missing upstream: a re-import never removes a local copy; settle them with /stage-evid-curator check."
        fi
        if (( refresh > 0 )); then
            when=""
            (( tampered > 0 )) && when=", once that check has run"
            log "${refresh} stale or new upstream${when}: re-import with: bash execs/scpts/import.sh --source ${SOURCE_DIR} --slug ${SLUG}"
        fi
        return 2
    fi
    if [[ ! -d "${DEST_DIR}" && ! -s "${LIST_FILE}" ]]; then
        log "Nothing to compare: upstream has no importable artifacts and mates/${SLUG}/ does not exist."
        return 0
    fi
    log "mates/${SLUG}/ is in sync with ${SOURCE_DIR}."
    return 0
}

# One line per slug MANIFEST holds star entries for: "<slug><TAB><source dir>",
# the directory being the entry's `- source:` minus its trailing /<rel>, from
# the first entry of that slug.
manifest_star_sources() {
    [[ -f "${MANIFEST}" ]] || return 0
    awk '
        function flush(    slug, rel, dir) {
            if (key != "" && type == "star") {
                slug = key
                sub(/\/.*/, "", slug)
                rel = substr(key, length(slug) + 2)
                dir = src
                if (rel != "" && substr(dir, length(dir) - length(rel)) == "/" rel)
                    dir = substr(dir, 1, length(dir) - length(rel) - 1)
                if (!(slug in seen)) { seen[slug] = 1; print slug "\t" dir }
            }
            key = ""; type = ""; src = ""
        }
        /^## / { flush(); key = substr($0, 4); sub(/[[:space:]]+$/, "", key); next }
        /^- source-type:/ { type = $0; sub(/^- source-type:[[:space:]]*/, "", type); sub(/[[:space:]]+$/, "", type) }
        /^- source:/      { src = $0;  sub(/^- source:[[:space:]]*/, "", src);        sub(/[[:space:]]+$/, "", src) }
        END { flush() }
    ' "${MANIFEST}"
}

if [[ "${DIFF}" == true ]]; then
    # Bare --diff after the first import: every imported slug, each against the
    # source its own entries record, so a slug imported with --source or --slug
    # is checked where it came from rather than against STAR_HOME's basename.
    if [[ -z "${OPT_SOURCE}${OPT_SLUG}" ]] && [[ -n "$(manifest_star_sources)" ]]; then
        any_drift=false
        any_unknown=false
        star_lit='$STAR_HOME'
        while IFS=$'\t' read -r m_slug m_dir; do
            [[ -n "${m_slug}" ]] || continue
            if [[ "${m_dir}" == "${star_lit}" || "${m_dir}" == "${star_lit}/"* ]]; then
                if [[ -z "${STAR_HOME:-}" ]]; then
                    printf '  unknown           mates/%s/ (source %s not reachable: STAR_HOME is unset)\n' "${m_slug}" "${m_dir}"
                    any_unknown=true
                    continue
                fi
                m_dir="${STAR_HOME}${m_dir#"${star_lit}"}"
            fi
            if [[ -z "${m_dir}" || ! -d "${m_dir}" ]]; then
                printf '  unknown           mates/%s/ (source %s not reachable)\n' "${m_slug}" "${m_dir:-(none recorded)}"
                any_unknown=true
                continue
            fi
            rc=0
            diff_one "$(cd -- "${m_dir}" && pwd -P)" "${m_slug}" || rc=$?
            if (( rc == 2 )); then any_drift=true; fi
        done < <(manifest_star_sources)
        if [[ "${any_unknown}" == true ]]; then
            log "A slug above has no reachable source: set STAR_HOME, or pass --source PATH --slug NAME for it."
        fi
        if [[ "${any_drift}" == true ]]; then exit 2; fi
        if [[ "${any_unknown}" == true ]]; then exit 1; fi
        exit 0
    fi
    # Before the first import, or with --source / --slug: the one upstream.
    resolve_source
    rc=0
    diff_one "${SOURCE_DIR}" "${SLUG}" || rc=$?
    exit "${rc}"
fi

# ---- import -----------------------------------------------------------------
resolve_source
log "Importing from ${SOURCE_DIR} into mates/${SLUG}/."
collect

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

# A commit pins only committed bytes. An importable file the upstream has not
# committed is recorded against <sha>-dirty, so the entry never claims a commit
# that does not hold what landed.
if [[ "${SOURCE_COMMIT}" != "n/a" ]]; then
    DIRTY="$(upstream_dirty)"
    if [[ -n "${DIRTY}" ]]; then
        SOURCE_COMMIT="${SOURCE_COMMIT}-dirty"
        log "warn: upstream has uncommitted changes in $(printf '%s\n' "${DIRTY}" | wc -l | tr -d ' ') importable file(s); source-commit records ${SOURCE_COMMIT}. Commit them in the STAR repo and re-import to pin the bytes:"
        printf '%s\n' "${DIRTY}" | sed 's/^/      /'
    fi
fi

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
    checksum="$(file_sha256 "${dst}")"
    covers="$(default_covers "${rel}")"

    {
        printf '## %s\n' "${key}"
        printf -- '- source-type: star\n'
        printf -- '- source: %s/%s\n' "${SRC_PREFIX}" "${rel}"
        printf -- '- source-commit: %s\n' "${SOURCE_COMMIT}"
        printf -- '- source-stamp: %s\n' "${stamp}"
        printf -- '- sha256: %s\n' "${checksum}"
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

log "Imported ${imported} file(s) from commit ${SOURCE_COMMIT} into mates/${SLUG}/; mates/MANIFEST.md updated."
log "mates/ is read-only from here: fix numbers upstream and re-import (conventions §9)."
