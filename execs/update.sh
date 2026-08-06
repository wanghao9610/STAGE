#!/usr/bin/env bash
set -euo pipefail

# execs/update.sh — sync STAGE-managed content from the upstream template (the
# four per-harness skill trees, the four session-hook trees, docs/mds/stage-workflow/,
# the shared agent instructions, and every script under execs/ — both entrypoints,
# this one included, and the three utilities in execs/scpts/), or install the
# STAGE skeleton into an existing paper repo with --adopt.

STAGE_REF="main"
SKILL_NAME=""
REF_SET=false
ADOPT=false
DIFF=false
FORCE=false

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# The STAGE-managed trees: overwritten on update, copy-if-absent on adopt.
# One root per harness — same fifteen skills, harness-specific invocation
# prefix and tool names.
SKILL_ROOTS=(
    ".agents/skills"
    ".claude/skills"
    ".cursor/skills"
    ".kimi-code/skills"
)
DOCS_TREE="docs/mds/stage-workflow"

# STAGE-owned session-hook assets: the script that injects the project-memory
# index (.stage/memory/) at the start of a session, and the one that injects the
# runtime's model id so an artifact records who wrote it (conventions §8) — one
# copy of each per harness, because every runtime spells the event and the
# output field differently. Overwritten on update like the skills — the memory
# store itself is the paper's and is never synced.
HOOK_TREES=(
    ".claude/hooks"
    ".codex/hooks"
    ".cursor/hooks"
    ".kimi-code/hooks"
)

# Single STAGE-managed files an update overwrites alongside the trees above.
# execs/run.sh is here because the skills call it by name and by flag — a paper
# repo that syncs a skill using `run.sh --main` while keeping a run.sh that
# predates the flag gets a run that fails at its build step. The three utilities
# under execs/scpts/ are here for the same reason and it is not weaker: sixteen
# skills call `import.sh --diff` and five call `lint.sh --no-build` by name and
# by flag, `lint.sh` calls `fmt.sh --check` the same way, and a caller reading an
# exit code means the one its own version documents. No script here carries
# project configuration: everything an instance sets lives in .env, which is
# git-ignored and never synced (conventions §3.1) — so all five are safe to
# replace wholesale.
#
# execs/update.sh syncs itself, so a repo never strands on an update mechanism
# too old to fetch its successor. A running shell script must not be rewritten
# in place — bash reads it incrementally by offset, so a truncating extract can
# resume parsing into different bytes — so this one file is kept out of the tar
# below and installed by rename instead (SELF_PATH, further down): the running
# process keeps the old inode to the end, the next invocation gets the new file.
SELF_PATH="execs/update.sh"
SYNC_FILES=(
    "execs/run.sh"
    "execs/scpts/import.sh"
    "execs/scpts/lint.sh"
    "execs/scpts/fmt.sh"
    # Kimi has no project-level hook config, so its registration snippet ships
    # as documentation beside the hook rather than as a config an update keeps.
    ".kimi-code/hooks.example.toml"
    "${SELF_PATH}"
)

# Synced paths a ref is allowed not to have. Each arrived later than the tree it
# sits in, so pinning an older ref is a legitimate reason for it to be missing,
# and that is a skipped line rather than a stopped update: the session hooks,
# which arrived after the skills, and fmt.sh, which arrived after the other two
# utilities. Anything else missing is a broken ref and still fatal.
is_optional_path() {
    case "$1" in
        .*/hooks*)            return 0 ;;
        "execs/scpts/fmt.sh") return 0 ;;
    esac
    return 1
}

# The shared agent instructions and the Cursor rule that copies their body:
# upstream-managed like the skills, and overwritten by an update. They are the
# same document twice, and CI enforces the mirror, so they are synced as a pair
# — a project's own conventions belong in a section the update does not own or
# in .env, not in an edited copy of these.
AGENT_DOC="AGENTS.md"
AGENT_RULES_TREE=".cursor/rules"

# Harness configuration a project may have edited: installed when it is missing
# — by --adopt and by an update alike — and never overwritten unless --force
# says so. A flat file list on purpose: an empty array expands to an unbound
# variable under `set -u` on bash 3.2, so a tree joins this only with the
# guarded expansion that needs.
#
# The last three register the session hooks. They are kept rather than
# overwritten because a paper repo may have added its own settings to them — so
# a repo adopted before a hook existed keeps a config that does not
# register it, which HOOK_CONFIGS below turns into a printed line instead of a
# hook that silently never fires.
HARNESS_FILES=(
    ".cursorignore"
    ".claude/settings.json"
    ".codex/hooks.json"
    ".cursor/hooks.json"
)
HOOK_CONFIGS=(
    ".claude/settings.json"
    ".codex/hooks.json"
    ".cursor/hooks.json"
)

log() {
    printf '[STAGE update] %s\n' "$*"
}

fail() {
    printf '[STAGE update] ERROR: %s\n' "$*" >&2
    exit 1
}

# Every harness-configuration file the fetched ref actually carries, one path
# per line. A path the ref does not have is skipped rather than fatal — harness
# configuration is optional to the update, unlike SYNC_PATHS.
harness_rels() {
    local rel
    for rel in "${HARNESS_FILES[@]}"; do
        if [[ -f "${SOURCE_DIR}/${rel}" ]]; then
            printf '%s\n' "${rel}"
        fi
    done
}

# A kept registration config that does not name one of the hooks: the script is
# installed, nothing errors, and either no memory reaches a session or every
# artifact it writes records "unrecorded". Reported, not repaired — merging into
# a file the project may have extended is the user's.
report_unregistered_hooks() {
    local cfg missing hook label
    for cfg in "${HOOK_CONFIGS[@]}"; do
        [[ -e "${ROOT_DIR}/${cfg}" ]] || continue
        missing=""
        for hook in "stage_memory.sh|project-memory" "stage_model_id.sh|model-id provenance"; do
            label="${hook#*|}"
            grep -q "${hook%%|*}" "${ROOT_DIR}/${cfg}" 2>/dev/null || missing+="${missing:+, }${label}"
        done
        if [[ -n "${missing}" ]]; then
            log "NOTE: ${cfg} was kept and registers no STAGE session hook for: ${missing}."
            log "      Merge the hook entries from upstream ${cfg} to enable them."
        elif [[ "${cfg}" == ".codex/hooks.json" ]]; then
            # Registering them is not enough on Codex: a project hook runs only
            # once the project is trusted and the hook itself approved, and a
            # changed hook needs approving again. Nothing reports the gap — the
            # hooks simply do not fire, no memory reaches the session, and every
            # artifact the session writes records "unrecorded".
            log "NOTE: ${cfg} is registered, but Codex runs a project hook only after you approve it."
            log "      Run /hooks in the Codex CLI and approve it — re-approve whenever it changes."
        fi
    done
}

usage() {
    cat <<'EOF'
Usage: bash execs/update.sh [ref] [--skill NAME] [--force]
       bash execs/update.sh --diff [ref] [--skill NAME] [--force]
       bash update.sh --adopt

Overwrite the STAGE-managed content — the shared agent instructions (AGENTS.md
and the Cursor rule that copies its body), the four per-harness skill trees
(.claude/skills/, .agents/skills/, .cursor/skills/, .kimi-code/skills/), the
four session-hook trees that inject the project-memory index and the session's
model id, docs/mds/stage-workflow/, and every script under execs/ — the two
entrypoints, run.sh and this one, and the three utilities in execs/scpts/:
import.sh, lint.sh, fmt.sh — with files from upstream.
The default ref is main; a branch or tag may be supplied instead. Local edits to
those paths are replaced, AGENTS.md included; the manuscript, evidence, notes,
and the memory store under .stage/memory/ are never touched. Use --skill to
update only the named skill across all four skill trees (it leaves everything
else, entrypoints and docs included, alone).

No script under execs/ holds project configuration — everything an instance sets
lives in .env, which is git-ignored and never synced — so all five are safe to
replace. They are synced because they are called by name and by
flag: run.sh --main, lint.sh --no-build and import.sh --diff from the skills,
fmt.sh --check from lint.sh. A repo that syncs a skill while keeping a script
that predates the flag it passes gets a run that fails at that step. execs/update.sh syncs itself, so no repo strands on an
update mechanism too old to fetch its successor: it is installed by rename,
which leaves this running process on the old file and gives the next invocation
the new one.

Harness configuration an instance may have edited — .cursorignore and the three
hook registrations (.claude/settings.json, .codex/hooks.json, .cursor/hooks.json)
— is installed when it is absent and otherwise kept, however far it has drifted
from upstream; only --force overwrites it. A kept registration that does not name
a session hook is reported, since a hook nobody registers never fires.

--diff previews an update without changing anything: it lists upstream files
that are new or differ from the local copies, harness configuration that
differs but would be kept, and project-local files an update would keep. It
exits 0 when everything already matches, 2 when an update would change files,
and 1 on error — so a script can tell "an update is available" from "the check
itself failed".

--force updates the same paths with both refusals lifted: uncommitted changes
under them are overwritten instead of stopping the command, and the harness
configuration above is overwritten instead of kept. It widens nothing — the
path list is unchanged, and a file upstream does not have is still left alone.
Combined with --diff it previews that scope without changing anything.

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
  bash execs/update.sh --force
  bash execs/update.sh --skill stage-sect-drafter
  bash execs/update.sh TAG_OR_BRANCH --skill stage-sect-drafter

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
        --force)
            FORCE=true
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
    # Adopt's whole contract is that it never touches an existing file, which is
    # the opposite of what --force asks for.
    [[ "${FORCE}" == false ]] || fail "--adopt cannot be combined with --force."

    ROOT_DIR="$(pwd -P)"
    git -C "${ROOT_DIR}" rev-parse --git-dir >/dev/null 2>&1 || \
        fail "--adopt must run inside a git repository. Run 'git init' first."
    [[ -e "${ROOT_DIR}/.git" ]] || \
        fail "--adopt must run at the repository root, not in a subdirectory."

    # Directories merged file by file, and single files, all copy-if-absent.
    ADOPT_TREES=(
        "${SKILL_ROOTS[@]}"
        "${HOOK_TREES[@]}"
        "${AGENT_RULES_TREE}"
        "${DOCS_TREE}"
    )
    ADOPT_FILES=(
        "${AGENT_DOC}"
        "${HARNESS_FILES[@]}"
        ".kimi-code/hooks.example.toml"
        # The memory store's index. The store is the paper's own from here on;
        # only this seed file, which documents the line format, comes from
        # upstream.
        ".stage/memory/MEMORY.md"
        ".env.example"
        ".gitignore"
        # The line-break rule fmt.sh applies and .vscode/settings.json points
        # at, plus the editor-side half of the same convention; a paper that
        # already has either keeps its own, like every file here.
        ".latexindent.yaml"
        ".editorconfig"
        "execs/run.sh"
        "execs/update.sh"
        "execs/scpts/import.sh"
        "execs/scpts/lint.sh"
        "execs/scpts/fmt.sh"
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
    SPARSE_PATHS=("${SYNC_PATHS[@]}")

    if [[ "${DIFF}" == true ]]; then
        log "Diffing skill: ${SKILL_NAME}"
    else
        log "Updating skill: ${SKILL_NAME}"
    fi
else
    # SYNC_PATHS is what gets diffed, dirty-checked, archived, and extracted —
    # directories and single files alike. SPARSE_PATHS is what the sparse
    # checkout materializes, and it holds directories only: `sparse-checkout
    # set` is cone-mode by default, where every argument is read as a directory,
    # so naming a file there would match nothing. A file's parent directory goes
    # in instead; fetching a few siblings we do not copy is cheaper than getting
    # this subtly wrong.
    SYNC_PATHS=(
        "${AGENT_DOC}"
        "${AGENT_RULES_TREE}"
        "${SKILL_ROOTS[@]}"
        "${HOOK_TREES[@]}"
        "${DOCS_TREE}"
        "${SYNC_FILES[@]}"
    )
    SPARSE_PATHS=(
        "${AGENT_RULES_TREE}"
        "${SKILL_ROOTS[@]}"
        "${HOOK_TREES[@]}"
        "${DOCS_TREE}"
    )
    # Parent directories of every synced or kept single file. The harness
    # configs are named explicitly rather than left to cone mode's ancestor
    # rule: harness_rels() checks them in the fetched tree, and a config the
    # checkout never materialized would read as "upstream does not have it".
    for f in "${SYNC_FILES[@]}" "${HARNESS_FILES[@]}"; do
        d="$(dirname -- "${f}")"
        [[ "${d}" == "." ]] || SPARSE_PATHS+=("${d}")
    done
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
# SELF_TMP holds the incoming copy of this script between `cp` and the `mv`
# that puts it in place; a run that dies in that window leaves no debris.
SELF_TMP=""
cleanup() {
    rm -rf -- "${TEMP_DIR}"
    [[ -z "${SELF_TMP}" ]] || rm -f -- "${SELF_TMP}"
}
trap cleanup EXIT

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
    # SPARSE_PATHS is directories only (see above); the existence check below
    # then runs over SYNC_PATHS, which is the exact list the tar copies — so a
    # file that the sparse checkout failed to materialize stops the run here
    # instead of being silently skipped.
    git -C "${SOURCE_DIR}" sparse-checkout set "${SPARSE_PATHS[@]}"

    # SYNCED is SYNC_PATHS minus what the fetched ref does not carry, and it is
    # what everything below diffs, dirty-checks, and extracts. What may be
    # absent is is_optional_path()'s list and nothing else; anything else
    # missing is a broken ref and still fatal.
    SYNCED=()
    for path in "${SYNC_PATHS[@]}"; do
        if [[ -e "${SOURCE_DIR}/${path}" ]]; then
            SYNCED+=("${path}")
        elif is_optional_path "${path}"; then
            log "Skipping ${path}: not present in ref '${STAGE_REF}'."
        else
            fail "Upstream ref is missing ${path}."
        fi
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
        done < <(cd "${SOURCE_DIR}" && find "${SYNCED[@]}" -type f | sort)

        # Project-local files under the same paths; an update keeps them.
        while IFS= read -r rel; do
            if [[ ! -e "${SOURCE_DIR}/${rel}" ]]; then
                printf '  extra    %s (not in upstream ref; update keeps it)\n' "${rel}"
                kept=$(( kept + 1 ))
            fi
        done < <(cd "${ROOT_DIR}" && find "${SYNCED[@]}" -type f 2>/dev/null | sort)

        # Harness configuration: installed when missing, kept when it differs —
        # unless --force, which puts it back in the overwrite set. A skill-only
        # update never reaches it at all.
        if [[ -z "${SKILL_NAME}" ]]; then
            while IFS= read -r rel; do
                if [[ ! -e "${ROOT_DIR}/${rel}" && ! -L "${ROOT_DIR}/${rel}" ]]; then
                    printf '  new      %s (harness config)\n' "${rel}"
                    added=$(( added + 1 ))
                elif ! cmp -s "${SOURCE_DIR}/${rel}" "${ROOT_DIR}/${rel}"; then
                    if [[ "${FORCE}" == true ]]; then
                        printf '  differs  %s (harness config; --force overwrites it)\n' "${rel}"
                        changed=$(( changed + 1 ))
                    else
                        printf '  config   %s (differs from upstream; update never overwrites it)\n' "${rel}"
                    fi
                fi
            done < <(harness_rels)
        fi

        if (( changed + added > 0 )); then
            hint="bash execs/update.sh"
            [[ "${REF_SET}" == false ]] || hint="${hint} ${STAGE_REF}"
            [[ -z "${SKILL_NAME}" ]] || hint="${hint} --skill ${SKILL_NAME}"
            [[ "${FORCE}" == false ]] || hint="${hint} --force"
            log "${changed} differ, ${added} new upstream, ${kept} extra local."
            log "'differs' is direction-blind: it includes files you edited yourself."
            log "Run '${hint}' to apply the upstream versions."
            # 2, not 1: fail() uses 1 for every hard error, so a caller could not
            # distinguish "an update is available" from "the check itself broke".
            exit 2
        fi
        log "Everything STAGE manages matches upstream ref '${STAGE_REF}'. Nothing to update."
        exit 0
    fi

    # The extract below overwrites in place and cannot be rolled back. Git is
    # the only safety net, so refuse to run when it would not hold:
    # uncommitted edits under a synced path would be destroyed with no copy
    # anywhere.
    if git -C "${ROOT_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
        # --force also overwrites the harness configuration, so it belongs in
        # what gets reported as about to be lost.
        DIRTY_PATHS=("${SYNCED[@]}")
        if [[ "${FORCE}" == true && -z "${SKILL_NAME}" ]]; then
            DIRTY_PATHS+=("${HARNESS_FILES[@]}")
        fi
        DIRTY="$(git -C "${ROOT_DIR}" status --porcelain -- "${DIRTY_PATHS[@]}" 2>/dev/null || true)"
        if [[ -n "${DIRTY}" ]]; then
            printf '%s\n' "${DIRTY}" | sed 's/^/      /' >&2
            if [[ "${FORCE}" == true ]]; then
                log "--force: the uncommitted changes above are being overwritten with no way back."
            else
                fail "The paths above have uncommitted changes and would be overwritten with no way back. Commit or stash them first, or preview with 'bash execs/update.sh --diff'."
            fi
        fi
    else
        log "NOTE: not a git repository, so an update cannot be undone. Back up the STAGE-managed trees first if you have local edits."
    fi

    # Everything but this script goes through the tar, which extracts in place.
    # This script is the one file that must not be written in place while it is
    # running, so it is filtered out here and renamed into position below.
    TAR_PATHS=()
    for path in "${SYNCED[@]}"; do
        [[ "${path}" == "${SELF_PATH}" ]] || TAR_PATHS+=("${path}")
    done

    tar -C "${SOURCE_DIR}" -cf "${ARCHIVE_FILE}" "${TAR_PATHS[@]}"
    tar -C "${ROOT_DIR}" -xf "${ARCHIVE_FILE}"

    # Self-update by rename. `mv` within the same directory is rename(2): the
    # directory entry swings to the new file while the running bash keeps the
    # old inode open and reads it to the end. `cp` over the target would
    # truncate and rewrite the bytes this process is still parsing.
    if [[ -z "${SKILL_NAME}" ]] && [[ -f "${SOURCE_DIR}/${SELF_PATH}" ]] && \
       ! cmp -s "${SOURCE_DIR}/${SELF_PATH}" "${ROOT_DIR}/${SELF_PATH}"; then
        SELF_TMP="${ROOT_DIR}/${SELF_PATH}.incoming.$$"
        cp -p "${SOURCE_DIR}/${SELF_PATH}" "${SELF_TMP}"
        mv -f "${SELF_TMP}" "${ROOT_DIR}/${SELF_PATH}"
        SELF_TMP=""
        log "Replaced ${SELF_PATH} with upstream's copy."
        log "      This run finishes on the old code; the next invocation uses the new one."
    fi

    if [[ -z "${SKILL_NAME}" ]]; then
        harness_kept=0
        while IFS= read -r rel; do
            if [[ ! -e "${ROOT_DIR}/${rel}" && ! -L "${ROOT_DIR}/${rel}" ]]; then
                mkdir -p "$(dirname -- "${ROOT_DIR}/${rel}")"
                cp -p "${SOURCE_DIR}/${rel}" "${ROOT_DIR}/${rel}"
                log "Installed ${rel} (harness config, was missing)"
            elif cmp -s "${SOURCE_DIR}/${rel}" "${ROOT_DIR}/${rel}"; then
                continue
            elif [[ "${FORCE}" == true ]]; then
                cp -p "${SOURCE_DIR}/${rel}" "${ROOT_DIR}/${rel}"
                log "Overwrote ${rel} (harness config; --force), including any edits you made to it."
            else
                harness_kept=$(( harness_kept + 1 ))
            fi
        done < <(harness_rels)

        if (( harness_kept > 0 )); then
            log "NOTE: ${harness_kept} harness config file(s) differ from upstream and were kept."
            log "      See which with 'bash execs/update.sh --diff'; take upstream's with --force."
        fi
        report_unregistered_hooks
    fi

    log "Updated: ${SYNCED[*]}"
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
    log "      Adopt keeps it, but a later 'bash execs/update.sh' overwrites it."
fi
if [[ -e "${ROOT_DIR}/.gitignore" ]]; then
    # Checked per path, and tolerant of the glob forms a rule may take. One
    # combined grep would let a .gitignore naming only wkdrs/ silence the
    # warning about the machine-local memory store too.
    unignored=()
    for tree in "wkdrs" "\.stage/memory/local"; do
        grep -qE "^/?${tree}(/|/\*|/\*\*)?$" "${ROOT_DIR}/.gitignore" 2>/dev/null || \
            unignored+=("${tree//\\/}/")
    done
    if (( ${#unignored[@]} > 0 )); then
        log "NOTE: your .gitignore was kept and does not ignore ${unignored[*]}."
        log "      Add them before committing, or builds, reports, or one machine's own notes enter history."
    fi
fi
report_unregistered_hooks

log "Next: copy .env.example to .env, then run /stage-proj-adopt to wire the paper up."
log "      Kimi Code only: 'bash .kimi-code/hooks/install.sh' registers both session hooks once per machine."
