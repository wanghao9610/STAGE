#!/usr/bin/env bash
# STAGE upstream consistency check.
#
# Guards the invariants the shared skill store plus six named harness trees, the
# shared agent instructions, and the workflow docs
# are supposed to keep while being maintained by hand. The trees hold the same
# sixteen skills and share their workflow shape. Explicit harness-local
# capabilities are exceptions only when a dedicated check below pins both the
# enhanced harness and the absence of that contract elsewhere; unguarded drift
# remains a bug, and nothing but this script looks for it.
#
# Run from anywhere inside the repo:  bash .github/scripts/check_consistency.sh
# Exits non-zero if any check fails. Upstream-maintainer tooling only — this
# directory is not synced into paper repositories by execs/update.sh.
set -uo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
cd "${ROOT_DIR}" || exit 1

SKILL_ROOTS=(.agents/skills .claude/skills .cursor/skills .dsh/skills .kimi-code/skills .pi/skills .qwen/skills)
# The six named trees guard implicit invocation through SKILL.md frontmatter;
# Codex does it through .codex/skills/*/agents/openai.yaml instead (check 4).
FRONTMATTER_ROOTS=(.claude/skills .cursor/skills .dsh/skills .kimi-code/skills .pi/skills .qwen/skills)
CONV_EN="docs/mds/stage-workflow/writing-workflow-conventions.md"

FAILURES=0
fail() { printf 'FAIL  %s\n' "$*"; FAILURES=$(( FAILURES + 1 )); }
note() { printf 'ok    %s\n' "$*"; }
section() { printf '\n== %s ==\n' "$*"; }

list_skills() { # $1 = skill root
    find "$1" -mindepth 1 -maxdepth 1 -type d | sed 's|.*/||' | sort
}

frontmatter_has_line() { # $1 = file, $2 = exact line expected inside the leading --- block
    awk -v want="$2" 'NR == 1 { next } /^---[ \t]*$/ { exit } $0 == want { found = 1; exit } END { exit !found }' "$1"
}

# 0. Generated trees and shared-link topology match their declared source.
section "Generated harness trees"
if bash .github/scripts/port.sh --check; then
    note "all six harness trees reproduce from the authored .agents source plus their adapters"
else
    fail ".github/scripts/port.sh --check failed"
fi

link_errors=0
for root in .claude/skills .cursor/skills .dsh/skills .kimi-code/skills .pi/skills .qwen/skills; do
    while IFS= read -r link; do
        target="$(readlink "${link}")"
        case "${target}" in
            ../../.agents/skills/*|../../../.agents/skills/*|../../../../.agents/skills/*) ;;
            *) fail "${link} points outside .agents/skills: ${target}"; link_errors=1 ;;
        esac
        [[ -e "${link}" ]] || { fail "${link} is broken"; link_errors=1; }
    done < <(find "${root}" -type l | sort)
done
manifest_links=0
while IFS= read -r link; do
    manifest_links=$(( manifest_links + 1 ))
    target="$(readlink "${link}")"
    [[ "${target}" == ../../../../.codex/skills/*/agents/openai.yaml ]] || {
        fail "${link} must point to its .codex/skills manifest, got ${target}"
        link_errors=1
    }
    [[ -e "${link}" ]] || { fail "${link} is broken"; link_errors=1; }
done < <(find .agents/skills -path '*/agents/openai.yaml' -type l | sort)
(( manifest_links == 16 )) || { fail ".agents has ${manifest_links} openai.yaml links, expected 16"; link_errors=1; }
real_manifests="$(find .codex/skills -path '*/agents/openai.yaml' -type f | wc -l | tr -d ' ')"
(( real_manifests == 16 )) || { fail ".codex has ${real_manifests} real openai.yaml manifests, expected 16"; link_errors=1; }
(( link_errors == 0 )) && note "shared links resolve only through .agents; 16 Codex manifests live under .codex"

# 1. The seven roots carry the same, non-empty set of skill directories.
section "Skill directory sets"
SKILLS="$(list_skills "${SKILL_ROOTS[0]}")"
if [[ -z "${SKILLS}" ]]; then
    fail "${SKILL_ROOTS[0]} contains no skill directories"
else
    for root in "${SKILL_ROOTS[@]:1}"; do
        if [[ "$(list_skills "${root}")" != "${SKILLS}" ]]; then
            fail "${root} skill set differs from ${SKILL_ROOTS[0]}:"
            diff <(printf '%s\n' "${SKILLS}") <(list_skills "${root}") | sed 's/^/      /'
        fi
    done
    note "$(printf '%s\n' "${SKILLS}" | wc -l | tr -d ' ') skills, same set in all seven roots"
fi

# 2. Frontmatter name matches the directory name in every tree.
section "Frontmatter name = directory name"
name_errors=0
for root in "${SKILL_ROOTS[@]}"; do
    while IFS= read -r skill; do
        manifest="${root}/${skill}/SKILL.md"
        if [[ ! -f "${manifest}" ]]; then
            fail "${manifest} is missing"
            name_errors=1
            continue
        fi
        if ! frontmatter_has_line "${manifest}" "name: ${skill}"; then
            fail "${manifest}: frontmatter name does not match directory '${skill}'"
            name_errors=1
        fi
    done < <(printf '%s\n' "${SKILLS}")
done
(( name_errors == 0 )) && note "every manifest's name matches its directory"

# 3. Per-skill file inventory is identical across the seven roots, apart from the
#    Codex-only agents/ manifest directory.
section "File inventory parity (ignoring .agents agents/ manifests)"
parity_errors=0
while IFS= read -r skill; do
    baseline="$(cd ".agents/skills/${skill}" && find -L . -type f ! -path './agents/*' | sort)"
    for root in "${SKILL_ROOTS[@]:1}"; do
        listing="$(cd "${root}/${skill}" && find -L . -type f ! -path './agents/*' | sort)"
        if [[ "${listing}" != "${baseline}" ]]; then
            fail "${root}/${skill} file set differs from .agents/skills/${skill}:"
            diff <(printf '%s\n' "${baseline}") <(printf '%s\n' "${listing}") | sed 's/^/      /'
            parity_errors=1
        fi
    done
done < <(printf '%s\n' "${SKILLS}")
(( parity_errors == 0 )) && note "file sets match across all seven trees"

# 4. The slash-only set is one decision expressed in seven places, and they must
#    agree. The conventions roster (§11) marks it with † and is what every skill
#    run loads; the six named trees enforce it with
#    `disable-model-invocation: true`;
#    Codex enforces it with `allow_implicit_invocation: false` in
#    agents/openai.yaml. A skill guarded in one place and not the others runs
#    unrequested on exactly the harnesses that forgot it — the failure mode is
#    silent, and it is the mode this check exists for.
section "Slash-only guard agreement"
guard_errors=0
SLASH_ONLY="$(sed -nE 's/^\| `(stage-[a-z-]+)` † \|.*/\1/p' "${CONV_EN}" | sort)"
if [[ -z "${SLASH_ONLY}" ]]; then
    fail "${CONV_EN} marks no skill with † in its §11 roster; the slash-only set cannot be resolved"
    guard_errors=1
fi

while IFS= read -r skill; do
    manifest=".codex/skills/${skill}/agents/openai.yaml"
    if [[ ! -f "${manifest}" ]]; then
        fail "${manifest} is missing; every Codex skill needs its interface manifest"
        guard_errors=1
        continue
    fi
    policy="$(sed -nE 's/^[[:space:]]*allow_implicit_invocation:[[:space:]]*(true|false)[[:space:]]*$/\1/p' "${manifest}")"
    if [[ -z "${policy}" ]]; then
        fail "${manifest}: allow_implicit_invocation is absent or not literally true/false"
        guard_errors=1
        continue
    fi

    want_guarded=false
    grep -qxF "${skill}" <<< "${SLASH_ONLY}" && want_guarded=true

    if [[ "${want_guarded}" == true && "${policy}" != "false" ]]; then
        fail "${manifest}: ${skill} is slash-only in the conventions roster but allows implicit invocation"
        guard_errors=1
    fi
    if [[ "${want_guarded}" == false && "${policy}" != "true" ]]; then
        fail "${manifest}: ${skill} is not slash-only in the conventions roster but forbids implicit invocation"
        guard_errors=1
    fi

    for root in "${FRONTMATTER_ROOTS[@]}"; do
        has=false
        frontmatter_has_line "${root}/${skill}/SKILL.md" "disable-model-invocation: true" && has=true
        if [[ "${want_guarded}" != "${has}" ]]; then
            if [[ "${want_guarded}" == true ]]; then
                fail "${root}/${skill}/SKILL.md: slash-only in the conventions roster but no 'disable-model-invocation: true'"
            else
                fail "${root}/${skill}/SKILL.md: carries 'disable-model-invocation: true' but is not slash-only in the conventions roster"
            fi
            guard_errors=1
        fi
    done
done < <(printf '%s\n' "${SKILLS}")
(( guard_errors == 0 )) && note "$(printf '%s\n' "${SLASH_ONLY}" | wc -l | tr -d ' ') slash-only skills guarded identically in all seven trees"

# 4a. The full /stage router is neutral content and lives once under .agents,
#     English only: its Chinese reading edition is retired, and a run in Chinese
#     follows the English roster and replies in Chinese.
#     Native command files adapt only their harness's argument syntax and skill
#     mechanism. Copying the roster into those files creates four policy surfaces
#     whose explicit-only set can drift independently.
section "Shared request router"
router_errors=0
ROUTER=".agents/commands/stage.md"
router_rows() { # $1 = router file, $2 = row regex -> matching skill names, sorted
    sed -nE "$2" "$1" | sort
}
ROUTER_ANY='s/^\| `(stage-[a-z-]+)` \|.*$/\1/p'
ROUTER_DAGGER='s/^\| `(stage-[a-z-]+)` \| † \|.*$/\1/p'
for router in "${ROUTER}"; do
    if [[ ! -f "${router}" ]]; then
        fail "${router} is missing"
        router_errors=1
        continue
    fi
    ROUTER_SKILLS="$(router_rows "${router}" "${ROUTER_ANY}")"
    if [[ "${ROUTER_SKILLS}" != "${SKILLS}" ]]; then
        fail "${router} roster differs from the shared skill set:"
        diff <(printf '%s\n' "${SKILLS}") <(printf '%s\n' "${ROUTER_SKILLS}") | sed 's/^/      /'
        router_errors=1
    fi
    ROUTER_SLASH_ONLY="$(router_rows "${router}" "${ROUTER_DAGGER}")"
    if [[ "${ROUTER_SLASH_ONLY}" != "${SLASH_ONLY}" ]]; then
        fail "${router} explicit-only set differs from conventions §11:"
        diff <(printf '%s\n' "${SLASH_ONLY}") <(printf '%s\n' "${ROUTER_SLASH_ONLY}") | sed 's/^/      /'
        router_errors=1
    fi
done
if [[ -e .agents/commands/stage.zh-CN.md ]]; then
    fail ".agents/commands/stage.zh-CN.md is retired; the English router is the only copy"
    router_errors=1
fi

while IFS='|' read -r wrapper argument_marker; do
    [[ -n "${wrapper}" ]] || continue
    if [[ ! -f "${wrapper}" ]]; then
        fail "missing native request-router entry point: ${wrapper}"
        router_errors=1
        continue
    fi
    grep -qF 'Read `.agents/commands/stage.md`' "${wrapper}" || {
        fail "${wrapper} does not delegate to the shared router"
        router_errors=1
    }
    grep -qF -- "${argument_marker}" "${wrapper}" || {
        fail "${wrapper} does not carry its native argument marker ${argument_marker}"
        router_errors=1
    }
    if grep -qE '^\| `stage-[a-z-]+`' "${wrapper}"; then
        fail "${wrapper} duplicates the roster owned by ${ROUTER}"
        router_errors=1
    fi
done <<'EOF'
.claude/commands/stage.md|[$ARGUMENTS]
.cursor/commands/stage.md|beside `/stage`
.pi/prompts/stage.md|[$@]
.qwen/commands/stage.md|[{{args}}]
EOF
(( router_errors == 0 )) && note "one English neutral roster drives four file-based native command entry points"

# 4b. Kimi exposes /stage as an explicit-only plugin skill. The plugin owns
#     only the native invocation adapter; the roster remains under .agents.
section "Kimi STAGE command plugin layout"
kimi_plugin_errors=0
KIMI_MARKETPLACE=".kimi-code/plugins/marketplace.json"
KIMI_PLUGIN_ROOT=".kimi-code/plugins/stage"
if ! python3 -c 'import json,sys; m=json.load(open(sys.argv[1])); p=json.load(open(sys.argv[2])); e=m["plugins"]; assert m["version"] == "2" and len(e) == 1 and e[0] == {"id": "stage", "displayName": "STAGE", "source": "./.kimi-code/plugins/stage"}; assert p["name"] == "stage" and p["skills"] == "./skills/"' "${KIMI_MARKETPLACE}" "${KIMI_PLUGIN_ROOT}/.kimi-plugin/plugin.json"; then
    fail "Kimi STAGE plugin or marketplace metadata is invalid"
    kimi_plugin_errors=1
fi
KIMI_ROUTER_SKILL="${KIMI_PLUGIN_ROOT}/skills/stage/SKILL.md"
if [[ ! -f "${KIMI_ROUTER_SKILL}" ]] || \
   ! frontmatter_has_line "${KIMI_ROUTER_SKILL}" "name: stage" || \
   ! frontmatter_has_line "${KIMI_ROUTER_SKILL}" "disableModelInvocation: true" || \
   ! grep -qF 'Read `.agents/commands/stage.md`' "${KIMI_ROUTER_SKILL}" || \
   ! grep -qF '/skill:stage-<name> <argument>' "${KIMI_ROUTER_SKILL}"; then
    fail "${KIMI_ROUTER_SKILL} is not the explicit-only Kimi adapter around the shared router"
    kimi_plugin_errors=1
elif grep -qE '^\| `stage-[a-z-]+`' "${KIMI_ROUTER_SKILL}"; then
    fail "${KIMI_ROUTER_SKILL} duplicates the roster owned by ${ROUTER}"
    kimi_plugin_errors=1
fi
if ! grep -qF 'STAGE_LANG=en|zh' "${KIMI_ROUTER_SKILL}" || \
   grep -qF 'stage.zh-CN.md' "${KIMI_ROUTER_SKILL}"; then
    fail "${KIMI_ROUTER_SKILL} does not resolve the reply language over the English-only router"
    kimi_plugin_errors=1
fi
(( kimi_plugin_errors == 0 )) && note "Kimi owns one explicit-only /stage adapter around the shared router"

# 4c. DSH exposes /stage through a zero-dependency Cordis bundle. Its handler
#     injects the request into a follow-up turn that reads the shared router;
#     neither the package patch nor the JavaScript may carry a second roster.
section "DSH STAGE command bundle layout"
dsh_command_errors=0
DSH_COMMAND_ROOT=".dsh/commands/stage"
if ! python3 -c 'import json,sys; p=json.load(open(sys.argv[1])); assert p["name"] == "stage" and p["private"] is True and p["type"] == "module" and p["main"] == "lib/index.js" and p["dsh"]["bundle"]["patch"] == "./cordis.patch.yml"' "${DSH_COMMAND_ROOT}/package.json"; then
    fail "${DSH_COMMAND_ROOT}/package.json is not a DSH command bundle"
    dsh_command_errors=1
fi
if ! grep -qE '^[[:space:]]*- id: stage[[:space:]]*$' "${DSH_COMMAND_ROOT}/cordis.patch.yml" || \
   ! grep -qE "^[[:space:]]*name: 'stage'[[:space:]]*$" "${DSH_COMMAND_ROOT}/cordis.patch.yml"; then
    fail "${DSH_COMMAND_ROOT}/cordis.patch.yml does not insert the stage command plugin"
    dsh_command_errors=1
fi
DSH_COMMAND_IMPL="${DSH_COMMAND_ROOT}/lib/index.js"
if ! node --check "${DSH_COMMAND_IMPL}" >/dev/null 2>&1 || \
   ! grep -qF 'const name = "stage";' "${DSH_COMMAND_IMPL}" || \
   ! grep -qF 'ctx.commands.register({' "${DSH_COMMAND_IMPL}" || \
   ! grep -qF 'recordInput: false' "${DSH_COMMAND_IMPL}" || \
   ! grep -qF 'Read `.agents/commands/stage.md`' "${DSH_COMMAND_IMPL}" || \
   ! grep -qF 'select `stage-flow-status`' "${DSH_COMMAND_IMPL}"; then
    fail "${DSH_COMMAND_IMPL} is not the thin DSH adapter around the shared router"
    dsh_command_errors=1
elif grep -qE '^\| `stage-[a-z-]+`' "${DSH_COMMAND_IMPL}"; then
    fail "${DSH_COMMAND_IMPL} duplicates the roster owned by ${ROUTER}"
    dsh_command_errors=1
fi
(( dsh_command_errors == 0 )) && note "DSH owns one zero-dependency /stage adapter around the shared router"

# 4d. Codex gets the generic router through one plugin owned entirely by
#     .codex. .agents exposes only the marketplace file the host discovers;
#     linking the directory would leak every Codex-private plugin into a shared
#     namespace and turn future harness support there into a collision.
section "Codex STAGE plugin layout"
plugin_errors=0
MARKETPLACE=".codex/plugins/marketplace.json"
PLUGIN_ROOT=".codex/plugins/stage"
DISCOVERY=".agents/plugins/marketplace.json"
if [[ ! -L "${DISCOVERY}" ]]; then
    fail "${DISCOVERY} is not a file symlink"
    plugin_errors=1
elif [[ "$(readlink "${DISCOVERY}")" != "../../.codex/plugins/marketplace.json" ]]; then
    fail "${DISCOVERY} does not point to ../../.codex/plugins/marketplace.json"
    plugin_errors=1
elif ! cmp -s "${DISCOVERY}" "${MARKETPLACE}"; then
    fail "${DISCOVERY} does not resolve to ${MARKETPLACE}"
    plugin_errors=1
fi
if ! python3 -c 'import json,sys; m=json.load(open(sys.argv[1])); p=json.load(open(sys.argv[2])); e=m["plugins"]; assert m["name"] == "stage" and len(e) == 1 and e[0]["name"] == "stage" and e[0]["source"] == {"source": "local", "path": "./.codex/plugins/stage"}; assert e[0]["policy"] == {"installation": "AVAILABLE", "authentication": "ON_INSTALL"} and e[0]["category"] == "Productivity"; assert p["name"] == "stage" and p["skills"] == "./skills/"' "${MARKETPLACE}" "${PLUGIN_ROOT}/.codex-plugin/plugin.json"; then
    fail "Codex STAGE plugin or marketplace metadata is invalid"
    plugin_errors=1
fi
if [[ ! -f "${PLUGIN_ROOT}/skills/stage/SKILL.md" ]] || \
   ! frontmatter_has_line "${PLUGIN_ROOT}/skills/stage/SKILL.md" "name: stage" || \
   ! grep -qF 'Read `.agents/commands/stage.md`' "${PLUGIN_ROOT}/skills/stage/SKILL.md" || \
   ! grep -qF 'allow_implicit_invocation: false' "${PLUGIN_ROOT}/skills/stage/agents/openai.yaml"; then
    fail "${PLUGIN_ROOT}/skills/stage is not the explicit-only wrapper around the shared router"
    plugin_errors=1
fi
if ! grep -qF 'STAGE_LANG=en|zh' "${PLUGIN_ROOT}/skills/stage/SKILL.md" || \
   grep -qF 'stage.zh-CN.md' "${PLUGIN_ROOT}/skills/stage/SKILL.md"; then
    fail "${PLUGIN_ROOT}/skills/stage/SKILL.md does not resolve the reply language over the English-only router"
    plugin_errors=1
fi
(( plugin_errors == 0 )) && note "Codex owns one stage plugin; .agents exposes only its marketplace file"

# 4e. All three package-based routers move through adopt and full updates, old
#      refs may omit the later Kimi/DSH packages, and both README editions give
#      the same host setup commands.
section "Router deployment and documentation"
deployment_errors=0
for router_tree in ".codex/plugins" ".dsh/commands" ".kimi-code/plugins"; do
    if [[ "$(grep -Fxc "        \"${router_tree}\"" execs/update.sh)" -ne 2 ]]; then
        fail "execs/update.sh must carry ${router_tree} in both adopt and full-update paths"
        deployment_errors=1
    fi
done
for optional_tree in ".dsh/commands" ".kimi-code/plugins"; do
    if ! grep -qF "\"${optional_tree}\")" execs/update.sh; then
        fail "execs/update.sh does not allow an older ref to omit ${optional_tree}"
        deployment_errors=1
    fi
done
if ! grep -qF 'if is_optional_path "${tree}"; then' execs/update.sh; then
    fail "execs/update.sh --adopt does not skip router packages absent from an older ref"
    deployment_errors=1
fi
for readme in README.md README.zh-CN.md; do
    for command in \
        'codex plugin marketplace add .' \
        'codex plugin add stage@stage' \
        '/plugins install ./.kimi-code/plugins/stage' \
        '/reload' \
        'dsh plugin --profile YOUR_PROFILE add ./.dsh/commands/stage' \
        'dsh --profile YOUR_PROFILE --dump-config'; do
        if ! grep -qF "${command}" "${readme}"; then
            fail "${readme} omits router setup step: ${command}"
            deployment_errors=1
        fi
    done
    for shared_topic in \
        'STAGE_LANG' \
        'STAGE_HARNESSES' \
        'INVOLVE=low' \
        '.stage/memory/' \
        'bash execs/update.sh --diff' \
        'bash execs/update.sh TAG_OR_BRANCH' \
        'bash execs/update.sh --harnesses claude' \
        'bash execs/update.sh --skill stage-flow-status' \
        '--adopt' \
        '--force'; do
        if ! grep -qF -- "${shared_topic}" "${readme}"; then
            fail "${readme} omits shared setup or update topic: ${shared_topic}"
            deployment_errors=1
        fi
    done
done
(( deployment_errors == 0 )) && note "all router packages update by harness, tolerate older refs, and share one setup template"

# 4f. /stage-auto is the goal-run grant (conventions §11.5): one shared
#     procedure under .agents/commands, thin native entry points in every
#     harness, each explicit-only. The procedure never starts a skill marked †,
#     so it must name every one of them, and every wrapper must carry that rule.
section "Goal run grant (/stage-auto)"
auto_errors=0
AUTO_PROCEDURE=".agents/commands/stage-auto.md"
if [[ ! -f "${AUTO_PROCEDURE}" ]]; then
    fail "${AUTO_PROCEDURE} is missing"
    auto_errors=1
else
    while IFS= read -r skill; do
        grep -qF "\`${skill}\`" "${AUTO_PROCEDURE}" || {
            fail "${AUTO_PROCEDURE} does not name ${skill} among the † skills a goal run never starts"
            auto_errors=1
        }
    done < <(printf '%s\n' "${SLASH_ONLY}")
    grep -qF 'Green lint is never the check' "${AUTO_PROCEDURE}" || {
        fail "${AUTO_PROCEDURE} lost the rule that green lint is never a goal run's check"
        auto_errors=1
    }
    if grep -qE 'stop=|auto=unattended|tier=' "${AUTO_PROCEDURE}"; then
        fail "${AUTO_PROCEDURE} carries STAR's grant machinery (stop=, auto=unattended, tier=)"
        auto_errors=1
    fi
    if grep -qE '^\| `stage-[a-z-]+`' "${AUTO_PROCEDURE}"; then
        fail "${AUTO_PROCEDURE} duplicates the roster owned by ${ROUTER}"
        auto_errors=1
    fi
fi
while IFS='|' read -r wrapper argument_marker; do
    [[ -n "${wrapper}" ]] || continue
    if [[ ! -f "${wrapper}" ]]; then
        fail "missing native goal-run entry point: ${wrapper}"
        auto_errors=1
        continue
    fi
    if ! grep -qF 'Read `.agents/commands/stage-auto.md`' "${wrapper}" || \
       ! grep -qF -- "${argument_marker}" "${wrapper}" || \
       ! grep -qF '†' "${wrapper}"; then
        fail "${wrapper} does not delegate to ${AUTO_PROCEDURE} with its native argument marker ${argument_marker}, or drops its † rule"
        auto_errors=1
    fi
done <<'EOF'
.claude/commands/stage-auto.md|[$ARGUMENTS]
.cursor/commands/stage-auto.md|beside `/stage-auto`
.pi/prompts/stage-auto.md|[$@]
.qwen/commands/stage-auto.md|[{{args}}]
EOF
if [[ -f .claude/commands/stage-auto.md ]] && \
   ! frontmatter_has_line .claude/commands/stage-auto.md 'disable-model-invocation: true'; then
    fail '.claude/commands/stage-auto.md must stay user-only (disable-model-invocation: true)'
    auto_errors=1
fi
CODEX_AUTO_SKILL="${PLUGIN_ROOT}/skills/stage-auto/SKILL.md"
if [[ ! -f "${CODEX_AUTO_SKILL}" ]] || \
   ! frontmatter_has_line "${CODEX_AUTO_SKILL}" 'name: stage-auto' || \
   ! grep -qF 'Read `.agents/commands/stage-auto.md`' "${CODEX_AUTO_SKILL}" || \
   ! grep -qF 'allow_implicit_invocation: false' "${PLUGIN_ROOT}/skills/stage-auto/agents/openai.yaml" || \
   ! grep -qF '$stage-auto' "${PLUGIN_ROOT}/.codex-plugin/plugin.json"; then
    fail "${PLUGIN_ROOT} does not carry the explicit-only \$stage-auto wrapper around ${AUTO_PROCEDURE}"
    auto_errors=1
fi
KIMI_AUTO_SKILL="${KIMI_PLUGIN_ROOT}/skills/stage-auto/SKILL.md"
if [[ ! -f "${KIMI_AUTO_SKILL}" ]] || \
   ! frontmatter_has_line "${KIMI_AUTO_SKILL}" 'name: stage-auto' || \
   ! frontmatter_has_line "${KIMI_AUTO_SKILL}" 'disableModelInvocation: true' || \
   ! grep -qF 'Read `.agents/commands/stage-auto.md`' "${KIMI_AUTO_SKILL}" || \
   ! grep -qF '/stage-auto' "${KIMI_PLUGIN_ROOT}/.kimi-plugin/plugin.json"; then
    fail "${KIMI_PLUGIN_ROOT} does not carry the explicit-only /stage-auto wrapper around ${AUTO_PROCEDURE}"
    auto_errors=1
fi
if ! grep -qF 'name: "stage-auto",' "${DSH_COMMAND_IMPL}" || \
   ! grep -qF 'Read `.agents/commands/stage-auto.md`' "${DSH_COMMAND_IMPL}" || \
   ! grep -qF "except \`/stage-auto <goal>\`, which DSH registers as a command" "${DSH_COMMAND_IMPL}" || \
   ! grep -qF '/stage-auto' "${DSH_COMMAND_ROOT}/cordis.patch.yml"; then
    fail "${DSH_COMMAND_ROOT} does not also register /stage-auto, or its follow-ups do not respell /stage-<name> while keeping /stage-auto"
    auto_errors=1
fi
grep -qF '`/stage-auto <goal>`' "${ROUTER}" || {
    fail "${ROUTER} does not hand goal pursuit to /stage-auto"
    auto_errors=1
}
if ! grep -qF '(../../../.agents/commands/stage-auto.md)' "${CONV_EN}"; then
    fail "${CONV_EN} does not link the goal-run procedure from §11"
    auto_errors=1
fi
if ! grep -qF '`stage-auto <goal>`' AGENTS.md || grep -qF '/stage-auto' AGENTS.md; then
    fail 'AGENTS.md must name `stage-auto <goal>`, harness-neutrally'
    auto_errors=1
fi
(( auto_errors == 0 )) && note "/stage-auto is one shared procedure behind explicit-only entry points in all seven harnesses; it never starts the $(printf '%s\n' "${SLASH_ONLY}" | wc -l | tr -d ' ') skills marked † and carries no STAR grant machinery"

# 5. Bilingual twins: every reference .md has its _zh.md counterpart and vice
#    versa. SKILL.md is English only, in the skill trees and in the router
#    plugins alike: no run loads a Chinese edition of it, so a SKILL_zh.md
#    anywhere fails.
section "Bilingual twins in skill trees"
twin_errors=0
while IFS= read -r f; do
    [[ "${f}" == */SKILL.md ]] && continue
    if [[ "${f}" == *_zh.md ]]; then
        [[ -f "${f%_zh.md}.md" ]] || { fail "${f} has no English counterpart"; twin_errors=1; }
    else
        [[ -f "${f%.md}_zh.md" ]] || { fail "${f} has no _zh.md counterpart"; twin_errors=1; }
    fi
done < <(find -L "${SKILL_ROOTS[@]}" -type f -name '*.md')
while IFS= read -r f; do
    fail "${f}: SKILL.md has no Chinese edition; a Chinese run reads SKILL.md and replies in Chinese"
    twin_errors=1
done < <(find -L "${SKILL_ROOTS[@]}" .codex/skills .codex/plugins .kimi-code/plugins -name SKILL_zh.md | sort)
(( twin_errors == 0 )) && note "every reference .md file has its bilingual twin; no tree or plugin carries a SKILL_zh.md"

# 6. Every manifest defers to the shared conventions document, by name.
#    Citing "conventions §8" without naming the file is what stage-proj-adopt
#    and stage-evid-curator did for their whole life: they read as if the
#    baseline were loaded, and no run ever loaded it.
section "Shared-conventions reference"
conv_ref_errors=0
for root in "${SKILL_ROOTS[@]}"; do
    while IFS= read -r skill; do
        grep -q 'writing-workflow-conventions\.md' "${root}/${skill}/SKILL.md" || {
            fail "${root}/${skill}/SKILL.md does not name the conventions document"
            conv_ref_errors=1
        }
    done < <(printf '%s\n' "${SKILLS}")
done
(( conv_ref_errors == 0 )) && note "every manifest names the conventions document"

# 7. Frontmatter advertises each harness's native invocation, while the generated
#    body stays prefix-neutral so shared files can live under .agents.
section "Invocation-token hygiene"
token_errors=0
SKILL_ALT="$(printf '%s\n' "${SKILLS}" | paste -sd '|' -)"
while IFS= read -r skill; do
    for root in "${SKILL_ROOTS[@]}"; do
        case "${root}" in
            .agents/skills) expected="${skill}" ;;
            .dsh/skills|.kimi-code/skills) expected="/skill:${skill}" ;;
            *) expected="/${skill}" ;;
        esac
        path="${root}/${skill}/SKILL.md"
        front="$(awk 'NR == 1 { next } /^---[ \t]*$/ { exit } { print }' "${path}")"
        body="$(awk 'NR == 1 && /^---[ \t]*$/ { fm = 1; next } fm && /^---[ \t]*$/ { fm = 0; next } !fm { print }' "${path}")"
        grep -qF -- "${expected}" <<<"${front}" || {
            fail "${path}: frontmatter does not advertise native invocation ${expected}"
            token_errors=1
        }
        prefixed="$(grep -nE '(\$|/|/skill:)('"${SKILL_ALT}"')([^a-z-]|$)' <<<"${body}" || true)"
        if [[ -n "${prefixed}" ]]; then
            fail "${path}: generated body contains a harness invocation prefix instead of a bare skill name:"
            printf '%s\n' "${prefixed}" | head -n 3 | sed 's/^/      /'
            token_errors=1
        fi
    done
done < <(printf '%s\n' "${SKILLS}")

mangled_paths="$(grep -RnoE 'docs/mds[^[:space:]`)]*' "${SKILL_ROOTS[@]}" 2>/dev/null |
                 grep -vF ':docs/mds/stage-workflow/' || true)"
if [[ -n "${mangled_paths}" ]]; then
    fail "docs/mds/ path damaged (a token rewrite hit the directory name):"
    printf '%s\n' "${mangled_paths}" | sed 's/^/      /'
    token_errors=1
fi
(( token_errors == 0 )) && note "frontmatter uses native invocations; shared bodies use bare skill names"

# 8. Harness vocabulary stays native to its tree. The port check proves the full
#    transformation; these markers pin the high-risk question and dispatch tools
#    whose foreign spelling silently degrades a confirmation or fan-out.
section "Harness-specific tool vocabulary"
vocab_errors=0
check_present() { # $1 = tree, $2 = literal native marker
    if ! grep -RqF --include='*.md' -- "$2" "$1" 2>/dev/null; then
        fail "$1 never names its native tool '$2'"
        vocab_errors=1
    fi
}
check_absent_vocab() { # $1 = tree, remaining args = foreign literals
    local tree="$1" literal hits
    shift
    for literal in "$@"; do
        hits="$(grep -RnF --include='*.md' -- "$literal" "$tree" 2>/dev/null || true)"
        if [[ -n "${hits}" ]]; then
            fail "$tree contains foreign tool '$literal':"
            printf '%s\n' "${hits}" | head -n 3 | sed 's/^/      /'
            vocab_errors=1
        fi
    done
}

check_present .claude/skills 'AskUserQuestion'
check_present .claude/skills '`Agent`'
check_absent_vocab .claude/skills 'AskQuestion' 'ask_user_question' 'stage_questionnaire' '`Task`' '`subagent`' '`stage_subagent`'

check_present .cursor/skills 'AskQuestion'
check_present .cursor/skills '`Task`'
check_absent_vocab .cursor/skills 'AskUserQuestion' 'ask_user_question' 'stage_questionnaire' '`Agent`' '`subagent`' '`stage_subagent`'

check_present .dsh/skills 'ask_user_question'
check_present .dsh/skills '`subagent`'
check_absent_vocab .dsh/skills 'AskUserQuestion' 'AskQuestion' 'stage_questionnaire' '`Agent`' '`Task`' '`stage_subagent`'

check_present .kimi-code/skills 'AskUserQuestion'
check_present .kimi-code/skills '`Agent`'
check_absent_vocab .kimi-code/skills 'AskQuestion' 'ask_user_question' 'stage_questionnaire' '`Task`' '`subagent`' '`stage_subagent`'

check_present .pi/skills 'stage_questionnaire'
check_present .pi/skills '`stage_subagent`'
check_absent_vocab .pi/skills 'AskUserQuestion' 'AskQuestion' 'ask_user_question' 'star_questionnaire' 'star_subagent' '`Agent`' '`Task`' '`subagent`'

check_present .qwen/skills '`ask_user_question`'
check_present .qwen/skills '`agent`'
check_absent_vocab .qwen/skills 'AskUserQuestion' 'AskQuestion' 'stage_questionnaire' '`Agent`' '`Task`' '`subagent`' '`stage_subagent`'

check_absent_vocab .agents/skills 'AskUserQuestion' 'AskQuestion' 'ask_user_question' 'stage_questionnaire' 'request_user_input' '`Agent`' '`Task`' '`subagent`' '`stage_subagent`'

for root in .dsh/skills .pi/skills; do
    foreign_types="$(grep -RnE --include='*.md' 'subagent_type|spawn_agent|agent_type' "${root}" 2>/dev/null || true)"
    if [[ -n "${foreign_types}" ]]; then
        fail "${root} names a delegation type its native dispatch tool does not accept:"
        printf '%s\n' "${foreign_types}" | head -n 3 | sed 's/^/      /'
        vocab_errors=1
    fi
done
pi_roster="$(sed -n 's/^name:[[:space:]]*//p' .pi/agents/*.md 2>/dev/null | sort -u)"
pi_unknown="$(grep -RhoE --include='*.md' 'agent: "[a-z0-9-]+"' .pi/skills 2>/dev/null |
              sed 's/.*"\(.*\)"/\1/' | sort -u |
              grep -vxF -f <(printf '%s\n' "${pi_roster}") || true)"
if [[ -n "${pi_unknown}" ]]; then
    fail ".pi/skills dispatches to agent names absent from .pi/agents:"
    printf '%s\n' "${pi_unknown}" | sed 's/^/      /'
    vocab_errors=1
fi
(( vocab_errors == 0 )) && note "each named tree uses its native question and dispatch tools; .agents stays role-based"

# 9. The always-on Cursor rule body stays in sync with AGENTS.md.
#    AGENTS.md: title + blank line, then the shared body.
#    agent-instructions.mdc: 4 frontmatter lines + blank line, then the same body.
section "Cursor rule mirrors AGENTS.md"
CURSOR_RULE=".cursor/rules/agent-instructions.mdc"
if [[ ! -f "${CURSOR_RULE}" ]]; then
    fail "${CURSOR_RULE} is missing"
elif diff <(tail -n +3 AGENTS.md) <(tail -n +6 "${CURSOR_RULE}") > /dev/null; then
    note "${CURSOR_RULE} matches the AGENTS.md body"
else
    fail "${CURSOR_RULE} has drifted from AGENTS.md:"
    diff <(tail -n +3 AGENTS.md) <(tail -n +6 "${CURSOR_RULE}") | sed 's/^/      /'
fi

# 10. Frontmatter descriptions stay inside the SKILL.md spec limit, in every
#     tree. The limit is 1024 *characters* and it is not one harness's quirk:
#     the agentskills.io SKILL.md spec, Anthropic's Agent Skills docs and the
#     Kimi CLI docs all state 1-1024 for `description`.
#       - Characters, not bytes. These descriptions carry §, — and →, so bytes
#         run past characters and a byte check at 1024 rejects valid files.
#         awk's length() is bytes on BWK awk, so the count goes through perl.
#       - The folded-block indicator is not part of the value: leaving ">-" in
#         the measured text inflates every folded file by 3.
#     A description says what the skill does, when it applies, and the
#     exclusions that prevent likely misrouting; mode syntax, procedures and
#     output shapes belong in the body. This bound and the DSH one below are
#     ceilings, not targets. When a description is shortened to fit, cut
#     detail, never a guarantee about what the skill will not do: a "never", a
#     read-only boundary, a venue fact only the user may confirm. Frontmatter is
#     hand-maintained per tree (port.sh does not generate it), so a shared change
#     edits all seven copies, each keeping its own invocation token (check 7)
#     and its other fields.
section "Description length (<= ${DESC_MAX:=1024} characters, SKILL.md spec)"
desc_errors=0
while IFS= read -r manifest; do
    len="$(awk '
        NR == 1 && /^---[ \t]*$/ { fm = 1; next }
        fm && /^---[ \t]*$/ { exit }
        fm && /^description:/ { grab = 1; sub(/^description:[ \t]*/, ""); sub(/^[>|][-+]?[ \t]*$/, "") }
        fm && grab && /^[A-Za-z_-]+:/ && !/^description:/ { exit }
        grab { gsub(/^[ \t]+|[ \t]+$/, ""); if (length($0)) body = body (length(body) ? " " : "") $0 }
        END { print body }
    ' "${manifest}" | perl -CSD -Mutf8 -ne 'chomp; $n += length; END { print $n + 0 }')"
    if (( len > DESC_MAX )); then
        fail "${manifest}: description is ${len} characters, over the ${DESC_MAX}-character SKILL.md limit"
        desc_errors=1
    fi
done < <(find -L "${SKILL_ROOTS[@]}" -name 'SKILL.md' | sort)
(( desc_errors == 0 )) && note "all descriptions within ${DESC_MAX} characters in all seven trees"

#     DSH is stricter than the spec and silent about it. Its model-facing catalog
#     renders `description` through catalogDescriptionMaxLength, default 500, and
#     over that it keeps the first 497 characters and appends "..." — no warning,
#     no log line. A STAGE description closes on its "Use when ..." routing
#     clause and the guarantees after it, so truncation removes exactly what
#     the model matches on and what keeps it from misusing the skill.
#     /skill: makes the .dsh copy of each shared description (and Kimi's, which
#     shares the token) the longest. Only .agents' figs-designer text, which
#     alone carries the image_gen/PPTX pipeline (check 19), runs longer, and DSH
#     reads .dsh/skills ahead of .agents/skills, so this is the bound that binds.
section "Description length in .dsh (<= ${DSH_DESC_MAX:=500}, DSH catalog bound)"
dsh_desc_errors=0
while IFS= read -r manifest; do
    len="$(awk '
        NR == 1 && /^---[ \t]*$/ { fm = 1; next }
        fm && /^---[ \t]*$/ { exit }
        fm && /^description:/ { grab = 1; sub(/^description:[ \t]*/, ""); sub(/^[>|][-+]?[ \t]*$/, "") }
        fm && grab && /^[A-Za-z_-]+:/ && !/^description:/ { exit }
        grab { gsub(/^[ \t]+|[ \t]+$/, ""); if (length($0)) body = body (length(body) ? " " : "") $0 }
        END { print body }
    ' "${manifest}" | perl -CSD -Mutf8 -ne 'chomp; $n += length; END { print $n + 0 }')"
    if (( len > DSH_DESC_MAX )); then
        fail "${manifest}: description is ${len} characters; DSH truncates its catalog at ${DSH_DESC_MAX}, cutting its closing clause"
        dsh_desc_errors=1
    fi
done < <(find -L .dsh/skills -name 'SKILL.md' | sort)
(( dsh_desc_errors == 0 )) && note "every .dsh description survives DSH's ${DSH_DESC_MAX}-character catalog intact"

# 11. Heading structure matches across the six named trees.
#     Checks 1-3 compare file *sets*; nothing above compares what is inside
#     them, so a step could be dropped from one tree, or reordered, and every
#     check passed.
#
#     Normalization: a heading is truncated at its first "(" or "（" and
#     stripped of backticks, so harness vocabulary inside a heading is free to
#     differ. What remains must match exactly.
#
#     .agents is excluded on purpose: neutral role wording can change a heading
#     where the parenthesis rule does not reach. Check 12 holds its ## shape.
section "Heading structure (six named harness trees)"
norm_headings() { # $1 = file; prints one normalized heading per line
    awk '
        /^#/ {
            n = 0
            while (substr($0, n + 1, 1) == "#") n++
            if (n < 2 || n > 4) next
            if (substr($0, n + 1, 1) != " ") next
            line = $0
            p = index(line, "(")
            q = index(line, "（")
            if (q > 0 && (p == 0 || q < p)) p = q
            if (p > 0) line = substr(line, 1, p - 1)
            gsub(/`/, "", line)
            gsub(/[ \t]+/, " ", line)
            sub(/^ +/, "", line)
            sub(/ +$/, "", line)
            print tolower(line)
        }
    ' "$1"
}
struct_errors=0
struct_files=0
while IFS= read -r rel; do
    struct_files=$(( struct_files + 1 ))
    for root in .cursor/skills .dsh/skills .kimi-code/skills .pi/skills .qwen/skills; do
        other="${root}/${rel}"
        [[ -f "${other}" ]] || continue   # inventory parity is check 3's job
        if ! diff -q <(norm_headings ".claude/skills/${rel}") <(norm_headings "${other}") > /dev/null; then
            fail "${other}: heading structure differs from .claude/skills/${rel}:"
            diff <(norm_headings ".claude/skills/${rel}") <(norm_headings "${other}") | sed 's/^/      /'
            struct_errors=1
        fi
    done
done < <(cd .claude/skills && find -L . -type f -name '*.md' | sed 's|^\./||' | sort)
(( struct_errors == 0 )) && note "heading structure matches across all six named trees (${struct_files} files)"

# 12. Top-level section parity between the authored source and Claude manifests.
#     A SKILL.md's ## sections are its shape, not its wording — Role, Core
#     Principles, Workflow, State & File Rules, Dialogue Discipline — and those
#     are shared. Manifests only, and the SET rather than the sequence, so
#     ordering and every adaptation below ## stay free.
section "Manifest section parity (.agents vs .claude)"
norm_sections() { # $1 = file; prints the file's normalized ## headings, sorted unique
    awk '
        /^## / {
            line = $0
            p = index(line, "(")
            q = index(line, "（")
            if (q > 0 && (p == 0 || q < p)) p = q
            if (p > 0) line = substr(line, 1, p - 1)
            gsub(/`/, "", line)
            gsub(/[ \t]+/, " ", line)
            sub(/^ +/, "", line)
            sub(/ +$/, "", line)
            print tolower(line)
        }
    ' "$1" | sort -u
}
section_errors=0
while IFS= read -r skill; do
    baseline=".agents/skills/${skill}/SKILL.md"
    other=".claude/skills/${skill}/SKILL.md"
    [[ -f "${baseline}" && -f "${other}" ]] || continue   # checks 2 and 3 own missing files
    if ! diff -q <(norm_sections "${baseline}") <(norm_sections "${other}") > /dev/null; then
        fail "${other}: ## sections differ from ${baseline}:"
        diff <(norm_sections "${baseline}") <(norm_sections "${other}") | sed 's/^/      /'
        section_errors=1
    fi
done < <(printf '%s\n' "${SKILLS}")
(( section_errors == 0 )) && note ".claude manifests carry the same ## sections as the authored .agents source"

# 13. Every manifest carries one Shared conventions paragraph naming the shared
#     .env controls — STAGE_LANG under conventions §7.6, INVOLVE under §7.7 —
#     and prescribes no tool-call itinerary: which reader, how many calls and
#     what output budget are the host's. A manifest that drops the paragraph,
#     or never names .env, STAGE_LANG or INVOLVE, runs without the controls
#     every other skill resolves.
section "Shared environment and language controls"
control_errors=0
for root in "${SKILL_ROOTS[@]}"; do
    while IFS= read -r skill; do
        path="${root}/${skill}/SKILL.md"
        [[ -f "${path}" ]] || continue   # check 2 owns missing files

        n="$(grep -cE '^\*\*Shared conventions\.' "${path}")"
        (( n == 1 )) || { fail "${path}: ${n} shared-conventions paragraphs, expected exactly 1"; control_errors=1; }
        for key in .env STAGE_LANG INVOLVE '§7.6' '§7.7'; do
            if ! grep -Fq -- "${key}" "${path}"; then
                fail "${path}: missing shared environment control ${key}"
                control_errors=1
            fi
        done
    done < <(printf '%s\n' "${SKILLS}")
done
(( control_errors == 0 )) && note "all manifests carry one Shared conventions paragraph naming .env, STAGE_LANG and INVOLVE under §7.6 and §7.7"

# 14. The conventions document's numbered structure is pinned, and every
#     citation of it resolves.
#     Skills cite this file at sub-section granularity — §7.6, §8.2, §9a — so
#     renumbering a section, or inserting an item into the middle of one,
#     silently repoints every citation after it. Item counts are pinned for the
#     sections that have items; §9's lettered rules are pinned by count too,
#     because §9a-§9e are the fabrication boundary and are cited by letter.
section "Conventions document structure"
CONV_HEADINGS=(
    '0. Vocabulary'
    '1. Git'
    '2. The STOP line'
    '3. `.env` and the build toolchain'
    '4. Real dates'
    '5. Manuscript, section, and cycle resolution'
    '6. Delegation'
    '7. Dialogue'
    '8. The output table'
    '9. The fabrication boundary'
    '10. Project layout'
    '11. The skill roster'
    '12. Project memory'
    '13. Harness hooks and model provenance'
)
# section|numbered top-level items
CONV_ITEMS=("1|6" "3|7" "4|4" "5|6" "6|9" "7|13" "10|5" "11|5")
CONV_SUBHEADS=("8|11")    # ### 8.n subheadings
CONV_LETTERS=("9|5")      # **(a) ... **(e) rules

# Every parser below skips fenced code blocks. §8.2 documents the manifest
# schema by example, and that example is a Markdown file whose entries are `##`
# headings — so a naive scan reads `## <slug>/metds/overview.md` as a section of
# the conventions, ends §8 there, and undercounts everything after it.
CONV_AWK_PRELUDE='/^```/ { fence = !fence; next } fence { next }'

conv_headings() { # $1 = file -> the document's ## headings, fences excluded
    awk "${CONV_AWK_PRELUDE}"' /^## / { sub(/^## /, ""); print }' "$1"
}
conv_items() { # $1 = file, $2 = section number -> top-level numbered items in it
    awk -v want="$2" "${CONV_AWK_PRELUDE}"'
        /^## / { n = $2; sub(/\./, "", n); insec = (n == want) }
        insec && /^[0-9]+\. / { c++ }
        END { print c + 0 }
    ' "$1"
}
conv_subheads() { # $1 = file, $2 = section number -> ### n.m subheadings in it
    awk -v want="$2" "${CONV_AWK_PRELUDE}"'
        /^## / { n = $2; sub(/\./, "", n); insec = (n == want) }
        insec && $0 ~ ("^### " want "\\.") { c++ }
        END { print c + 0 }
    ' "$1"
}
conv_letters() { # $1 = file, $2 = section number -> lettered rules in it
    awk -v want="$2" "${CONV_AWK_PRELUDE}"'
        /^## / { n = $2; sub(/\./, "", n); insec = (n == want) }
        insec && /^\*\*\([a-z]\)/ { c++ }
        END { print c + 0 }
    ' "$1"
}

conv_errors=0
expected_conv="$(printf '%s\n' "${CONV_HEADINGS[@]}")"
actual_conv="$(conv_headings "${CONV_EN}")"
if [[ "${expected_conv}" != "${actual_conv}" ]]; then
    fail "${CONV_EN} headings changed; skills cite this file as §n and §n.m. Re-audit the citations, then update CONV_HEADINGS in this script:"
    diff <(printf '%s\n' "${expected_conv}") <(printf '%s\n' "${actual_conv}") | sed 's/^/      /'
    conv_errors=1
fi
for spec in "items:${CONV_ITEMS[*]}" "subheads:${CONV_SUBHEADS[*]}" "letters:${CONV_LETTERS[*]}"; do
    kind="${spec%%:*}"
    for row in ${spec#*:}; do
        sec="${row%%|*}"
        want="${row#*|}"
        got="$(conv_${kind} "${CONV_EN}" "${sec}")"
        if [[ "${got}" != "${want}" ]]; then
            fail "${CONV_EN}: §${sec} carries ${got} ${kind}, pinned at ${want} — every §${sec}.n citation past the change now points elsewhere"
            conv_errors=1
        fi
    done
done

# Every citation resolves: the section exists, and the sub-item it names does too.
CITATION_SCAN=("${SKILL_ROOTS[@]}" docs/mds/stage-workflow AGENTS.md README.md README.zh-CN.md)
cite_checked=0
while IFS= read -r cite; do
    [[ -n "${cite}" ]] || continue
    cite_checked=$(( cite_checked + 1 ))
    c_sec="${cite%%.*}"
    c_item=""
    [[ "${cite}" == *.* ]] && c_item="${cite#*.}"
    if (( c_sec > 13 )); then
        fail "conventions §${cite} is cited, but the document has no §${c_sec}"
        conv_errors=1
        continue
    fi
    [[ -n "${c_item}" ]] || continue
    for row in "${CONV_ITEMS[@]}" "${CONV_SUBHEADS[@]}"; do
        [[ "${row%%|*}" == "${c_sec}" ]] || continue
        if (( c_item > ${row#*|} )); then
            fail "conventions §${cite} is cited, but §${c_sec} has only ${row#*|} items"
            conv_errors=1
        fi
    done
done < <(grep -rhoE '(conventions|规约) §[0-9]+(\.[0-9]+)?' "${CITATION_SCAN[@]}" 2>/dev/null |
         grep -oE '[0-9]+(\.[0-9]+)?' | sort -u)
(( conv_errors == 0 )) && note "conventions structure pinned; ${cite_checked} distinct §n citations resolve"

# 15. The docs stay tied to the skills they describe.
#     Two thirds of the skills guide paraphrases the fifteen SKILL.md files,
#     which are authoritative and change far more often; a skill added, removed,
#     or renamed leaves the guide and the landing pages describing a workflow
#     that no longer exists.
section "Docs cover every skill"
doc_errors=0
for guide in docs/mds/stage-workflow/writing-workflow-skills.md \
             docs/mds/stage-workflow/writing-workflow-skills.zh-CN.md \
             "${CONV_EN}" \
             README.md README.zh-CN.md; do
    [[ -f "${guide}" ]] || { fail "${guide} is missing"; doc_errors=1; continue; }
    while IFS= read -r skill; do
        # The name must end where the skill's name ends: a plain substring match
        # would accept `stage-clms-auditorx` as a mention of `stage-clms-auditor`.
        grep -qE "${skill}([^A-Za-z0-9_-]|\$)" "${guide}" || {
            fail "${guide} never names ${skill} — a skill was added or renamed without the docs"
            doc_errors=1
        }
    done < <(printf '%s\n' "${SKILLS}")
done

# The workflow docs are English, apart from the skills guide, which ships as an
# en/zh pair. The workflow reads only the English docs, so no other Chinese
# edition may come back, here or beside the agent instructions.
ZH_DOC_PAIRS=(docs/mds/stage-workflow/writing-workflow-skills)
for base in "${ZH_DOC_PAIRS[@]}"; do
    for f in "${base}.md" "${base}.zh-CN.md"; do
        [[ -f "${f}" ]] || { fail "${f} is missing; the skills guide ships as an en/zh pair"; doc_errors=1; }
    done
done
while IFS= read -r f; do
    [[ -f "${f%.zh-CN.md}.md" ]] || { fail "${f} has no English counterpart"; doc_errors=1; }
    if [[ " ${ZH_DOC_PAIRS[*]} " != *" ${f%.zh-CN.md} "* ]]; then
        fail "${f}: only the skills guide has a Chinese edition among the workflow docs"
        doc_errors=1
    fi
done < <(find docs/mds/stage-workflow -name '*.zh-CN.md' | sort)
for f in AGENTS.zh-CN.md CLAUDE.zh-CN.md; do
    if [[ -e "${f}" || -L "${f}" ]]; then
        fail "${f}: STAGE ships no Chinese edition of this file; the English one is the only copy"
        doc_errors=1
    fi
done

# Every relative link in the guides resolves.
for guide in docs/mds/stage-workflow/writing-workflow-skills.md \
             docs/mds/stage-workflow/writing-workflow-skills.zh-CN.md \
             README.md README.zh-CN.md; do
    [[ -f "${guide}" ]] || continue
    while IFS= read -r target; do
        [[ -n "${target}" ]] || continue
        if [[ ! -e "$(dirname "${guide}")/${target}" ]]; then
            fail "${guide}: link target ${target} does not exist"
            doc_errors=1
        fi
    done < <(grep -oE '\]\([^)#][^)]*\)' "${guide}" | sed 's/^](//; s/)$//; s/#.*$//' |
             grep -vE '^(https?|mailto):' | grep -v '^$' | sort -u)
done
(( doc_errors == 0 )) && note "guides and landing pages name every skill; only the skills guide is paired en/zh, and no retired Chinese edition is back; links resolve"

# 16. Chinese text carries no space between two Chinese characters.
#     Chinese is written in reference files, the skills guide,
#     README.zh-CN.md and the landing pages, where only a
#     hand-typed space can land between two Chinese characters. The scan is Han
#     and CJK punctuation only. A Chinese character beside a *symbol* is correct
#     typography and stays free — 规约 §9, 评审意见 → 要点记录表, 陈述处 ⇄ 证据,
#     标 † 的五个, "# 2 · 配置", 回到顶部 ↑, the box-drawing rules in the workflow
#     diagram, and "——" spaced on both sides.
#     One exception, and it is a real one: 中文要点摘要 is a section title, and
#     the spaces around it set it off from the sentence carrying it, the way
#     backticks would in English. Both spaces must be there — a title that lost
#     one is a typo the scan should still catch — so the pair is dropped before
#     matching rather than the pattern being loosened.
section "Chinese spacing (reference files, zh docs)"
zh_space_errors=0
while IFS= read -r zhfile; do
    while IFS= read -r hit; do
        [[ -n "${hit}" ]] || continue
        fail "${zhfile}:${hit} — space between two Chinese characters"
        zh_space_errors=1
    done < <(perl -CSD -Mutf8 -ne '
        BEGIN { $CJK = qr/[\p{Han}\p{Block=CJK_Symbols_and_Punctuation}\p{Block=Halfwidth_and_Fullwidth_Forms}]/ }
        my $line = $_;
        $line =~ s/ 中文要点摘要 //g;
        print "$.: $&\n" while $line =~ /$CJK $CJK/g;
    ' "${zhfile}")
done < <(find . -path ./.git -prune -o -path ./wkdrs -prune -o \
              \( -name '*_zh.md' -o -name '*.zh-CN.md' -o -name '*_zh.html' \) -print |
         sed 's|^\./||' | sort)
(( zh_space_errors == 0 )) && note "no space inside a word in any Chinese file"

# 17. Hooks exist, parse, and are registered through each harness's native path.
section "Hooks"
hook_errors=0
for f in .claude/hooks/stage_model_id.sh .codex/hooks/stage_model_id.sh \
         .cursor/hooks/stage_model_id.sh .dsh/hooks/stage_model_id.sh \
         .kimi-code/hooks/stage_model_id.sh .pi/extensions/stage-hooks/stage_model_id.sh \
         .qwen/hooks/stage_model_id.sh \
         .claude/hooks/stage_memory.sh .codex/hooks/stage_memory.sh \
         .cursor/hooks/stage_memory.sh .dsh/hooks/stage_memory.sh \
         .kimi-code/hooks/stage_memory.sh .pi/extensions/stage-hooks/stage_memory.sh \
         .qwen/hooks/stage_memory.sh \
         .claude/hooks/stage_commit_guard.sh .codex/hooks/stage_commit_guard.sh \
         .cursor/hooks/stage_commit_guard.sh .dsh/hooks/stage_commit_guard.sh \
         .kimi-code/hooks/stage_commit_guard.sh .pi/extensions/stage-hooks/stage_commit_guard.sh \
         .qwen/hooks/stage_commit_guard.sh \
         .claude/hooks/stage_involve_gate.sh .claude/hooks/stage_involve_level.sh \
         .claude/hooks/stage_bash_gate.sh \
         .codex/hooks/stage_involve_gate.sh .qwen/hooks/stage_involve_gate.sh \
         .dsh/hooks/install.sh .kimi-code/hooks/install.sh; do
    [[ -x "${f}" ]] || { fail "${f} is missing or not executable"; hook_errors=1; }
    [[ -f "${f}" ]] && ! bash -n "${f}" 2>/dev/null && { fail "${f} does not parse"; hook_errors=1; }
done

for f in .claude/settings.json .codex/hooks.json .cursor/hooks.json .dsh/hooks.json \
         .kimi-code/hooks.example.toml .pi/extensions/stage-hooks/index.ts .qwen/settings.json; do
    [[ -f "${f}" ]] || { fail "${f} is missing"; hook_errors=1; continue; }
    for hook in stage_model_id.sh stage_memory.sh stage_commit_guard.sh; do
        grep -qF "${hook}" "${f}" || { fail "${f} does not register ${hook}"; hook_errors=1; }
    done
done

for hook in stage_model_id.sh stage_memory.sh stage_commit_guard.sh; do
    grep -qF "${hook}" .kimi-code/hooks/install.sh || \
        { fail ".kimi-code/hooks/install.sh does not install ${hook}"; hook_errors=1; }
done
for literal in '@deepseek-ai/dsh-hooks-claude-code' './.dsh/hooks.json'; do
    for f in .dsh/hooks/install.sh .dsh/cordis.patch.yml; do
        grep -qF -- "${literal}" "${f}" || { fail "${f} no longer names ${literal}"; hook_errors=1; }
    done
done

for f in .claude/hooks/stage_commit_guard.sh .codex/hooks/stage_commit_guard.sh \
         .dsh/hooks/stage_commit_guard.sh .qwen/hooks/stage_commit_guard.sh; do
    grep -qF '"hookEventName":"PreToolUse","permissionDecision":"deny"' "${f}" || \
        { fail "${f} no longer emits a PreToolUse deny decision"; hook_errors=1; }
done
grep -qF '"hookSpecificOutput":{"permissionDecision":"deny"' .kimi-code/hooks/stage_commit_guard.sh || \
    { fail ".kimi-code/hooks/stage_commit_guard.sh no longer emits Kimi's deny shape"; hook_errors=1; }
{ grep -qF '"permission":"deny"' .cursor/hooks/stage_commit_guard.sh && grep -qF 'exit 2' .cursor/hooks/stage_commit_guard.sh; } || \
    { fail ".cursor/hooks/stage_commit_guard.sh lost its deny permission or exit 2"; hook_errors=1; }
{ grep -qF 'exit 1' .pi/extensions/stage-hooks/stage_commit_guard.sh && \
  grep -qF 'block: true' .pi/extensions/stage-hooks/index.ts; } || \
    { fail ".pi stage hook extension no longer blocks a declined shell command"; hook_errors=1; }
grep -qE '"matcher"[[:space:]]*:[[:space:]]*"bash"' .dsh/hooks.json || \
    { fail ".dsh/hooks.json no longer matches DSH's lowercase bash tool"; hook_errors=1; }
#     The memory index's field separator — space, middle dot, space — is what all
#     seven memory hooks build their lines with, and what conventions §12 documents as
#     the shape a session reads. Reword it in one place and the hooks and §12
#     describe two different lines.
for f in .claude/hooks/stage_memory.sh .codex/hooks/stage_memory.sh \
         .cursor/hooks/stage_memory.sh .kimi-code/hooks/stage_memory.sh \
         .dsh/hooks/stage_memory.sh .pi/extensions/stage-hooks/stage_memory.sh \
         .qwen/hooks/stage_memory.sh "${CONV_EN}"; do
    grep -qF ' · ' "${f}" 2>/dev/null || \
        { fail "${f} no longer carries the memory index separator ' · '"; hook_errors=1; }
done
#     The aging rule is copied the same way: every memory hook carries both date
#     spellings of the 180-day cutoff (BSD and GNU) and gates the stale mark on
#     the literal type `env` read from the frontmatter, and §12 states the
#     same window. Change one copy and the others keep answering for a rule the
#     store no longer follows.
for f in .claude/hooks/stage_memory.sh .codex/hooks/stage_memory.sh \
         .cursor/hooks/stage_memory.sh .kimi-code/hooks/stage_memory.sh \
         .dsh/hooks/stage_memory.sh .pi/extensions/stage-hooks/stage_memory.sh \
         .qwen/hooks/stage_memory.sh; do
    { grep -qF -- '-v-180d' "${f}" && grep -qF '180 days ago' "${f}"; } || \
        { fail "${f} lost a spelling of the 180-day cutoff (-v-180d / '180 days ago')"; hook_errors=1; }
    grep -qF 'f["type"] == "env"' "${f}" || \
        { fail "${f} no longer gates the stale mark on the literal type env"; hook_errors=1; }
done
grep -qF '180 days' "${CONV_EN}" || \
    { fail "conventions §12 (project memory) no longer states the 180-day aging window"; hook_errors=1; }
#     What the awk does is shown, not read: every copy is run at its own depth
#     against one store of three memories — an aged `env`, a `deadend` of the
#     same date, and a legacy file with no `summary:` — and has to list all three
#     and mark exactly one, so a copy whose parsing breaks fails here rather than
#     silently injecting nothing into every session of that harness.
memory_fixture="$(mktemp -d "${TMPDIR:-/tmp}/stage-memory-fixture.XXXXXX")" || {
    fail "could not create the memory-hook fixture directory"
    hook_errors=1
    memory_fixture=""
}
if [[ -n "${memory_fixture}" ]]; then
    mkdir -p "${memory_fixture}/.stage/memory/local"
    printf -- '---\ntype: env\nscope: machine:box\nsummary: stage.cls builds here only under xelatex\nverified: 2025-01-01\n---\nbody\n' > "${memory_fixture}/.stage/memory/xelatex-only.md"
    printf -- '---\ntype: deadend\nscope: cycle:demo_2026\nsummary: the benchmark framing read as incremental\nverified: 2025-01-01\n---\nbody\n' > "${memory_fixture}/.stage/memory/benchmark-framing.md"
    printf -- '---\ntype: pref\nscope: global\nverified: 2026-09-01\n---\n\nThe first body line stands in.\n' > "${memory_fixture}/.stage/memory/local/legacy.md"
    for f in .claude/hooks/stage_memory.sh .codex/hooks/stage_memory.sh \
             .cursor/hooks/stage_memory.sh .kimi-code/hooks/stage_memory.sh \
             .dsh/hooks/stage_memory.sh .pi/extensions/stage-hooks/stage_memory.sh \
             .qwen/hooks/stage_memory.sh; do
        mkdir -p "${memory_fixture}/$(dirname "${f}")"
        cp "${f}" "${memory_fixture}/${f}"
        listed="$(bash "${memory_fixture}/${f}" --list </dev/null 2>/dev/null)"
        if [[ "$(grep -c '^- ' <<< "${listed}")" != 3 || "$(grep -c '\[stale:' <<< "${listed}")" != 1 || "${listed}" != *"— The first body line stands in."* ]]; then
            fail "${f} --list does not index the fixture store (3 lines, 1 stale mark, legacy summary from the body):"
            printf '%s\n' "${listed:-<nothing>}" | sed 's/^/      /'
            hook_errors=1
        fi
    done
    rm -rf "${memory_fixture}"
fi

# The commit guard's rule body — everything from the segment loop down — is one
# decision table in seven copies; only the prelude (event wiring, payload
# parsing, deny encoding, project-root depth) may differ per tree. Existence and
# parse checks cannot see a tree enforcing someone else's rules: three trees
# once shipped a guard with no freeze-tag protection and another repository's
# § numbers, and every check above stayed green. Byte parity over the extracted
# span is what catches that, and the freeze-tag marker pins the one rule whose
# loss is a silent hole even if the baseline itself is edited.
guard_rules() { sed -n '/^while IFS= read -r segment; do$/,$p' "$1"; }
GUARD_BASE="$(guard_rules .claude/hooks/stage_commit_guard.sh)"
if [[ -z "${GUARD_BASE}" ]]; then
    fail ".claude/hooks/stage_commit_guard.sh: rule body not found (segment loop missing)"
    hook_errors=1
fi
for f in .codex/hooks/stage_commit_guard.sh .cursor/hooks/stage_commit_guard.sh \
         .dsh/hooks/stage_commit_guard.sh .kimi-code/hooks/stage_commit_guard.sh \
         .pi/extensions/stage-hooks/stage_commit_guard.sh .qwen/hooks/stage_commit_guard.sh; do
    if [[ "$(guard_rules "${f}")" != "${GUARD_BASE}" ]]; then
        fail "${f}: commit-guard rule body differs from .claude's — the seven copies decline the same commands, and only the prelude adapts per harness"
        hook_errors=1
    fi
done
for f in .claude/hooks/stage_commit_guard.sh .codex/hooks/stage_commit_guard.sh \
         .cursor/hooks/stage_commit_guard.sh .dsh/hooks/stage_commit_guard.sh \
         .kimi-code/hooks/stage_commit_guard.sh .pi/extensions/stage-hooks/stage_commit_guard.sh \
         .qwen/hooks/stage_commit_guard.sh; do
    grep -qF 'a freeze tag is the immutable record of what was submitted' "${f}" || \
        { fail "${f}: freeze-tag protection (conventions §1.4) is missing from the commit guard"; hook_errors=1; }
done

for f in .claude/settings.json .codex/hooks.json .qwen/settings.json; do
    grep -qF stage_involve_gate.sh "${f}" || { fail "${f} does not register stage_involve_gate.sh"; hook_errors=1; }
done
for f in .claude/hooks/stage_involve_gate.sh .codex/hooks/stage_involve_gate.sh .qwen/hooks/stage_involve_gate.sh; do
    grep -qF '"${involve}" == "low"' "${f}" || { fail "${f} no longer gates on involve=low"; hook_errors=1; }
    grep -qF 'mates/*' "${f}" || { fail "${f} no longer keeps the prompt for mates/"; hook_errors=1; }
done
# Claude's gate takes the level from the shared resolver, so an invocation's
# involve= token reaches it (conventions §7.7); a gate back on .env alone drops it.
grep -qF 'involve="$(stage_involve_level "${input}" "${root}")"' .claude/hooks/stage_involve_gate.sh || \
    { fail ".claude/hooks/stage_involve_gate.sh no longer takes its level from stage_involve_level.sh"; hook_errors=1; }

# Claude's bash gate answers a shell prompt at involve=low and stays silent on
# STAGE's red lines (conventions §7.7). Fixed commands pin both halves: the
# mates/, kit, .env, tlmgr, tracked-overwrite, and outward-send arms, and the
# reading of a wrapper's option values, backticks, continuations, and a commit
# message's heredoc, are STAGE's own and absent from STAR's gate, so a re-port
# could drop them with every existence check above still green. A case reads
# through %b, so \n in it is a newline.
grep -qF stage_bash_gate.sh .claude/settings.json || \
    { fail ".claude/settings.json does not register stage_bash_gate.sh"; hook_errors=1; }
grep -qF 'involve="$(stage_involve_level "${input}" "${root}")"' .claude/hooks/stage_bash_gate.sh || \
    { fail ".claude/hooks/stage_bash_gate.sh no longer takes its level from stage_involve_level.sh"; hook_errors=1; }
gate_dir="$(mktemp -d "${TMPDIR:-/tmp}/stage-bash-gate-check.XXXXXX")" || {
    fail "could not create the bash-gate check fixture directory"
    hook_errors=1
    gate_dir=""
}
if [[ -n "${gate_dir}" ]]; then
    printf 'INVOLVE=low\n' > "${gate_dir}/.env"
    mkdir -p "${gate_dir}/notes"
    printf 'x\n' > "${gate_dir}/notes/claims.md"
    git -C "${gate_dir}" init -q && git -C "${gate_dir}" add notes/claims.md
    gate_verdict() { # $1 = shell command; prints allow, prompt, or what came back
        local out
        out="$(python3 -c 'import json, sys; print(json.dumps({"tool_name": "Bash", "tool_input": {"command": sys.argv[1]}, "cwd": sys.argv[2]}))' "$1" "${gate_dir}" \
            | CLAUDE_PROJECT_DIR="${gate_dir}" bash .claude/hooks/stage_bash_gate.sh 2>&1)"
        if [[ "${out}" == *'"permissionDecision":"allow"'* ]]; then printf 'allow'
        elif [[ -z "${out}" ]]; then printf 'prompt'
        else printf '%s' "${out}"; fi
    }
    gate_errors=0
    while IFS='|' read -r gate_want gate_cmd; do
        gate_cmd="$(printf '%b' "${gate_cmd}")"
        gate_got="$(gate_verdict "${gate_cmd}")"
        [[ "${gate_got}" == "${gate_want}" ]] || \
            { fail "stage_bash_gate.sh: expected ${gate_want}, got ${gate_got}, for: ${gate_cmd}"; gate_errors=1; hook_errors=1; }
    done <<'CASES'
allow|bash execs/scpts/lint.sh && git add notes/claims.md
allow|grep -c acc mates/MANIFEST.md
allow|bash execs/scpts/import.sh --source ../proj
allow|curl -LH "Accept: application/x-bibtex" https://doi.org/10.1000/x
allow|git commit -m "$(cat <<'EOF'\nfix: read INVOLVE from .env\nEOF\n)"
prompt|rm -f wkdrs/builds/main.pdf
prompt|ls wkdrs/*.log | xargs -I {} rm {}
prompt|echo `rm -rf manus`
prompt|git \\\n  push origin main
prompt|git push
prompt|git clean -fdx
prompt|git tag freeze/neurips_2026_2026-09-23
prompt|cp results.csv mates/manual/results.csv
prompt|unzip kit.zip -d cycls/neurips_2026/template
prompt|echo INVOLVE=low >> .env
prompt|tlmgr install booktabs
prompt|cp draft.md notes/claims.md
prompt|curl -sL https://x -o notes/claims.md
prompt|scp main.pdf host:/tmp/
CASES
    (( gate_errors == 0 )) && note "bash gate allows ordinary commands at involve=low and leaves STAGE's red lines to the prompt"
    rm -rf "${gate_dir}"
fi

for f in .claude/hooks/stage_model_id.sh .codex/hooks/stage_model_id.sh \
         .cursor/hooks/stage_model_id.sh .dsh/hooks/stage_model_id.sh \
         .kimi-code/hooks/stage_model_id.sh .pi/extensions/stage-hooks/stage_model_id.sh \
         .qwen/hooks/stage_model_id.sh; do
    grep -qF 'writing-workflow-conventions section 8' "${f}" 2>/dev/null || \
        { fail "${f} no longer points at writing-workflow-conventions section 8"; hook_errors=1; }
done
grep -qF 'stage_model_id.sh --check' "${CONV_EN}" || \
    { fail "conventions §13 (harness hooks) no longer spells the Codex post-write check"; hook_errors=1; }

#     Codex closes provenance with a write-after check. Four cases pin its
#     precedence, its failure boundary, and that it expects exactly what the
#     resolver told the skill to write; more cases would duplicate the
#     resolver's own simple contract rather than protect another behavior.
model_check_dir="$(mktemp -d "${TMPDIR:-/tmp}/stage-model-id-check.XXXXXX")" || {
    fail "could not create the model-id check fixture directory"
    hook_errors=1
    model_check_dir=""
}
if [[ -n "${model_check_dir}" ]]; then
    model_rollout="${model_check_dir}/rollout.jsonl"
    model_artifact="${model_check_dir}/report.md"
    printf '%s\n' '{"type":"turn_context","payload":{"model":"gpt-5.6-sol"}}' > "${model_rollout}"

    # 1. Exact rollout, degraded artifact: must fail.
    printf '%s\n' '---' 'model_id: gpt-5' '---' > "${model_artifact}"
    model_check_output="$(bash .codex/hooks/stage_model_id.sh --check \
        "${model_artifact}" "${model_rollout}" "gpt-5.6-sol" 2>&1)"
    model_check_rc=$?
    if (( model_check_rc == 0 )); then
        fail "model-id check accepted gpt-5 against rollout gpt-5.6-sol"
        hook_errors=1
    elif ! grep -qF "expected 'gpt-5.6-sol', found 'gpt-5'" <<< "${model_check_output}"; then
        fail "model-id mismatch failed without the expected diagnostic: ${model_check_output}"
        hook_errors=1
    else
        note "model-id check rejects gpt-5 against rollout gpt-5.6-sol"
    fi

    # 2. Exact rollout, exact artifact: must pass.
    printf '%s\n' '---' 'model_id: gpt-5.6-sol' '---' > "${model_artifact}"
    if bash .codex/hooks/stage_model_id.sh --check \
        "${model_artifact}" "${model_rollout}" "gpt-5.6-sol"; then
        note "model-id check accepts gpt-5.6-sol against rollout gpt-5.6-sol"
    else
        fail "model-id check rejected gpt-5.6-sol against rollout gpt-5.6-sol"
        hook_errors=1
    fi

    # 3. No rollout and no SessionStart model: unrecorded must pass.
    printf '%s\n' '---' 'model_id: unrecorded' '---' > "${model_artifact}"
    if bash .codex/hooks/stage_model_id.sh --check "${model_artifact}" "" ""; then
        note "model-id check accepts unrecorded when rollout and session model are absent"
    else
        fail "model-id check rejected unrecorded with no rollout or session model"
        hook_errors=1
    fi

    # 4. The session model keeps a suffix the rollout drops, as --resolve does.
    printf '%s\n' '---' 'model_id: gpt-5.6-sol[1m]' '---' > "${model_artifact}"
    if bash .codex/hooks/stage_model_id.sh --check \
        "${model_artifact}" "${model_rollout}" "gpt-5.6-sol[1m]"; then
        note "model-id check expects the resolver's suffixed id gpt-5.6-sol[1m]"
    else
        fail "model-id check rejected gpt-5.6-sol[1m], the id --resolve prints for that rollout and session model"
        hook_errors=1
    fi

    rm -rf "${model_check_dir}"
fi
(( hook_errors == 0 )) && note "hooks ship, parse, and register natively in all seven harnesses; the memory hooks index a fixture store; the commit guard declines the same commands in every tree"

# 18. The provenance line is stated in the same skills in all seven trees.
#     Conventions §8 makes model_id / model_trail every producer's job; each
#     manifest repeats it once so a run following the skill alone still records
#     it. Which skills carry it is a decision — flow-status writes nothing and
#     evid-curator writes only the mates/ store, which carries neither — and a
#     tree that drifts from that decision records provenance on one harness and
#     not on the next.
section "Provenance line parity"
prov_errors=0
prov_marker() { # $1 = tree root; prints the skills whose manifests state it
    local root="$1" skill
    while IFS= read -r skill; do
        if grep -qF 'model_trail' "${root}/${skill}/SKILL.md" 2>/dev/null; then
            printf '%s\n' "${skill}"
        fi
    done < <(printf '%s\n' "${SKILLS}")
}
PROV_BASELINE="$(prov_marker .agents/skills)"
if [[ -z "${PROV_BASELINE}" ]]; then
    fail ".agents/skills states model_trail in no manifest; conventions §8 asks every producer to"
    prov_errors=1
fi
for root in "${SKILL_ROOTS[@]:1}"; do
    if [[ "$(prov_marker "${root}")" != "${PROV_BASELINE}" ]]; then
        fail "${root} states the provenance line in a different set of skills than .agents/skills:"
        diff <(printf '%s\n' "${PROV_BASELINE}") <(prov_marker "${root}") | sed 's/^/      /'
        prov_errors=1
    fi
done
(( prov_errors == 0 )) && note "$(printf '%s\n' "${PROV_BASELINE}" | wc -l | tr -d ' ') skills state the provenance line, the same set in all seven trees"

# 19. The neutral root carries the optional local image_gen -> editable PPTX ->
#     rendered PDF figure pipeline. It is a capability-conditional extension,
#     not a requirement every harness pretends to have: the neutral manifest
#     carries the full contract, Codex UI advertises it, and the
#     six named harness trees do not acquire fragments of it by a broad
#     sync. Literal markers are used because each one protects a distinct link
#     in the chain a future edit could otherwise drop silently.
section "Optional local figure PPTX pipeline"
codex_fig_errors=0
CODEX_FIG_EN=".agents/skills/stage-figs-designer/SKILL.md"
CODEX_FIG_UI=".codex/skills/stage-figs-designer/agents/openai.yaml"
CODEX_FIG_MARKERS=(
    'image_gen'
    'manus/figs/srcs/<slug>.pptx'
    'manus/figs/srcs/<slug>.sources.md'
    'manus/figs/srcs/<slug>.render.yml'
    'role: illustrative-only'
    '@oai/artifact-tool'
    'soffice'
    'source_sha256'
    'output_sha256'
    'slides_test.py'
    'render_slides.py'
    'view_image'
    'bash execs/run.sh'
    'bash execs/scpts/lint.sh'
)
if [[ -f "${CODEX_FIG_EN}" ]]; then
    for marker in "${CODEX_FIG_MARKERS[@]}"; do
        grep -qF -- "${marker}" "${CODEX_FIG_EN}" || {
            fail "${CODEX_FIG_EN}: optional local figure pipeline is missing '${marker}'"
            codex_fig_errors=1
        }
    done
else
    fail "${CODEX_FIG_EN} is missing"
    codex_fig_errors=1
fi
for marker in 'editable PPTX' 'Image Gen' 'render the final PDF'; do
    grep -qF -- "${marker}" "${CODEX_FIG_UI}" 2>/dev/null || {
        fail "${CODEX_FIG_UI}: UI contract is missing '${marker}'"
        codex_fig_errors=1
    }
done
grep -qF 'allow_implicit_invocation: true' "${CODEX_FIG_UI}" 2>/dev/null || {
    fail "${CODEX_FIG_UI}: the non-slash-only figure skill must allow implicit invocation"
    codex_fig_errors=1
}
for root in .claude/skills .cursor/skills .dsh/skills .kimi-code/skills .pi/skills .qwen/skills; do
    path="${root}/stage-figs-designer/SKILL.md"
    for marker in 'image_gen' 'manus/figs/srcs/<slug>.pptx'; do
        if grep -qF -- "${marker}" "${path}" 2>/dev/null; then
            fail "${path}: contains neutral-root-only figure marker '${marker}'"
            codex_fig_errors=1
        fi
    done
done
(( codex_fig_errors == 0 )) && note "the neutral root carries the optional pipeline; Codex UI links to it; named trees stay native"

# 20. The advisory prose scan keeps the STORY-aligned thresholds: chatbot
#     residue can stand alone, ordinary phrases require a multi-pattern cluster,
#     comments and table data are outside the scan, and captions remain prose.
section "Advisory prose lint"
prose_lint_errors=0
PROSE_TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/stage-prose-lint.XXXXXX")"
mkdir -p "${PROSE_TEST_DIR}/execs/scpts" "${PROSE_TEST_DIR}/manus/secs" \
         "${PROSE_TEST_DIR}/manus/tabs" "${PROSE_TEST_DIR}/wkdrs/builds"
cp execs/scpts/lint.sh "${PROSE_TEST_DIR}/execs/scpts/lint.sh"

cat > "${PROSE_TEST_DIR}/execs/run.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
: > "${PROSE_TEST_DIR}/wkdrs/builds/main.log"
: > "${PROSE_TEST_DIR}/wkdrs/builds/main.pdf"

cat > "${PROSE_TEST_DIR}/manus/secs/1_positive.tex" <<'EOF'
This section delves into the evolving landscape and sets the stage for the method.

值得注意的是，本节将深入探讨不断演变的格局，从而彰显该方法的重要性。
EOF
cat > "${PROSE_TEST_DIR}/manus/secs/2_chatbot.tex" <<'EOF'
I hope this helps.
EOF
cat > "${PROSE_TEST_DIR}/manus/secs/3_single_signal.tex" <<'EOF'
It is important to note that the optimizer uses momentum.
EOF
cat > "${PROSE_TEST_DIR}/manus/secs/4_safe.tex" <<'EOF'
However, the samples were normalized before training, and the same term is used throughout.
% I hope this helps. This section delves into an evolving landscape.
EOF
cat > "${PROSE_TEST_DIR}/manus/tabs/results.tex" <<'EOF'
I hope this helps. This section delves into the evolving landscape.
\caption{This table stands as a testament to the result. It is important to note that all rows use the same split.}
EOF

if PROSE_TEST_OUT="$(cd "${PROSE_TEST_DIR}" && bash execs/scpts/lint.sh 2>&1)"; then
    for marker in \
        'manus/secs/1_positive.tex:1: prose review (inflated-significance,stock-signposting)' \
        'manus/secs/1_positive.tex:3: prose review (' \
        'manus/secs/2_chatbot.tex:1: prose review (chatbot-residue)' \
        'manus/tabs/results.tex:2: prose review (inflated-significance,stock-signposting)'; do
        grep -qF -- "${marker}" <<< "${PROSE_TEST_OUT}" || {
            fail "prose lint missed expected marker: ${marker}"
            prose_lint_errors=1
        }
    done
    for ignored in \
        'manus/secs/3_single_signal.tex:1: prose review' \
        'manus/secs/4_safe.tex:1: prose review' \
        'manus/tabs/results.tex:1: prose review'; do
        if grep -qF -- "${ignored}" <<< "${PROSE_TEST_OUT}"; then
            fail "prose lint warned on protected or below-threshold text: ${ignored}"
            prose_lint_errors=1
        fi
    done
    grep -qF 'findings are advisory, not proof of AI authorship' <<< "${PROSE_TEST_OUT}" || {
        fail "prose lint no longer states its advisory, non-authorship boundary"
        prose_lint_errors=1
    }
else
    fail "prose lint fixture exited non-zero"
    printf '%s\n' "${PROSE_TEST_OUT}" | sed 's/^/      /'
    prose_lint_errors=1
fi
rm -rf -- "${PROSE_TEST_DIR}"
(( prose_lint_errors == 0 )) && note "chatbot, cluster, false-positive, comment, and caption fixtures pass"

# 21. The versioned memory store ships as its template. STAGE is the template
#     every paper starts from — a clone or the GitHub template copies
#     .stage/memory/ as is — so a memory about developing STAGE would arrive in
#     every paper as a fact about that paper. Upstream's own memories live
#     under the git-ignored .stage/memory/local/ whatever their scope (README,
#     "Working on STAGE itself"); this holds the tracked store to the files the
#     template ships.
section "Upstream memory store ships as its template"
MEMORY_TEMPLATE_FILES='.stage/memory/.gitkeep'
tracked_memory="$(git ls-files .stage/memory)"
if [[ "${tracked_memory}" == "${MEMORY_TEMPLATE_FILES}" ]]; then
    note ".stage/memory/ tracks only the files the template ships"
else
    fail ".stage/memory/ tracks more than the template ships; STAGE's own memories belong under the git-ignored .stage/memory/local/:"
    diff <(printf '%s\n' "${MEMORY_TEMPLATE_FILES}") <(printf '%s\n' "${tracked_memory}") | sed 's/^/      /'
fi

printf '\n'
if (( FAILURES > 0 )); then
    printf '%d check(s) failed.\n' "${FAILURES}"
    exit 1
fi
printf 'All consistency checks passed.\n'
