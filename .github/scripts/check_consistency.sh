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
CONV_ZH="docs/mds/stage-workflow/writing-workflow-conventions.zh-CN.md"

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
        for manifest in "${root}/${skill}/SKILL.md" "${root}/${skill}/SKILL_zh.md"; do
            if [[ ! -f "${manifest}" ]]; then
                fail "${manifest} is missing"
                name_errors=1
                continue
            fi
            if ! frontmatter_has_line "${manifest}" "name: ${skill}"; then
                fail "${manifest}: frontmatter name does not match directory '${skill}'"
                name_errors=1
            fi
        done
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
        for f in SKILL.md SKILL_zh.md; do
            has=false
            frontmatter_has_line "${root}/${skill}/${f}" "disable-model-invocation: true" && has=true
            if [[ "${want_guarded}" != "${has}" ]]; then
                if [[ "${want_guarded}" == true ]]; then
                    fail "${root}/${skill}/${f}: slash-only in the conventions roster but no 'disable-model-invocation: true'"
                else
                    fail "${root}/${skill}/${f}: carries 'disable-model-invocation: true' but is not slash-only in the conventions roster"
                fi
                guard_errors=1
            fi
        done
    done
done < <(printf '%s\n' "${SKILLS}")
(( guard_errors == 0 )) && note "$(printf '%s\n' "${SLASH_ONLY}" | wc -l | tr -d ' ') slash-only skills guarded identically in all seven trees"

# 4a. The full /stage router and its Chinese reading edition are neutral content
#     and live together under .agents.
#     Native command files adapt only their harness's argument syntax and skill
#     mechanism. Copying the roster into those files creates four policy surfaces
#     whose explicit-only set can drift independently.
section "Shared request router"
router_errors=0
ROUTER=".agents/commands/stage.md"
ROUTER_ZH=".agents/commands/stage.zh-CN.md"
router_rows() { # $1 = router file, $2 = row regex -> matching skill names, sorted
    sed -nE "$2" "$1" | sort
}
ROUTER_ANY='s/^\| `(stage-[a-z-]+)` \|.*$/\1/p'
ROUTER_DAGGER='s/^\| `(stage-[a-z-]+)` \| † \|.*$/\1/p'
for router in "${ROUTER}" "${ROUTER_ZH}"; do
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
(( router_errors == 0 )) && note "one bilingual neutral roster drives four file-based native command entry points"

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
KIMI_ROUTER_SKILL_ZH="${KIMI_PLUGIN_ROOT}/skills/stage/SKILL_zh.md"
if [[ ! -f "${KIMI_ROUTER_SKILL_ZH}" ]] || \
   ! frontmatter_has_line "${KIMI_ROUTER_SKILL_ZH}" "name: stage" || \
   ! frontmatter_has_line "${KIMI_ROUTER_SKILL_ZH}" "disableModelInvocation: true" || \
   ! grep -qF '.agents/commands/stage.md' "${KIMI_ROUTER_SKILL_ZH}"; then
    fail "${KIMI_ROUTER_SKILL_ZH} is not the Chinese explicit-only Kimi adapter"
    kimi_plugin_errors=1
fi
for skill_file in "${KIMI_ROUTER_SKILL}" "${KIMI_ROUTER_SKILL_ZH}"; do
    if ! grep -qF 'STAGE_LANG=zh' "${skill_file}" || \
       ! grep -qF '.agents/commands/stage.zh-CN.md' "${skill_file}"; then
        fail "${skill_file} does not apply STAGE's Chinese router wording"
        kimi_plugin_errors=1
    fi
done
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
if [[ ! -f "${PLUGIN_ROOT}/skills/stage/SKILL_zh.md" ]] || \
   ! frontmatter_has_line "${PLUGIN_ROOT}/skills/stage/SKILL_zh.md" "name: stage" || \
   ! grep -qF '.agents/commands/stage.md' "${PLUGIN_ROOT}/skills/stage/SKILL_zh.md"; then
    fail "${PLUGIN_ROOT}/skills/stage lacks its Chinese wrapper around the shared router"
    plugin_errors=1
fi
for skill_file in "${PLUGIN_ROOT}/skills/stage/SKILL.md" "${PLUGIN_ROOT}/skills/stage/SKILL_zh.md"; do
    if ! grep -qF 'STAGE_LANG=zh' "${skill_file}" || \
       ! grep -qF '.agents/commands/stage.zh-CN.md' "${skill_file}"; then
        fail "${skill_file} does not apply STAGE's Chinese router wording"
        plugin_errors=1
    fi
done
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
        '.stage/memory/MEMORY.md' \
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

# 5. Bilingual twins: every skill .md has its _zh.md counterpart and vice versa.
section "Bilingual twins in skill trees"
twin_errors=0
while IFS= read -r f; do
    if [[ "${f}" == *_zh.md ]]; then
        [[ -f "${f%_zh.md}.md" ]] || { fail "${f} has no English counterpart"; twin_errors=1; }
    else
        [[ -f "${f%.md}_zh.md" ]] || { fail "${f} has no _zh.md counterpart"; twin_errors=1; }
    fi
done < <(find -L "${SKILL_ROOTS[@]}" -type f -name '*.md')
(( twin_errors == 0 )) && note "every skill .md file has its bilingual twin"

# 6. Every manifest defers to the shared conventions document, by name.
#    Citing "conventions §8" without naming the file is what stage-proj-adopt
#    and stage-evid-curator did for their whole life: they read as if the
#    baseline were loaded, and no run ever loaded it.
section "Shared-conventions reference"
conv_ref_errors=0
for root in "${SKILL_ROOTS[@]}"; do
    while IFS= read -r skill; do
        for f in SKILL.md SKILL_zh.md; do
            grep -q 'writing-workflow-conventions\.md' "${root}/${skill}/${f}" || {
                fail "${root}/${skill}/${f} does not name the conventions document"
                conv_ref_errors=1
            }
        done
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
        for name in SKILL.md SKILL_zh.md; do
            path="${root}/${skill}/${name}"
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
#     The Kimi tree is the tight one — /skill: adds six characters per skill
#     token, three tokens in the longest description — so a description trimmed
#     to fit .claude can still overrun there.
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
    for manifest in SKILL.md SKILL_zh.md; do
        baseline=".agents/skills/${skill}/${manifest}"
        other=".claude/skills/${skill}/${manifest}"
        [[ -f "${baseline}" && -f "${other}" ]] || continue   # checks 2 and 3 own missing files
        if ! diff -q <(norm_sections "${baseline}") <(norm_sections "${other}") > /dev/null; then
            fail "${other}: ## sections differ from ${baseline}:"
            diff <(norm_sections "${baseline}") <(norm_sections "${other}") | sed 's/^/      /'
            section_errors=1
        fi
    done
done < <(printf '%s\n' "${SKILLS}")
(( section_errors == 0 )) && note ".claude manifests carry the same ## sections as the authored .agents source"

# 13. Opening-load invariants.
#     Every run is supposed to start the same way: resolve STAGE_LANG from .env,
#     load the whole conventions file through the harness's file-reading tool,
#     and skip the re-read only when the text is still verbatim in context.
#     Nothing above guards any of it — a manifest could drop the language probe,
#     lose the conventions block, or cat the conventions into a shell command
#     (guaranteeing the >30 KB result the one-message shape exists to avoid), and
#     every check stayed green. The literals pinned here are the strings that
#     discipline rides on; rewording one centrally means updating this check in
#     the same commit.
section "Opening-load invariants"
open_errors=0
PROBE_LINE="grep -sE '^STAGE_LANG=' .env"
for root in "${SKILL_ROOTS[@]}"; do
    while IFS= read -r skill; do
        for f in SKILL.md SKILL_zh.md; do
            path="${root}/${skill}/${f}"
            [[ -f "${path}" ]] || continue   # check 2 owns missing files

            n="$(grep -cF -- "${PROBE_LINE}" "${path}")"
            if (( n != 1 )); then
                fail "${path}: ${n} STAGE_LANG probe lines, expected exactly 1"
                open_errors=1
            fi

            if [[ "${f}" == SKILL_zh.md ]]; then
                head_re='^\*\*通用规约。'
                reuse_re='^\*\*复用上一次装载。\*\*'
            else
                head_re='^\*\*Shared conventions\.'
                reuse_re='^\*\*Reusing an earlier load\.\*\*'
            fi
            n="$(grep -cE "${head_re}" "${path}")"
            (( n == 1 )) || { fail "${path}: ${n} shared-conventions blocks, expected exactly 1"; open_errors=1; }
            n="$(grep -cE "${reuse_re}" "${path}")"
            (( n == 1 )) || { fail "${path}: ${n} reuse-an-earlier-load paragraphs, expected exactly 1"; open_errors=1; }

            hits="$(grep -n 'cat docs/mds/stage-workflow/writing-workflow-conventions' "${path}" || true)"
            if [[ -n "${hits}" ]]; then
                fail "${path}: cats the whole conventions file through the shell; it spills and costs the round trip the one-message load avoids:"
                printf '%s\n' "${hits}" | sed 's/^/      /'
                open_errors=1
            fi
        done
    done < <(printf '%s\n' "${SKILLS}")
done
(( open_errors == 0 )) && note "opening loads hold: one language probe, one conventions block, one reuse paragraph, no conventions cat"

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
)
# section|numbered top-level items
CONV_ITEMS=("1|6" "3|7" "4|4" "5|6" "6|9" "7|13" "10|5" "11|4")
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
    # The Chinese edition writes the same rules with fullwidth parentheses.
    awk -v want="$2" "${CONV_AWK_PRELUDE}"'
        /^## / { n = $2; sub(/\./, "", n); insec = (n == want) }
        insec && /^\*\*[（(][a-z][）)]/ { c++ }
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
if [[ "$(conv_headings "${CONV_EN}" | sed -nE 's/^([0-9]+)\..*/\1/p')" != "$(conv_headings "${CONV_ZH}" | sed -nE 's/^([0-9]+)\..*/\1/p')" ]]; then
    fail "${CONV_ZH} does not carry the same section numbers as ${CONV_EN}; a §n citation resolves to a different rule per language"
    conv_errors=1
fi
for spec in "items:${CONV_ITEMS[*]}" "subheads:${CONV_SUBHEADS[*]}" "letters:${CONV_LETTERS[*]}"; do
    kind="${spec%%:*}"
    for row in ${spec#*:}; do
        sec="${row%%|*}"
        want="${row#*|}"
        for f in "${CONV_EN}" "${CONV_ZH}"; do
            got="$(conv_${kind} "${f}" "${sec}")"
            if [[ "${got}" != "${want}" ]]; then
                fail "${f}: §${sec} carries ${got} ${kind}, pinned at ${want} — every §${sec}.n citation past the change now points elsewhere"
                conv_errors=1
            fi
        done
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
    if (( c_sec > 11 )); then
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
             "${CONV_EN}" "${CONV_ZH}" \
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

# Workflow docs ship as en/zh pairs.
while IFS= read -r f; do
    if [[ "${f}" == *.zh-CN.md ]]; then
        [[ -f "${f%.zh-CN.md}.md" ]] || { fail "${f} has no English counterpart"; doc_errors=1; }
    else
        [[ -f "${f%.md}.zh-CN.md" ]] || { fail "${f} has no .zh-CN.md counterpart"; doc_errors=1; }
    fi
done < <(find docs/mds/stage-workflow -type f -name '*.md')

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
(( doc_errors == 0 )) && note "guides and landing pages name every skill; workflow docs paired en/zh; links resolve"

# 16. Chinese text carries no space between two Chinese characters.
#     A folded scalar turns every line break into a space, which is what English
#     descriptions want and Chinese ones never do: wrapping 中文 across two lines
#     puts a space inside a word, and the next rewrap bakes that space in and
#     adds a new one at the new break. The value the harness reads drifts one
#     space per edit while the file still looks wrapped and tidy.
#     The invariant is therefore both halves: the description is one line, so a
#     fold cannot introduce a space, and no such space is already in it. The
#     scan is non-ASCII-space-non-ASCII, which also catches "——" carrying a
#     space on one side only; a space between Chinese and Latin (`notes/` 里的)
#     is correct style and has an ASCII character on one side, so it passes.
section "Chinese spacing (descriptions, skill bodies, zh docs)"
zh_desc_errors=0
while IFS= read -r manifest; do
    verdict="$(perl -CSD -Mutf8 -0777 -ne '
        my ($fm) = /\A---\n(.*?)\n---\n/s or exit 0;
        my ($body) = $fm =~ /^description:[^\n]*\n((?:[ \t]+\S[^\n]*\n?)+)/m or exit 0;
        my @lines = grep { /\S/ } split /\n/, $body;
        print "multi-line description: a fold would put a space inside a word\n" if @lines > 1;
        my $joined = join " ", map { my $l = $_; $l =~ s/^\s+|\s+$//g; $l } @lines;
        print "space between two Chinese characters\n" if $joined =~ /[^\x00-\x7f] [^\x00-\x7f]/;
    ' "${manifest}")"
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        fail "${manifest}: ${line}"
        zh_desc_errors=1
    done <<< "${verdict}"
done < <(find "${SKILL_ROOTS[@]}" -name 'SKILL_zh.md' | sort)

# Everywhere else Chinese is written — skill bodies, reference files, the two
# workflow documents, the memory spec, README.zh-CN.md and the landing pages —
# no fold is involved, so only a hand-typed space can land between two Chinese
# characters. The scan is therefore narrower than the description one: Han and
# CJK punctuation only. A Chinese character beside a *symbol* is correct
# typography and stays free — 规约 §9, 评审意见 → 要点记录表, 陈述处 ⇄ 证据,
# 标 † 的五个, "# 2 · 配置", 回到顶部 ↑, the box-drawing rules in the workflow
# diagram, and "——" spaced on both sides.
#     One exception, and it is a real one: 中文要点摘要 is a section title, and
#     the spaces around it set it off from the sentence carrying it, the way
#     backticks would in English. Both spaces must be there — a title that lost
#     one is a typo the scan should still catch — so the pair is dropped before
#     matching rather than the pattern being loosened.
while IFS= read -r zhfile; do
    while IFS= read -r hit; do
        [[ -n "${hit}" ]] || continue
        fail "${zhfile}:${hit} — space between two Chinese characters"
        zh_desc_errors=1
    done < <(perl -CSD -Mutf8 -ne '
        BEGIN { $CJK = qr/[\p{Han}\p{Block=CJK_Symbols_and_Punctuation}\p{Block=Halfwidth_and_Fullwidth_Forms}]/ }
        my $line = $_;
        $line =~ s/ 中文要点摘要 //g;
        print "$.: $&\n" while $line =~ /$CJK $CJK/g;
    ' "${zhfile}")
done < <(find . -path ./.git -prune -o -path ./wkdrs -prune -o \
              \( -name '*_zh.md' -o -name '*.zh-CN.md' -o -name '*_zh.html' \) -print |
         sed 's|^\./||' | sort)
(( zh_desc_errors == 0 )) && note "every Chinese description is one line; no space inside a word in any Chinese file"

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
         .claude/hooks/stage_involve_gate.sh .codex/hooks/stage_involve_gate.sh \
         .qwen/hooks/stage_involve_gate.sh .dsh/hooks/install.sh .kimi-code/hooks/install.sh; do
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
    grep -qF '"${involve}" == "low"' "${f}" || { fail "${f} no longer gates on INVOLVE=low"; hook_errors=1; }
done

for f in .claude/hooks/stage_model_id.sh .codex/hooks/stage_model_id.sh \
         .cursor/hooks/stage_model_id.sh .dsh/hooks/stage_model_id.sh \
         .kimi-code/hooks/stage_model_id.sh .pi/extensions/stage-hooks/stage_model_id.sh \
         .qwen/hooks/stage_model_id.sh; do
    grep -qF 'writing-workflow-conventions section 8' "${f}" 2>/dev/null || \
        { fail "${f} no longer points at writing-workflow-conventions section 8"; hook_errors=1; }
done
for f in docs/mds/stage-workflow/model_id_spec.md docs/mds/stage-workflow/model_id_spec.zh-CN.md; do
    [[ -f "${f}" ]] || { fail "${f} is missing"; hook_errors=1; }
done
(( hook_errors == 0 )) && note "hooks ship, parse, and register natively in all seven harnesses; the commit guard declines the same commands in every tree"

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
        if grep -qF 'model_trail' "${root}/${skill}/SKILL.md" 2>/dev/null &&
           grep -qF 'model_trail' "${root}/${skill}/SKILL_zh.md" 2>/dev/null; then
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
#     not a requirement every harness pretends to have: the English and Chinese
#     neutral manifests carry the full contract, Codex UI advertises it, and the
#     six named harness trees do not acquire fragments of it by a broad
#     sync. Literal markers are used because each one protects a distinct link
#     in the chain a future edit could otherwise drop silently.
section "Optional local figure PPTX pipeline"
codex_fig_errors=0
CODEX_FIG_EN=".agents/skills/stage-figs-designer/SKILL.md"
CODEX_FIG_ZH=".agents/skills/stage-figs-designer/SKILL_zh.md"
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
for f in "${CODEX_FIG_EN}" "${CODEX_FIG_ZH}"; do
    [[ -f "${f}" ]] || { fail "${f} is missing"; codex_fig_errors=1; continue; }
    for marker in "${CODEX_FIG_MARKERS[@]}"; do
        grep -qF -- "${marker}" "${f}" || {
            fail "${f}: optional local figure pipeline is missing '${marker}'"
            codex_fig_errors=1
        }
    done
done
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
    for f in SKILL.md SKILL_zh.md; do
        path="${root}/stage-figs-designer/${f}"
        for marker in 'image_gen' 'manus/figs/srcs/<slug>.pptx'; do
            if grep -qF -- "${marker}" "${path}" 2>/dev/null; then
                fail "${path}: contains neutral-root-only figure marker '${marker}'"
                codex_fig_errors=1
            fi
        done
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

printf '\n'
if (( FAILURES > 0 )); then
    printf '%d check(s) failed.\n' "${FAILURES}"
    exit 1
fi
printf 'All consistency checks passed.\n'
