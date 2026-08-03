#!/usr/bin/env bash
# STAGE upstream consistency check.
#
# Guards the invariants the four per-harness skill trees (.agents / .claude /
# .cursor / .kimi-code), the shared agent instructions, and the workflow docs
# are supposed to keep while being maintained by hand. The trees hold the same
# fifteen skills and differ only in invocation prefix and tool names, so every
# drift between them is a bug rather than a variant — and nothing but this
# script looks for it.
#
# Run from anywhere inside the repo:  bash .github/scripts/check_consistency.sh
# Exits non-zero if any check fails. Upstream-maintainer tooling only — this
# directory is not synced into paper repositories by execs/update.sh.
set -uo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)"
cd "${ROOT_DIR}" || exit 1

SKILL_ROOTS=(.agents/skills .claude/skills .cursor/skills .kimi-code/skills)
# The three trees that guard implicit invocation through SKILL.md frontmatter;
# .agents does it through agents/openai.yaml instead (check 4).
FRONTMATTER_ROOTS=(.claude/skills .cursor/skills .kimi-code/skills)
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

# 1. The four roots carry the same, non-empty set of skill directories.
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
    note "$(printf '%s\n' "${SKILLS}" | wc -l | tr -d ' ') skills, same set in all four roots"
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

# 3. Per-skill file inventory is identical across the four trees, apart from the
#    Codex-only agents/ manifest directory.
section "File inventory parity (ignoring .agents agents/ manifests)"
parity_errors=0
while IFS= read -r skill; do
    baseline="$(cd ".claude/skills/${skill}" && find . -type f | sort)"
    for root in "${SKILL_ROOTS[@]}"; do
        [[ "${root}" == ".claude/skills" ]] && continue
        listing="$(cd "${root}/${skill}" && find . -type f ! -path './agents/*' | sort)"
        if [[ "${listing}" != "${baseline}" ]]; then
            fail "${root}/${skill} file set differs from .claude/skills/${skill}:"
            diff <(printf '%s\n' "${baseline}") <(printf '%s\n' "${listing}") | sed 's/^/      /'
            parity_errors=1
        fi
    done
done < <(printf '%s\n' "${SKILLS}")
(( parity_errors == 0 )) && note "file sets match across all four trees"

# 4. The slash-only set is one decision expressed in three places, and they must
#    agree. The conventions roster (§11) marks it with † and is what every skill
#    run loads; the Claude, Cursor and Kimi trees enforce it with
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
    manifest=".agents/skills/${skill}/agents/openai.yaml"
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
(( guard_errors == 0 )) && note "$(printf '%s\n' "${SLASH_ONLY}" | wc -l | tr -d ' ') slash-only skills guarded identically in all four trees"

# 5. Bilingual twins: every skill .md has its _zh.md counterpart and vice versa.
section "Bilingual twins in skill trees"
twin_errors=0
while IFS= read -r f; do
    if [[ "${f}" == *_zh.md ]]; then
        [[ -f "${f%_zh.md}.md" ]] || { fail "${f} has no English counterpart"; twin_errors=1; }
    else
        [[ -f "${f%.md}_zh.md" ]] || { fail "${f} has no _zh.md counterpart"; twin_errors=1; }
    fi
done < <(find "${SKILL_ROOTS[@]}" -type f -name '*.md')
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

# 7. Invocation tokens are tree-appropriate: $stage-* in .agents, /stage-* in
#    .claude and .cursor, /skill:stage-* in .kimi-code.
section "Invocation-token hygiene"
token_errors=0
check_absent() { # $1 = path, $2 = literal token that must not appear there
    local hits
    hits="$(grep -RnF -- "$2" "$1" 2>/dev/null || true)"
    if [[ -n "${hits}" ]]; then
        fail "$1 contains foreign invocation token '$2':"
        printf '%s\n' "${hits}" | head -n 3 | sed 's/^/      /'
        token_errors=1
    fi
}
while IFS= read -r skill; do
    check_absent .agents/skills "/${skill}"
    check_absent .agents/skills "skill:${skill}"
    for root in .claude/skills .cursor/skills; do
        check_absent "${root}" "\$${skill}"
        check_absent "${root}" "skill:${skill}"
    done
    check_absent .kimi-code/skills "\$${skill}"
    # Bare /stage-* is foreign in the Kimi tree; /skill:stage-* does not contain it.
    check_absent .kimi-code/skills "/${skill}"
done < <(printf '%s\n' "${SKILLS}")

# The rewrite that retokenizes a ported skill targets "/stage-" or "$stage-",
# and one repo path carries that substring: docs/mds/stage-workflow/. A rewrite
# run without a guard turns it into "docs/mds/skill:stage-workflow/" or
# "docs/mds$stage-workflow/", and every check above passes it — the token is
# native to that tree, and check 6 matches the filename, not the directory. So
# the rule is stated positively: every "docs/mds" in the skill trees is
# followed by exactly "/stage-workflow/". The match is compared with its own
# `-n` colon in front, which is what keeps a mangled "skill:" from being read
# as the separator grep itself printed.
mangled_paths="$(grep -rnoE 'docs/mds[^[:space:]`)]*' "${SKILL_ROOTS[@]}" 2>/dev/null |
                 grep -vF ':docs/mds/stage-workflow/' || true)"
if [[ -n "${mangled_paths}" ]]; then
    fail "docs/mds/ path damaged (a token rewrite hit the directory name):"
    printf '%s\n' "${mangled_paths}" | sed 's/^/      /'
    token_errors=1
fi
(( token_errors == 0 )) && note "invocation tokens are consistent per tree; docs/mds/ paths intact"

# 8. Harness vocabulary stays native to its tree. A skill that tells a Cursor
#    agent to call AskUserQuestion, or a Kimi agent to call Read, names a tool
#    that harness does not have — the run degrades to plain text, silently, at
#    exactly the confirmation point the workflow put there.
section "Harness-specific tool vocabulary"
vocab_errors=0
check_foreign() { # $1 = tree, $2 = literal, $3 = what the tree calls it instead
    local hits
    hits="$(grep -RnF --include='*.md' -- "$2" "$1" 2>/dev/null || true)"
    if [[ -n "${hits}" ]]; then
        fail "$1 names '$2'; this tree's tool is $3:"
        printf '%s\n' "${hits}" | head -n 3 | sed 's/^/      /'
        vocab_errors=1
    fi
}
#            tree                  foreign literal        native name
check_foreign .claude/skills       'AskQuestion'          'AskUserQuestion'
check_foreign .claude/skills       'request_user_input'   'AskUserQuestion'
check_foreign .claude/skills       '`ReadFile`'           '`Read`'
check_foreign .claude/skills       'Shell'                'Bash'
check_foreign .cursor/skills       'AskUserQuestion'      'AskQuestion'
check_foreign .cursor/skills       'request_user_input'   'AskQuestion'
check_foreign .cursor/skills       '`ReadFile`'           '`Read`'
check_foreign .cursor/skills       'Bash'                 'Shell'
check_foreign .kimi-code/skills    'AskQuestion'          'AskUserQuestion'
check_foreign .kimi-code/skills    'request_user_input'   'AskUserQuestion'
check_foreign .kimi-code/skills    '`Read`'               '`ReadFile`'
check_foreign .kimi-code/skills    'Bash'                 'Shell'
check_foreign .agents/skills       'AskUserQuestion'      'request_user_input'
check_foreign .agents/skills       'AskQuestion'          'request_user_input'
check_foreign .agents/skills       'Bash'                 'the shell, in prose'
check_foreign .agents/skills       'Shell'                'the shell, in prose'
for root in "${FRONTMATTER_ROOTS[@]}"; do
    check_foreign "${root}" 'spawn_agent' 'a plain subagent'
    check_foreign "${root}" 'update_plan' 'plan mode'
done
# The delegation ban is stated once per skill that has one, and it has to be
# stated in the tree's own words or it names nothing the agent can refuse.
stale_generic="$(grep -RnE --include='*.md' 'no subagents|不派子代理' .agents/skills .cursor/skills || true)"
if [[ -n "${stale_generic}" ]]; then
    fail ".agents/.cursor state the delegation ban generically; each must name its own dispatch tool:"
    printf '%s\n' "${stale_generic}" | sed 's/^/      /'
    vocab_errors=1
fi
(( vocab_errors == 0 )) && note "each tree names only its own harness's tools"

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
done < <(find "${SKILL_ROOTS[@]}" -name 'SKILL.md' | sort)
(( desc_errors == 0 )) && note "all descriptions within ${DESC_MAX} characters in all four trees"

# 11. Heading structure matches across the three trees that share it.
#     Checks 1-3 compare file *sets*; nothing above compares what is inside
#     them, so a step could be dropped from one tree, or reordered, and every
#     check passed.
#
#     Normalization: a heading is truncated at its first "(" or "（" and
#     stripped of backticks, so harness vocabulary inside a heading is free to
#     differ. What remains must match exactly.
#
#     .agents is excluded on purpose: its headings carry Codex vocabulary in
#     places the parenthesis rule does not reach. Check 12 holds its shape at
#     the ## level instead.
section "Heading structure (.claude / .cursor / .kimi-code)"
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
    for root in .cursor/skills .kimi-code/skills; do
        other="${root}/${rel}"
        [[ -f "${other}" ]] || continue   # inventory parity is check 3's job
        if ! diff -q <(norm_headings ".claude/skills/${rel}") <(norm_headings "${other}") > /dev/null; then
            fail "${other}: heading structure differs from .claude/skills/${rel}:"
            diff <(norm_headings ".claude/skills/${rel}") <(norm_headings "${other}") | sed 's/^/      /'
            struct_errors=1
        fi
    done
done < <(cd .claude/skills && find . -type f -name '*.md' | sed 's|^\./||' | sort)
(( struct_errors == 0 )) && note "heading structure matches across the three trees (${struct_files} files)"

# 12. Top-level section parity between .agents and .claude manifests.
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
        baseline=".claude/skills/${skill}/${manifest}"
        other=".agents/skills/${skill}/${manifest}"
        [[ -f "${baseline}" && -f "${other}" ]] || continue   # checks 2 and 3 own missing files
        if ! diff -q <(norm_sections "${baseline}") <(norm_sections "${other}") > /dev/null; then
            fail "${other}: ## sections differ from ${baseline}:"
            diff <(norm_sections "${baseline}") <(norm_sections "${other}") | sed 's/^/      /'
            section_errors=1
        fi
    done
done < <(printf '%s\n' "${SKILLS}")
(( section_errors == 0 )) && note ".agents manifests carry the same ## sections as .claude"

# 13. Opening-load invariants.
#     Every run is supposed to start the same way: resolve STAGE_LANG from .env,
#     load the whole conventions file through the harness's file-reading tool,
#     and skip the re-read only when the text is still verbatim in context.
#     Nothing above guards any of it — a manifest could drop the language probe,
#     lose the conventions block, or cat the conventions into a shell command
#     (guaranteeing the >30 KB spill the one-message shape exists to avoid), and
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
    '8. The artifact registry'
    '9. The fabrication boundary'
    '10. Project layout'
    '11. The skill roster'
)
# section|numbered top-level items
CONV_ITEMS=("1|6" "3|6" "4|4" "5|6" "6|9" "7|11" "10|5" "11|3")
CONV_SUBHEADS=("8|10")    # ### 8.n subheadings
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

printf '\n'
if (( FAILURES > 0 )); then
    printf '%d check(s) failed.\n' "${FAILURES}"
    exit 1
fi
printf 'All consistency checks passed.\n'
