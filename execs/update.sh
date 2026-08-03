#!/usr/bin/env bash
set -euo pipefail

# execs/update.sh — sync STAGE-managed content from the upstream template
# (.claude/skills/, .agents/skills/, docs/mds/stage-workflow/), or install the
# STAGE skeleton into an existing paper repo with --adopt.

STAGE_REF="main"
SKILL_NAME=""
REF_SET=false
ADOPT=false
DIFF=false

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# The STAGE-managed trees: overwritten on update, copy-if-absent on adopt.
SKILL_ROOTS=(
    ".agents/skills"
    ".claude/skills"
)
DOCS_TREE="docs/mds/stage-workflow"

log() {
    printf '[STAGE update] %s\n' "$*"
}

fail() {
    printf '[STAGE update] ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: bash execs/update.sh [ref] [--skill NAME]
       bash execs/update.sh --diff [ref] [--skill NAME]
       bash update.sh --adopt

Overwrite the STAGE-managed trees — .claude/skills/, .agents/skills/, and
docs/mds/stage-workflow/ — with files from upstream. The default ref is main;
a branch or tag may be supplied instead. Local edits under those trees are
replaced; the manuscript, evidence, and notes are never touched. Use --skill
to update only the named skill in both skill trees.

--diff previews an update without changing anything: it lists upstream files
that are new or differ from the local copies, plus project-local files an
update would keep. It exits 0 when everything already matches and 1 when an
update would change files.

--adopt installs the STAGE skeleton into an already-started paper repo instead
of updating this one. It runs against the current working directory, which
must be a git repository root, and never overwrites a file that is already
there: every existing path is kept and reported. Run /stage-proj-adopt
afterwards to wire the paper up.

The upstream repository is STAGE_REPOSITORY (environment first, then .env);
default https://github.com/wanghao9610/STAGE.git.

Examples:
  bash execs/update.sh
  bash execs/update.sh TAG_OR_BRANCH
  bash execs/update.sh --diff
  bash execs/update.sh --skill stage-sect-drafter

  cd /path/to/my-paper
  curl -fsSL https://raw.githubusercontent.com/wanghao9610/STAGE/main/execs/update.sh -o /tmp/stage-update.sh
  bash /tmp/stage-update.sh --adopt
EOF
}

while (( $# > 0 )); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --skill)
            shift
            (( $# > 0 )) || fail "--skill requires a skill name."
            [[ -z "${SKILL_NAME}" ]] || fail "--skill may only be specified once."
            SKILL_NAME="$1"
            ;;
        --skill=*)
            [[ -z "${SKILL_NAME}" ]] || fail "--skill may only be specified once."
            SKILL_NAME="${1#*=}"
            [[ -n "${SKILL_NAME}" ]] || fail "--skill requires a skill name."
            ;;
        --adopt)
            ADOPT=true
            ;;
        --diff)
            DIFF=true
            ;;
        -*)
            fail "Unknown option: $1"
            ;;
        *)
            [[ "${REF_SET}" == false ]] || fail "Only one ref may be supplied."
            STAGE_REF="$1"
            REF_SET=true
            ;;
    esac
    shift
done

if [[ "${ADOPT}" == true ]]; then
    [[ -z "${SKILL_NAME}" ]] || fail "--adopt cannot be combined with --skill."
    [[ "${DIFF}" == false ]] || fail "--adopt cannot be combined with --diff."

    ROOT_DIR="$(pwd -P)"
    git -C "${ROOT_DIR}" rev-parse --git-dir >/dev/null 2>&1 || \
        fail "--adopt must run inside a git repository. Run 'git init' first."
    [[ -e "${ROOT_DIR}/.git" ]] || \
        fail "--adopt must run at the repository root, not in a subdirectory."

    # Directories merged file by file, and single files, all copy-if-absent.
    ADOPT_TREES=(
        "${SKILL_ROOTS[@]}"
        "${DOCS_TREE}"
    )
    ADOPT_FILES=(
        "AGENTS.md"
        ".env.example"
        ".gitignore"
        "execs/run.sh"
        "execs/update.sh"
        "execs/scpts/import.sh"
        "execs/scpts/lint.sh"
        "manus/main.tex"
        "manus/stys/stage.sty"
        "mates/MANIFEST.md"
    )
    # Layout directories the writing workflow expects to exist.
    ADOPT_DIRS=(
        "manus/secs"
        "manus/figs/srcs"
        "manus/tabs"
        "manus/bibs"
        "manus/stys"
        "mates/manual"
        "notes/refs"
        "cycls"
        "tasks"
        "wkdrs"
        "execs/scpts"
    )
elif [[ -n "${SKILL_NAME}" ]]; then
    [[ "${SKILL_NAME}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || \
        fail "Invalid skill name '${SKILL_NAME}'."

    SYNC_PATHS=()
    for root in "${SKILL_ROOTS[@]}"; do
        SYNC_PATHS+=("${root}/${SKILL_NAME}")
    done

    if [[ "${DIFF}" == true ]]; then
        log "Diffing skill: ${SKILL_NAME}"
    else
        log "Updating skill: ${SKILL_NAME}"
    fi
else
    SYNC_PATHS=(
        "${SKILL_ROOTS[@]}"
        "${DOCS_TREE}"
    )
fi

# Without --adopt this script rewrites the project it lives in, derived from
# its own location. A copy run from somewhere else would target that other
# tree.
if [[ "${ADOPT}" == false ]]; then
    [[ -f "${ROOT_DIR}/execs/run.sh" ]] || \
        fail "${ROOT_DIR} is not a STAGE project (no execs/run.sh). This script updates the project it lives in: copy it to <paper>/execs/update.sh and run it there, or pass --adopt to install STAGE into the current directory."
fi

# Upstream resolution: environment wins, then .env, then the public default.
if [[ -z "${STAGE_REPOSITORY:-}" && -f "${ROOT_DIR}/.env" ]]; then
    STAGE_REPOSITORY="$(sed -n 's/^STAGE_REPOSITORY=//p' "${ROOT_DIR}/.env" | tail -1)"
fi
STAGE_REPOSITORY="${STAGE_REPOSITORY:-https://github.com/wanghao9610/STAGE.git}"

command -v git >/dev/null 2>&1 || fail "git is required."
command -v tar >/dev/null 2>&1 || fail "tar is required."

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TEMP_DIR}"' EXIT

SOURCE_DIR="${TEMP_DIR}/repository"
ARCHIVE_FILE="${TEMP_DIR}/stage-content.tar"

log "Fetching ${STAGE_REF} from ${STAGE_REPOSITORY}"

CLONE_ARGS=(--quiet --depth 1 --branch "${STAGE_REF}" --single-branch)
if [[ "${ADOPT}" == false ]]; then
    CLONE_ARGS+=(--filter=blob:none --sparse)
fi

git clone \
    "${CLONE_ARGS[@]}" \
    "${STAGE_REPOSITORY}" \
    "${SOURCE_DIR}" || fail "Unable to fetch ref '${STAGE_REF}' from ${STAGE_REPOSITORY}. Check the ref exists (a branch or tag, not a commit SHA), that the network is reachable, and that git is 2.25 or newer — currently $(git --version 2>/dev/null || echo 'unknown')."

if [[ "${ADOPT}" == false ]]; then
    if [[ -n "${SKILL_NAME}" ]]; then
        git -C "${SOURCE_DIR}" sparse-checkout set "${SYNC_PATHS[@]}"
    else
        # Directory arguments keep sparse-checkout correct in both cone and
        # non-cone mode; the tar below still copies only SYNC_PATHS.
        git -C "${SOURCE_DIR}" sparse-checkout set \
            .agents/skills .claude/skills docs/mds/stage-workflow
    fi

    for path in "${SYNC_PATHS[@]}"; do
        [[ -e "${SOURCE_DIR}/${path}" ]] || fail "Upstream ref is missing ${path}."
    done

    if [[ "${DIFF}" == true ]]; then
        changed=0
        added=0
        kept=0

        # Upstream files that an update would overwrite or add.
        while IFS= read -r rel; do
            if [[ ! -e "${ROOT_DIR}/${rel}" && ! -L "${ROOT_DIR}/${rel}" ]]; then
                printf '  new      %s\n' "${rel}"
                added=$(( added + 1 ))
            elif ! cmp -s "${SOURCE_DIR}/${rel}" "${ROOT_DIR}/${rel}"; then
                printf '  differs  %s\n' "${rel}"
                changed=$(( changed + 1 ))
            fi
        done < <(cd "${SOURCE_DIR}" && find "${SYNC_PATHS[@]}" -type f | sort)

        # Project-local files under the same paths; an update keeps them.
        while IFS= read -r rel; do
            if [[ ! -e "${SOURCE_DIR}/${rel}" ]]; then
                printf '  extra    %s (not in upstream ref; update keeps it)\n' "${rel}"
                kept=$(( kept + 1 ))
            fi
        done < <(cd "${ROOT_DIR}" && find "${SYNC_PATHS[@]}" -type f 2>/dev/null | sort)

        if (( changed + added > 0 )); then
            hint="bash execs/update.sh"
            [[ "${REF_SET}" == false ]] || hint="${hint} ${STAGE_REF}"
            [[ -z "${SKILL_NAME}" ]] || hint="${hint} --skill ${SKILL_NAME}"
            log "${changed} differ, ${added} new upstream, ${kept} extra local."
            log "'differs' is direction-blind: it includes files you edited yourself."
            log "Run '${hint}' to apply the upstream versions."
            exit 1
        fi
        log "Everything STAGE manages matches upstream ref '${STAGE_REF}'. Nothing to update."
        exit 0
    fi

    # The extract below overwrites in place and cannot be rolled back. Git is
    # the only safety net, so refuse to run when it would not hold:
    # uncommitted edits under a synced path would be destroyed with no copy
    # anywhere.
    if git -C "${ROOT_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
        DIRTY="$(git -C "${ROOT_DIR}" status --porcelain -- "${SYNC_PATHS[@]}" 2>/dev/null || true)"
        if [[ -n "${DIRTY}" ]]; then
            printf '%s\n' "${DIRTY}" | sed 's/^/      /' >&2
            fail "The paths above have uncommitted changes and would be overwritten with no way back. Commit or stash them first, or preview with 'bash execs/update.sh --diff'."
        fi
    else
        log "NOTE: not a git repository, so an update cannot be undone. Back up the STAGE-managed trees first if you have local edits."
    fi

    tar -C "${SOURCE_DIR}" -cf "${ARCHIVE_FILE}" "${SYNC_PATHS[@]}"
    tar -C "${ROOT_DIR}" -xf "${ARCHIVE_FILE}"

    log "Updated: ${SYNC_PATHS[*]}"
    log "Review the changes with git status and git diff before committing them."
    exit 0
fi

# --adopt: install into an existing paper repo, never overwriting anything.
installed=0
skipped=0

install_file() {
    local rel="$1"
    local src="${SOURCE_DIR}/${rel}"
    local dst="${ROOT_DIR}/${rel}"

    [[ -e "${src}" ]] || return 0
    if [[ -e "${dst}" || -L "${dst}" ]]; then
        printf '  kept    %s (already present)\n' "${rel}"
        skipped=$(( skipped + 1 ))
        return 0
    fi
    mkdir -p "$(dirname -- "${dst}")"
    cp -p "${src}" "${dst}"
    printf '  added   %s\n' "${rel}"
    installed=$(( installed + 1 ))
}

for tree in "${ADOPT_TREES[@]}"; do
    [[ -d "${SOURCE_DIR}/${tree}" ]] || fail "Upstream ref is missing ${tree}."
    while IFS= read -r rel; do
        install_file "${rel}"
    done < <(cd "${SOURCE_DIR}" && find "${tree}" -type f | sort)
done

for file in "${ADOPT_FILES[@]}"; do
    install_file "${file}"
done

for dir in "${ADOPT_DIRS[@]}"; do
    if [[ -e "${ROOT_DIR}/${dir}" || -L "${ROOT_DIR}/${dir}" ]]; then
        printf '  kept    %s/ (already present)\n' "${dir}"
        skipped=$(( skipped + 1 ))
    else
        mkdir -p "${ROOT_DIR}/${dir}"
        printf '  added   %s/\n' "${dir}"
        installed=$(( installed + 1 ))
    fi
done

if [[ -e "${ROOT_DIR}/CLAUDE.md" || -L "${ROOT_DIR}/CLAUDE.md" ]]; then
    printf '  kept    CLAUDE.md (already present)\n'
    skipped=$(( skipped + 1 ))
elif [[ -e "${ROOT_DIR}/AGENTS.md" ]]; then
    ln -s AGENTS.md "${ROOT_DIR}/CLAUDE.md"
    printf '  added   CLAUDE.md -> AGENTS.md\n'
    installed=$(( installed + 1 ))
fi

log "Adopted into ${ROOT_DIR}: ${installed} added, ${skipped} left alone."
if (( skipped > 0 )); then
    log "Nothing that was already there was modified. Review the kept lines above."
fi

# Two kept files have consequences worth naming instead of leaving to
# discovery.
if [[ -e "${ROOT_DIR}/AGENTS.md" ]] && \
   ! cmp -s "${SOURCE_DIR}/AGENTS.md" "${ROOT_DIR}/AGENTS.md"; then
    log "NOTE: your AGENTS.md was kept, so STAGE's writing conventions are not in it."
    log "      Compare against ${STAGE_REPOSITORY} AGENTS.md and merge what you want."
fi
if [[ -e "${ROOT_DIR}/.gitignore" ]] && \
   ! grep -qE '^/?wkdrs(/|/\*|/\*\*)?$' "${ROOT_DIR}/.gitignore" 2>/dev/null; then
    log "NOTE: your .gitignore was kept and does not ignore wkdrs/."
    log "      Add it before committing, or builds and reports will enter history."
fi

log "Next: copy .env.example to .env, then run /stage-proj-adopt to wire the paper up."
