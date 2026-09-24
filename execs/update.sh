#!/usr/bin/env bash
set -euo pipefail

# execs/update.sh — sync STAGE-managed content from the upstream template (the
# seven skill trees, the Codex $stage / $stage-auto plugin, the Kimi and DSH
# /stage and /stage-auto entries, their hook and capability trees,
# docs/mds/stage-workflow/, the shared agent instructions, and
# every script under execs/
# — both entrypoints, this one included, and the three utilities in execs/scpts/),
# or install the STAGE skeleton into an existing paper repo with --adopt.

STAGE_REF="main"
SKILL_NAME=""
REF_SET=false
ADOPT=false
DIFF=false
FORCE=false
HARNESSES_ARG=""

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# The STAGE-managed trees: overwritten on update, copy-if-absent on adopt.
# One shared root plus six named harness trees — the same sixteen skills with
# harness-specific frontmatter, invocation prefix, and tool names where needed.
SKILL_ROOTS=(
    ".agents/skills"
    ".claude/skills"
    ".cursor/skills"
    ".dsh/skills"
    ".kimi-code/skills"
    ".pi/skills"
    ".qwen/skills"
)
CODEX_MANIFEST_ROOT=".codex/skills"
DOCS_TREE="docs/mds/stage-workflow"

# STAGE-owned hook assets. Two inject at the start of a session: the script that
# puts the project-memory index (.stage/memory/) in front of the agent, and the
# one that states the runtime's model id so an artifact records who wrote it
# (conventions §8). Three decide instead: the commit guard that declines the git
# commands conventions §1 forbids, in every tree; the involve gate that answers
# a file-edit permission prompt at involve=low (§7.7), in the three trees whose
# harness lets a hook decide one; and, in Claude's tree alone, the bash gate
# that answers a shell-command prompt at involve=low outside the red lines. One
# copy of each per harness that carries it, because every runtime spells the
# event and the output field differently. Overwritten on update like the
# skills — the memory store itself is the paper's and is never synced.
HOOK_TREES=(
    ".claude/hooks"
    ".codex/hooks"
    ".cursor/hooks"
    ".dsh/hooks"
    ".kimi-code/hooks"
    ".pi/extensions/stage-hooks"
    ".qwen/hooks"
)

# Pi supplies the capabilities its core does not ship. The neutral request
# router and the /stage-auto goal-run procedure live once under
# .agents/commands; four harnesses expose thin native file entry points,
# while Kimi and DSH own package-based adapters. These are STAGE-owned and
# overwritten on update like the skills.
EXTENSION_TREES=(
    ".pi/agents"
    ".pi/extensions/stage-plan-mode"
    ".pi/extensions/stage-subagent"
)
EXTENSION_FILES=(
    ".pi/extensions/stage-permission-gate.ts"
    ".pi/extensions/stage-questionnaire.ts"
)
COMMAND_TREES=(
    ".agents/commands"
    ".claude/commands"
    ".cursor/commands"
    ".pi/prompts"
    ".qwen/commands"
)
HOOK_FILES=(
    ".dsh/hooks.json"
    ".dsh/cordis.patch.yml"
    ".kimi-code/hooks.example.toml"
)

# Single STAGE-managed files an update overwrites alongside the trees above.
# execs/run.sh is here because the skills call it by name and by flag — a paper
# repo that syncs a skill using `run.sh --main` while keeping a run.sh that
# predates the flag gets a run that fails at its build step. The three utilities
# under execs/scpts/ are here for the same reason and it is not weaker: the
# skills call `import.sh --diff` and `lint.sh --no-build` by name and by flag,
# `lint.sh` calls `fmt.sh --check` the same way, and a caller reading an exit
# code means the one its own version documents. No script here carries
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
    ".pi/APPEND_SYSTEM.md"
    "${SELF_PATH}"
)

# Synced paths a ref is allowed not to have. Each arrived later than the tree it
# sits in, so pinning an older ref is a legitimate reason for it to be missing,
# and that is a skipped line rather than a stopped update: the session hooks,
# which arrived after the skills; fmt.sh, which arrived after the other two
# utilities; and the Kimi and DSH /stage router entries, which arrived after
# their harness trees. Anything else missing is a broken ref and still fatal.
is_optional_path() {
    case "$1" in
        .*/hooks*)            return 0 ;;
        "execs/scpts/fmt.sh") return 0 ;;
        ".dsh/commands")      return 0 ;;
        ".kimi-code/plugins") return 0 ;;
    esac
    return 1
}

# The shared agent instructions are updated for every selection. Cursor's rules
# are updated only when Cursor is selected; then their mirrored body moves with
# AGENTS.md, and CI enforces the two copies. Project-specific conventions belong
# in a section the update does not own or in .env, not in an edited copy here.
# AGENTS.zh-CN.md and its CLAUDE.zh-CN.md pointer are not synced: an update
# neither refreshes nor deletes a copy the project already has.
AGENT_DOCS=("AGENTS.md")
AGENT_RULES_TREE=".cursor/rules"

# Harness configuration a project may have edited: installed when it is missing
# — by --adopt and by an update alike — and never overwritten unless --force
# says so. A flat file list on purpose: an empty array expands to an unbound
# variable under `set -u` on bash 3.2, so a tree joins this only with the
# guarded expansion that needs.
#
# The last three register the hooks. They are kept rather than overwritten
# because a paper repo may have added its own settings to them — so a repo
# adopted before a hook existed keeps a config that does not register it, which
# HOOK_CONFIGS below turns into a printed line instead of a hook that silently
# never fires.
HARNESS_FILES=(
    ".cursorignore"
    ".claude/settings.json"
    ".codex/hooks.json"
    ".cursor/hooks.json"
    ".pi/settings.json"
    ".qwen/settings.json"
)
HOOK_CONFIGS=(
    ".claude/settings.json"
    ".codex/hooks.json"
    ".cursor/hooks.json"
    ".qwen/settings.json"
)

# The named harness trees selectable through --harnesses and STAGE_HARNESSES.
# Which paths belong to each harness is decided by path_harness(), so a new path
# under one of these roots is classified without being added to another list.
ALL_HARNESSES=(claude codex cursor dsh kimi pi qwen)

log() {
    printf '[STAGE update] %s\n' "$*"
}

fail() {
    printf '[STAGE update] ERROR: %s\n' "$*" >&2
    exit 1
}

# Keep Codex's repo marketplace at the path its host discovers while leaving
# the canonical file under .codex. Filesystems that cannot create symlinks get
# a real copy so the plugin remains usable.
link_codex_marketplace() {
    local dst="${ROOT_DIR}/.agents/plugins/marketplace.json"
    local src="${ROOT_DIR}/.codex/plugins/marketplace.json"

    [[ -f "${src}" ]] || fail "Missing Codex marketplace: .codex/plugins/marketplace.json."
    mkdir -p "$(dirname -- "${dst}")"
    if [[ -L "${dst}" ]] && [[ "$(readlink "${dst}")" == "../../.codex/plugins/marketplace.json" ]]; then
        return 0
    fi
    if [[ -e "${dst}" || -L "${dst}" ]]; then
        rm -f -- "${dst}"
    fi
    if ! ln -s "../../.codex/plugins/marketplace.json" "${dst}" 2>/dev/null; then
        cp -p "${src}" "${dst}"
        log "NOTE: symlinks are unavailable; installed .agents/plugins/marketplace.json as a real file."
    fi
}

# Which harness owns a path, or empty when the path belongs to the shared
# skeleton and every run covers it. .agents is shared on purpose, except for
# Codex's single marketplace discovery file: AGENTS.md convention readers use
# the rest directly, while .codex holds Codex-only hooks, per-skill manifests,
# and plugins. .cursorignore is Cursor's one path outside .cursor/.
path_harness() { # $1 = path relative to the project root
    case "$1" in
        .agents/plugins/marketplace.json|.codex/*) printf 'codex' ;;
        .agents/*)               printf '' ;;
        .claude/*)               printf 'claude' ;;
        .cursor/*|.cursorignore) printf 'cursor' ;;
        .dsh/*)                  printf 'dsh' ;;
        .kimi-code/*)            printf 'kimi' ;;
        .pi/*)                   printf 'pi' ;;
        .qwen/*)                 printf 'qwen' ;;
    esac
}

# Top-level directories a selected harness needs in the sparse checkout.
harness_dirs() { # $1 = harness name
    case "$1" in
        codex)  printf '.codex' ;;
        claude) printf '.claude' ;;
        cursor) printf '.cursor' ;;
        dsh)    printf '.dsh' ;;
        kimi)   printf '.kimi-code' ;;
        pi)     printf '.pi' ;;
        qwen)   printf '.qwen' ;;
    esac
}

is_selected() { # $1 = harness name
    local name
    for name in ${SELECTED_HARNESSES[@]+"${SELECTED_HARNESSES[@]}"}; do
        [[ "${name}" == "$1" ]] && return 0
    done
    return 1
}

# True for a shared path or a path owned by a selected harness.
path_selected() { # $1 = path relative to the project root
    local harness
    harness="$(path_harness "$1")"
    [[ -n "${harness}" ]] || return 0
    is_selected "${harness}"
}

# Drop paths outside this run's harness selection; result is FILTERED.
FILTERED=()
filter_paths() { # $@ = paths relative to the project root
    local path
    FILTERED=()
    for path in "$@"; do
        if path_selected "${path}"; then
            FILTERED+=("${path}")
        fi
    done
}

# Every harness-configuration file the fetched ref actually carries, one path
# per line. A path the ref does not have is skipped rather than fatal — harness
# configuration is optional to the update, unlike SYNC_PATHS.
harness_rels() {
    local rel
    for rel in "${HARNESS_FILES[@]}"; do
        path_selected "${rel}" || continue
        if [[ -f "${SOURCE_DIR}/${rel}" ]]; then
            printf '%s\n' "${rel}"
        fi
    done
}

# A kept .claude/settings.json can register every hook and still lack the allow
# rule for the command the provenance hook hands a delegate. A delegate cannot
# answer a permission prompt, so that command is denied and the delegate records
# "unrecorded". A missing permission is not a missing hook, so it gets a note of
# its own rather than a name in report_unregistered_hooks' list.
note_resolver_rule() { # $1 = config path relative to the project root
    [[ "$1" == ".claude/settings.json" && -e "${ROOT_DIR}/$1" ]] || return 0
    grep -q 'stage_model_id\.sh --resolve' "${ROOT_DIR}/$1" 2>/dev/null && return 0
    log "NOTE: $1 does not allow the model-id resolver, so a delegate's model_id reads unrecorded."
    log "      Copy \"Bash(bash .claude/hooks/stage_model_id.sh --resolve:*)\" from upstream $1 into its permissions.allow."
}

# A kept .codex/hooks.json from before the memory hook got a SessionStart group
# of its own registers it beside the model-id hook under "startup|resume", so a
# session Codex starts any other way gets no memory index. The hook is named,
# so report_unregistered_hooks stays quiet about it; this says so instead. With
# no JSON reader at hand it stays silent rather than guess.
note_codex_memory_group() { # $1 = config path relative to the project root
    [[ "$1" == ".codex/hooks.json" && -e "${ROOT_DIR}/$1" ]] || return 0
    grep -q 'stage_memory\.sh' "${ROOT_DIR}/$1" 2>/dev/null || return 0
    command -v python3 >/dev/null 2>&1 || return 0
    python3 - "${ROOT_DIR}/$1" <<'PY' 2>/dev/null || return 0
import json, sys
groups = (json.load(open(sys.argv[1])).get("hooks") or {}).get("SessionStart") or []
sys.exit(1 if any(g.get("matcher") in (None, "", "*") and "stage_memory.sh" in json.dumps(g.get("hooks"))
                  for g in groups) else 0)
PY
    log "NOTE: $1 runs stage_memory.sh only on a SessionStart matcher, so some Codex sessions start without the memory index."
    log "      Move it into a SessionStart group of its own with no matcher, as upstream $1 does."
}

# A kept registration config that does not name one of the hooks: the script is
# installed, nothing errors, and either no memory reaches a session, or every
# artifact it writes records "unrecorded", or a git command §1 forbids meets no
# floor. Reported, not repaired — merging into a file the project may have
# extended is the user's.
report_unregistered_hooks() {
    local cfg missing hook label hooks
    for cfg in "${HOOK_CONFIGS[@]}"; do
        path_selected "${cfg}" || continue
        [[ -e "${ROOT_DIR}/${cfg}" ]] || continue
        missing=""
        # The commit guard declines a shell command before it runs, which every
        # harness can express — Claude, Codex, and Qwen on PreToolUse, Cursor on
        # beforeShellExecution — so every registration carries it. The involve gate
        # answers a permission prompt, so it applies only where a hook can
        # decide one: Cursor has no event that gates a file edit. The bash gate
        # ships in Claude's tree alone.
        hooks=("stage_memory.sh|project-memory" "stage_model_id.sh|model-id provenance"
               "stage_commit_guard.sh|commit guard")
        case "${cfg}" in
            .claude/settings.json|.codex/hooks.json|.qwen/settings.json)
                hooks+=("stage_involve_gate.sh|involve gate") ;;
        esac
        [[ "${cfg}" == ".claude/settings.json" ]] && \
            hooks+=("stage_bash_gate.sh|bash gate")
        # A delegate starts with none of the context the two session hooks
        # inject, and SessionStart does not fire for one. Claude Code is the
        # only harness here with an event that does — SubagentStart — so it is
        # the only config that can be missing it, and a config written before
        # the event existed registers the two scripts against SessionStart
        # alone. Nothing else reports that: the delegate simply records
        # "unrecorded" and works without the project's memory index.
        [[ "${cfg}" == ".claude/settings.json" ]] && \
            hooks+=("SubagentStart|SubagentStart delegate context")
        for hook in "${hooks[@]}"; do
            label="${hook#*|}"
            grep -q "${hook%%|*}" "${ROOT_DIR}/${cfg}" 2>/dev/null || missing+="${missing:+, }${label}"
        done
        if [[ -n "${missing}" ]]; then
            log "NOTE: ${cfg} was kept and registers no STAGE hook for: ${missing}."
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
        note_resolver_rule "${cfg}"
        note_codex_memory_group "${cfg}"
    done
}

usage() {
    cat <<'EOF'
Usage: bash execs/update.sh [ref] [--harnesses LIST] [--skill NAME] [--force]
       bash execs/update.sh --diff [ref] [--harnesses LIST] [--skill NAME] [--force]
       bash update.sh [ref] [--harnesses LIST] --adopt

Overwrite the STAGE-managed content — the shared agent instructions (AGENTS.md),
the shared skill store plus six named harness skill trees
(.agents, .claude, .cursor, .dsh, .kimi-code, .pi, .qwen), the Codex $stage /
$stage-auto plugin, the Kimi and DSH /stage and /stage-auto entries, their
hook, command, prompt, agent, extension, and Codex manifest paths,
docs/mds/stage-workflow/,
and every script under execs/ — the two entrypoints, run.sh and this one, and
the three utilities in execs/scpts/:
import.sh, lint.sh, fmt.sh — with files from upstream.
The default ref is main; a branch or tag may be supplied instead. Local edits to
selected managed paths are replaced, AGENTS.md included; the manuscript,
evidence, notes, and the memory store under .stage/memory/ are never touched.
Use --skill to update only the named skill across the shared root and selected
harness trees (it leaves everything else, entrypoints and docs included, alone).

No script under execs/ holds project configuration — everything an instance sets
lives in .env, which is git-ignored and never synced — so all five are safe to
replace. They are synced because they are called by name and by
flag: run.sh --main, lint.sh --no-build and import.sh --diff from the skills,
fmt.sh --check from lint.sh. A repo that syncs a skill while keeping a script
that predates the flag it passes gets a run that fails at that step. execs/update.sh syncs itself, so no repo strands on an
update mechanism too old to fetch its successor: it is installed by rename,
which leaves this running process on the old file and gives the next invocation
the new one.

Harness configuration an instance may have edited — .cursorignore, the four hook
registrations, and .pi/settings.json
— is installed when it is absent and otherwise kept, however far it has drifted
from upstream; only --force overwrites it. A kept registration that does not name
a hook is reported, since a hook nobody registers never fires.

--harnesses limits the run to named harness trees, comma separated: claude,
codex, cursor, dsh, kimi, pi or qwen — or all, which is the default, or none for
the shared skeleton by itself. A tree left out is neither written nor deleted.
Without the flag, the list comes from STAGE_HARNESSES (environment first, then
.env), then defaults to all. Shared paths — .agents/skills, .agents/commands,
the agent instructions, workflow documentation,
and every script under execs/ — are updated for every selection.
The generic router packages live under .codex/plugins, .dsh/commands and
.kimi-code/plugins; each is updated only when its harness is selected. Codex's
one discovery link under .agents/plugins follows the same selection.

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
  bash execs/update.sh --harnesses codex
  bash execs/update.sh --harnesses claude,pi --diff

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
        --harnesses)
            shift
            (( $# > 0 )) || fail "--harnesses requires a list of harnesses."
            [[ -z "${HARNESSES_ARG}" ]] || fail "--harnesses may only be specified once."
            HARNESSES_ARG="$1"
            ;;
        --harnesses=*)
            [[ -z "${HARNESSES_ARG}" ]] || fail "--harnesses may only be specified once."
            HARNESSES_ARG="${1#*=}"
            [[ -n "${HARNESSES_ARG}" ]] || fail "--harnesses requires a list of harnesses."
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

# The target .env supplies both updater settings. --adopt targets the current
# repository; every other mode targets the repository this script lives in.
ENV_DIR="${ROOT_DIR}"
[[ "${ADOPT}" == false ]] || ENV_DIR="$(pwd -P)"

env_value() { # $1 = key; last assignment in target .env, empty when absent
    [[ -f "${ENV_DIR}/.env" ]] || return 0
    sed -n "s/^$1=//p" "${ENV_DIR}/.env" | tail -1
}

# Harness selection precedence: flag, environment, .env, then all.
HARNESSES_SPEC="${HARNESSES_ARG}"
HARNESSES_SOURCE="--harnesses"
if [[ -z "${HARNESSES_SPEC}" ]]; then
    HARNESSES_SPEC="${STAGE_HARNESSES:-}"
    HARNESSES_SOURCE="the STAGE_HARNESSES environment variable"
fi
if [[ -z "${HARNESSES_SPEC}" ]]; then
    HARNESSES_SPEC="$(env_value STAGE_HARNESSES)"
    HARNESSES_SOURCE="STAGE_HARNESSES in .env"
fi
if [[ -z "${HARNESSES_SPEC}" ]]; then
    HARNESSES_SPEC="all"
    HARNESSES_SOURCE="the default"
fi

SELECTED_HARNESSES=()
if [[ "${HARNESSES_SPEC}" == "all" ]]; then
    SELECTED_HARNESSES=("${ALL_HARNESSES[@]}")
elif [[ "${HARNESSES_SPEC}" != "none" ]]; then
    while IFS= read -r name; do
        name="${name//[[:space:]]/}"
        [[ -n "${name}" ]] || continue
        known=false
        for harness in "${ALL_HARNESSES[@]}"; do
            [[ "${name}" == "${harness}" ]] && known=true
        done
        [[ "${known}" == true ]] || \
            fail "Unknown harness '${name}' in ${HARNESSES_SOURCE}. Valid: ${ALL_HARNESSES[*]}, all, none."
        is_selected "${name}" || SELECTED_HARNESSES+=("${name}")
    done < <(tr ',' '\n' <<<"${HARNESSES_SPEC}")
    (( ${#SELECTED_HARNESSES[@]} > 0 )) || \
        fail "${HARNESSES_SOURCE} names no harness. Use 'none' to cover the shared paths by themselves."
fi

if (( ${#SELECTED_HARNESSES[@]} < ${#ALL_HARNESSES[@]} )); then
    untouched=()
    for harness in "${ALL_HARNESSES[@]}"; do
        is_selected "${harness}" || untouched+=("${harness}")
    done
    selected_label="none"
    (( ${#SELECTED_HARNESSES[@]} == 0 )) || selected_label="${SELECTED_HARNESSES[*]}"
    log "Harnesses (${HARNESSES_SOURCE}): ${selected_label}."
    log "Left alone, neither written nor deleted: ${untouched[*]}."
fi

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
        # Shared roots first; they are installed for every harness selection.
        ".agents/skills"
        "${CODEX_MANIFEST_ROOT}"
        # The Codex-only $stage / $stage-auto plugin. Its .agents discovery entry is a
        # single file in ADOPT_FILES, not a link over the whole directory.
        ".codex/plugins"
        # Kimi and DSH own package-based adapters for /stage and /stage-auto.
        ".dsh/commands"
        ".kimi-code/plugins"
        "${SKILL_ROOTS[@]:1}"
        "${HOOK_TREES[@]}"
        "${EXTENSION_TREES[@]}"
        "${COMMAND_TREES[@]}"
        "${AGENT_RULES_TREE}"
        "${DOCS_TREE}"
    )
    ADOPT_FILES=(
        "${AGENT_DOCS[@]}"
        ".agents/plugins/marketplace.json"
        "${HARNESS_FILES[@]}"
        "${EXTENSION_FILES[@]}"
        "${HOOK_FILES[@]}"
        ".pi/APPEND_SYSTEM.md"
        # The memory store. It is the paper's own from here on; only the empty
        # directory marker comes from upstream — the hooks build the index
        # from the memory files themselves.
        ".stage/memory/.gitkeep"
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
        # The three template-layer files main.tex loads by path or by name: the
        # preprint class, the authoring package, and the bibliography style its
        # \bibliographystyle line names. A paper that already has any of them
        # keeps its own, like every file here.
        "manus/stys/stage.cls"
        "manus/stys/stage.sty"
        "manus/stys/stage.bst"
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
    filter_paths "${ADOPT_TREES[@]}"
    ADOPT_TREES=("${FILTERED[@]}")
    filter_paths "${ADOPT_FILES[@]}"
    ADOPT_FILES=("${FILTERED[@]}")
elif [[ -n "${SKILL_NAME}" ]]; then
    [[ "${SKILL_NAME}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || \
        fail "Invalid skill name '${SKILL_NAME}'."

    SYNC_PATHS=()
    for root in "${SKILL_ROOTS[@]}"; do
        SYNC_PATHS+=("${root}/${SKILL_NAME}")
    done
    SYNC_PATHS+=("${CODEX_MANIFEST_ROOT}/${SKILL_NAME}")
    filter_paths "${SYNC_PATHS[@]}"
    SYNC_PATHS=(${FILTERED[@]+"${FILTERED[@]}"})
    (( ${#SYNC_PATHS[@]} > 0 )) || \
        fail "--skill has no tree to act on: ${HARNESSES_SOURCE} selects no harness."
    # Every named tree may link to .agents, and .agents' openai.yaml links back
    # to .codex, so both stores must be present while sparse paths are resolved.
    SPARSE_PATHS=("${SYNC_PATHS[@]}" ".agents/skills/${SKILL_NAME}" ".codex/skills/${SKILL_NAME}")

    if [[ "${DIFF}" == true ]]; then
        log "Diffing skill: ${SKILL_NAME}"
    else
        log "Updating skill: ${SKILL_NAME}"
    fi
else
    # SYNC_PATHS is what gets diffed, dirty-checked, archived, and extracted —
    # directories and single files alike. SPARSE_PATHS is what the sparse
    # checkout creates files, and it holds directories only: `sparse-checkout
    # set` is cone-mode by default, where every argument is read as a directory,
    # so naming a file there would match nothing. A file's parent directory goes
    # in instead; fetching a few siblings we do not copy is cheaper than getting
    # this subtly wrong.
    SYNC_PATHS=(
        "${AGENT_DOCS[@]}"
        "${AGENT_RULES_TREE}"
        "${CODEX_MANIFEST_ROOT}"
        # Codex's $stage / $stage-auto plugin stays private to its tree. Only the marketplace
        # file is exposed through the exact .agents path the host discovers.
        ".codex/plugins"
        ".agents/plugins/marketplace.json"
        # Kimi's /stage and /stage-auto plugin and DSH's command bundle stay private
        # to their own trees and are installed into each host separately.
        ".dsh/commands"
        ".kimi-code/plugins"
        "${SKILL_ROOTS[@]}"
        "${HOOK_TREES[@]}"
        "${EXTENSION_TREES[@]}"
        "${EXTENSION_FILES[@]}"
        "${COMMAND_TREES[@]}"
        "${HOOK_FILES[@]}"
        "${DOCS_TREE}"
        "${SYNC_FILES[@]}"
    )
    filter_paths "${SYNC_PATHS[@]}"
    SYNC_PATHS=("${FILTERED[@]}")
    SPARSE_PATHS=(
        # Both stores are checkout dependencies even when Codex is not selected:
        # shared files link between them, while SYNC_PATHS still decides what is
        # installed into the target repository.
        ".agents/skills"
        ".agents/commands"
        ".agents/plugins"
        ".codex/skills"
        "${DOCS_TREE}"
        "execs"
    )
    for harness in ${SELECTED_HARNESSES[@]+"${SELECTED_HARNESSES[@]}"}; do
        read -ra harness_roots <<<"$(harness_dirs "${harness}")"
        SPARSE_PATHS+=("${harness_roots[@]}")
    done
fi

# Without --adopt this script rewrites the project it lives in, derived from
# its own location. A copy run from somewhere else would target that other
# tree.
if [[ "${ADOPT}" == false ]]; then
    [[ -f "${ROOT_DIR}/execs/run.sh" ]] || \
        fail "${ROOT_DIR} is not a STAGE project (no execs/run.sh). This script updates the project it lives in: copy it to <paper>/execs/update.sh and run it there, or pass --adopt to install STAGE into the current directory."
fi

# Upstream resolution: environment wins, then the target .env, then the public default.
if [[ -z "${STAGE_REPOSITORY:-}" ]]; then
    STAGE_REPOSITORY="$(env_value STAGE_REPOSITORY)"
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

# Preserve the template's shared skill links even on hosts whose global Git
# configuration disables symlink checkout.
CLONE_ARGS=(-c core.symlinks=true --quiet --depth 1 --branch "${STAGE_REF}" --single-branch)
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
    # file that the sparse checkout failed to create stops the run here
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
        done < <(cd "${SOURCE_DIR}" && find -L "${SYNCED[@]}" -type f | sort)

        # Project-local files under the same paths; an update keeps them.
        while IFS= read -r rel; do
            if [[ ! -e "${SOURCE_DIR}/${rel}" ]]; then
                printf '  extra    %s (not in upstream ref; update keeps it)\n' "${rel}"
                kept=$(( kept + 1 ))
            fi
        done < <(cd "${ROOT_DIR}" && find -L "${SYNCED[@]}" -type f 2>/dev/null | sort)

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
            # An .env/environment selection is already reproduced by the plain
            # command; only a one-run flag needs carrying into the hint.
            [[ -z "${HARNESSES_ARG}" ]] || hint="${hint} --harnesses ${HARNESSES_ARG}"
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
            filter_paths "${HARNESS_FILES[@]}"
            DIRTY_PATHS+=(${FILTERED[@]+"${FILTERED[@]}"})
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
        if [[ "${path}" == "${SELF_PATH}" ]]; then
            continue
        elif [[ "${path}" == ".agents/plugins/marketplace.json" ]]; then
            # tar -h intentionally dereferences shared skill links, but this
            # link must remain the one narrow .agents discovery entry.
            continue
        else
            TAR_PATHS+=("${path}")
        fi
    done

    if (( ${#TAR_PATHS[@]} > 0 )); then
        # Follow links so installed harness trees are self-contained. GNU tar may
        # otherwise encode repeated targets as hard links, which some filesystems
        # reject; bsdtar already stores full copies and has no such option.
        TAR_CREATE_ARGS=(-ch)
        if tar --help 2>/dev/null | grep -q -- --hard-dereference; then
            TAR_CREATE_ARGS+=(--hard-dereference)
        fi
        tar -C "${SOURCE_DIR}" "${TAR_CREATE_ARGS[@]}" -f "${ARCHIVE_FILE}" "${TAR_PATHS[@]}"
        tar -C "${ROOT_DIR}" -xf "${ARCHIVE_FILE}"
    fi

    if [[ -z "${SKILL_NAME}" ]] && is_selected codex; then
        link_codex_marketplace
    fi

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
        log "      This run finishes on the old code; run it once more to receive any path the new updater adds."
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
    if [[ "${rel}" == ".agents/plugins/marketplace.json" ]]; then
        link_codex_marketplace
        printf '  added   %s -> %s\n' "${rel}" "../../.codex/plugins/marketplace.json"
        installed=$(( installed + 1 ))
        return 0
    fi
    mkdir -p "$(dirname -- "${dst}")"
    cp -p "${src}" "${dst}"
    printf '  added   %s\n' "${rel}"
    installed=$(( installed + 1 ))
}

for tree in "${ADOPT_TREES[@]}"; do
    if [[ ! -d "${SOURCE_DIR}/${tree}" ]]; then
        if is_optional_path "${tree}"; then
            log "Skipping ${tree}: not present in ref '${STAGE_REF}'."
            continue
        fi
        fail "Upstream ref is missing ${tree}."
    fi
    while IFS= read -r rel; do
        install_file "${rel}"
    done < <(cd "${SOURCE_DIR}" && find -L "${tree}" -type f | sort)
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
log "      DSH and Kimi Code: run their .dsh/hooks/install.sh and .kimi-code/hooks/install.sh once per machine."
