#!/usr/bin/env bash
#
# STAGE writing-flow data collector — one digest instead of one read per file.
#
# The output table (conventions §8) is a fixed, flat set: six files under notes/, one
# manifest, one cycle directory, a promise list, and four listings. Opening each
# one costs a round trip, and a round trip costs a model turn — the reading
# itself is microseconds. This prints all of it at once.
#
# Every copy is byte-identical across the four harness trees; it names no harness
# and no skill, so there is nothing to adapt per tree.
#
# Deliberately dumb: it globs, greps, and prints. It decides nothing. No status
# glyphs, no coverage verdicts, no priority order, no drift check, no scoping to
# a section — it prints what is on disk and the skill applies the rules. That
# split is the point: conventions §8 and each skill's own text stay the single
# home of every rule, so a producer skill that adds a column never has to be
# mirrored here.
#
# Usage: bash <skill-dir>/scripts/scan.sh [--full]
#        # run from the project root
#
#   --full   drop the row caps. The default caps every table at 200 rows and
#            every listing at 200 names, which no real manuscript reaches — a
#            paper with 200 claims has a problem this script is not the place to
#            solve. What was cut is always counted, never dropped silently, so
#            the cap announces itself and this flag is the answer when it does.
#
# Reads only. Writes nothing, anywhere.

set -u

FULL=0
usage() { printf 'usage: scan.sh [--full]\n' >&2; exit 2; }
while [ $# -gt 0 ]; do
    case "$1" in
        --full) FULL=1 ;;
        *) usage ;;
    esac
    shift
done

FM_CAP=60    # frontmatter lines per file
ROW_CAP=200  # table rows per file, listing entries per directory
if [ "$FULL" = 1 ]; then FM_CAP=100000; ROW_CAP=100000; fi

say() { printf '%s\n' "$*"; }

# File selection never goes through a shell glob: an unmatched pattern is fatal
# in zsh and expands to itself in POSIX sh, and either one would quietly corrupt
# the digest. find behaves the same under every shell, and sorting makes the
# output byte-identical whatever the caller ran it with.
find_files() {  # $1 = dir, $2 = depth, $3 = name pattern
    [ -d "$1" ] || return 0
    find "$1" -mindepth "$2" -maxdepth "$2" -type f -name "$3" 2>/dev/null | sort
}

find_dirs() {   # $1 = dir; immediate subdirectories, trailing slash kept
    [ -d "$1" ] || return 0
    find "$1" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sed 's|$|/|' | sort
}

# Modification time, printed for the artifacts whose age is the signal: a build
# and a report are compared against the outline's `updated:`. BSD and GNU stat
# take different flags and neither accepts the other's, so try both.
mtime() {
    stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$1" 2>/dev/null && return 0
    stat -c '%y' "$1" 2>/dev/null | cut -c1-16
}

# Leading --- block, capped. model_trail is counted rather than printed: it grows
# by one entry per writing session for the life of the paper and sits above the
# fields every board needs, so printing it would eventually push them past the
# cap. The provenance line reads model_id: and the entry count, which is what it
# reports — the last writer of each artifact, and which artifacts have no trail.
frontmatter() {
    awk -v cap="$FM_CAP" '
        NR == 1 && $0 != "---" { exit }
        NR == 1 { next }
        /^---$/ { exit }
        /^model_trail:/ { intrail = 1; n = 0; next }
        intrail && /^[ \t]*-/ { n++; next }
        intrail && /^[^ \t]/ {
            printf "  model_trail: (%d entries)\n", n
            intrail = 0
        }
        { if (++shown <= cap) print; else omitted++ }
        END {
            if (intrail) printf "  model_trail: (%d entries)\n", n
            if (omitted) printf "  … (%d more frontmatter lines)\n", omitted
        }
    ' "$1"
}

# Every table row in the file, capped. A row is any line starting with `|`, which
# is the ledger, the outline boards, the notation table, and the response point
# ledger alike — the script does not know which is which, and does not need to.
rows() {
    awk -v cap="$ROW_CAP" '
        /^[ \t]*\|/ { if (++shown <= cap) print; else omitted++ }
        END { if (omitted) printf "… (%d more table rows)\n", omitted }
    ' "$1"
}

# `- [ ]` / `- [x]` lines: the promise lists, where the open boxes are what gates
# a camera-ready. Never capped by row count alone — an open box is the thing a
# reader must see — so the cap counts ticked ones only.
boxes() {
    awk -v cap="$ROW_CAP" '
        /^[ \t]*- \[[ xX]\]/ {
            if ($0 ~ /- \[[xX]\]/) { if (++ticked > cap) { omitted++; next } }
            print
        }
        END { if (omitted) printf "… (%d more ticked boxes)\n", omitted }
    ' "$1"
}

cap_list() {  # stdin, capped, with the remainder counted
    awk -v cap="$ROW_CAP" '
        { if (++shown <= cap) print; else omitted++ }
        END {
            if (!shown) print "(none)"
            if (omitted) printf "… (%d more)\n", omitted
        }
    '
}

# A output-table file: its path, then frontmatter, then rows. Absence is a state the
# skill reports, so a missing file prints its name and "(absent)" rather than
# nothing — a silent gap reads as a scan that forgot to look.
#
# A file with no leading `---` still gets its `model_id:` looked for: §8 has
# refs_index.md carrying that field as a plain header line, and the provenance
# read wants it from every artifact that names a writer at all.
dump_file() {
    say ""
    if [ ! -f "$1" ]; then
        say "### $1 — (absent)"
        return 0
    fi
    say "### $1 — mtime $(mtime "$1")"
    if [ "$(head -n 1 "$1")" = "---" ]; then
        frontmatter "$1"
    else
        head -n 10 "$1" | grep -E '^model_id:' || true
    fi
    rows "$1"
}

if [ ! -d notes ] && [ ! -d manus ] && [ ! -d mates ]; then
    say "(no notes/, manus/ or mates/ in $(pwd -P) — run this from the project root)"
    exit 0
fi

say "# STAGE writing-flow scan — $(pwd -P)"
say "# today: $(date +%Y-%m-%d)"
[ "$FULL" = 0 ] || say "# mode: --full (caps off)"
say "# Raw excerpts only: no status, no verdicts, no drift check, no ordering, no scoping."
say "# Apply your skill's own rules to what follows."

# ------------------------------------------------------------------ env
# The four runtime variables decide what several boards can say at all:
# STAR_HOME whether evidence freshness is knowable, ANON whether the identity
# scan runs, STAGE_LANG the reply language, LATEX_ENGINE the build. Values only —
# .env holds no secrets by §3, and a path is a fact the report may need.
say ""
say "## ENV — .env (§3)"
if [ -f .env ]; then
    grep -sE '^(STAR_HOME|LATEX_ENGINE|ANON|STAGE_REPOSITORY|STAGE_LANG|INVOLVE)=' .env || say "(none of the six set)"
else
    say "(.env absent — every variable at its documented default)"
fi

# ------------------------------------------------------------------ notes
say ""
say "## NOTES — the writing metadata (§8.1, §8.4–§8.11)"
for f in notes/story.md notes/outline.md notes/claims.md notes/notation.md notes/style.md notes/adopt.md; do
    dump_file "$f"
done

# ------------------------------------------------------------------ evidence
# One `##` heading per registered file, with the `imported:` and fingerprint
# lines under it. The entry bodies are what a freshness question reads; the file
# contents under mates/ are never touched here.
say ""
say "## MATES — mates/MANIFEST.md entries (§8.2)"
if [ -f mates/MANIFEST.md ]; then
    say "### mates/MANIFEST.md — mtime $(mtime mates/MANIFEST.md)"
    grep -nE '^## |^(imported|source|source-type|sha256|rows|stamp):' mates/MANIFEST.md | cap_list
else
    say "(absent)"
fi
say ""
say "### mates/ — depth-1 directories"
find_dirs mates | cap_list

# ------------------------------------------------------------------ refs
say ""
say "## REFS — reading notes against the bibliography (§8.7)"
say "### notes/refs/ — *.md"
find_files notes/refs 1 '*.md' | cap_list
dump_file notes/refs/refs_index.md
say ""
say "### manus/bibs/reference.bib — citekeys"
if [ -f manus/bibs/reference.bib ]; then
    grep -oE '^@[A-Za-z]+\{[^,]+' manus/bibs/reference.bib | sed 's/^@[A-Za-z]*{//' | sort | cap_list
else
    say "(absent)"
fi

# ------------------------------------------------------------------ cycles
# Every cycle, not just the active one: which is active comes from notes/story.md
# frontmatter (§5), which the NOTES block above already printed, and resolving it
# here would be a judgment this script does not make.
say ""
say "## CYCLES — cycls/<venue>_<year>/ (§8.3, §8.8, §8.10)"
cycles=$(find_dirs cycls)
if [ -z "$cycles" ]; then
    say "(none)"
else
    printf '%s\n' "$cycles" | while IFS= read -r c; do
        c=${c%/}
        say ""
        say "### $c/"
        if [ -f "$c/venue.yml" ]; then
            say "-- venue.yml --"
            grep -vE '^[ \t]*(#|$)' "$c/venue.yml" | cap_list
        else
            say "-- venue.yml — (absent)"
        fi
        say "-- reviews/ --"
        find_files "$c/reviews" 1 '*' | cap_list
        say "-- response/ --"
        find_files "$c/response" 1 '*' | cap_list
        say "-- submission records, poster, template --"
        { find_files "$c" 1 'SUBMISSION_*'
          find_dirs "$c" | grep -E '/(poster|template)/$' || true
        } | cap_list
    done
fi

# ------------------------------------------------------------------ tasks
say ""
say "## TASKS — promise lists and venue follow-ups"
task_files=$(find_files tasks 1 '*.md')
if [ -z "$task_files" ]; then
    say "(none)"
else
    printf '%s\n' "$task_files" | while IFS= read -r t; do
        say ""
        say "### $t — mtime $(mtime "$t")"
        boxes "$t"
    done
fi

# ------------------------------------------------------------------ manuscript
# Listings only. What each section says is the drafter's business; what the board
# needs is which files exist, to be set against the outline's rows.
say ""
say "## MANUS — depth-1 listings"
for d in manus/secs manus/tabs manus/figs manus/figs/srcs manus/bibs manus/stys; do
    say ""
    say "### $d/"
    find_files "$d" 1 '*' | grep -v '/\.gitkeep$' | cap_list
done
say ""
say "### manus/main.tex — \\input order"
if [ -f manus/main.tex ]; then
    grep -nE '\\(input|include)\{' manus/main.tex | cap_list
else
    say "(absent)"
fi

# ------------------------------------------------------------------ wkdrs
# Builds and reports are dated evidence of when something last ran, which is why
# the mtime rides along; the contents are regenerable and never read here.
say ""
say "## WKDRS — builds and reports (gitignored, regenerable)"
say "### wkdrs/builds/ — *.pdf"
builds=$(find_files wkdrs/builds 1 '*.pdf')
if [ -z "$builds" ]; then
    say "(none)"
else
    printf '%s\n' "$builds" | while IFS= read -r b; do say "$b — mtime $(mtime "$b")"; done | cap_list
fi
say ""
say "### wkdrs/reports/ — *.md"
reports=$(find_files wkdrs/reports 1 '*.md')
if [ -z "$reports" ]; then
    say "(none)"
else
    printf '%s\n' "$reports" | while IFS= read -r r; do say "$r — mtime $(mtime "$r")"; done | cap_list
fi
say ""
say "### wkdrs/ — depth-1 directories"
find_dirs wkdrs | cap_list

# ------------------------------------------------------------------ git
# Read-only by §1: this skill's whole git surface. The freeze tags say which
# cycles were submitted; the porcelain lines say what is uncommitted, which is
# context for a report, never something this skill acts on.
say ""
say "## GIT — read-only"
say "### uncommitted"
git status --short 2>/dev/null | cap_list
say ""
say "### last commit"
git log -1 --format='%h %ad %s' --date=short 2>/dev/null || say "(no commits)"
say ""
say "### freeze tags"
git tag -l 'freeze/*' 2>/dev/null | sort | cap_list
