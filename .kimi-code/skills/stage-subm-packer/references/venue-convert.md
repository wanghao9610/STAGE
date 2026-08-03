# Venue Template Conversion

How `stage-subm-packer` turns the manuscript into a copy that compiles under an
officially-supplied venue class. Loaded when a run converts — `convert` mode, or
a pack whose cycle has a `template:` naming a registered kit. `SKILL.md` states
the rules; this file is the procedure.

The shape in one line: **`manus/` is read; a standalone copy is written; the copy
is regenerated from scratch every run.** There is no in-place venue swap, no
second source of truth, and no incremental sync.

## The contract

Four rules. Each exists because the obvious shortcut past it produces a paper
that is wrong in a way nobody notices until a reviewer does.

1. **The kit is the only source of truth.** The venue's class, style, and
   bibliography-style files come from an official kit the user supplies. Never
   fetch one, never reconstruct one from memory of what CVPR's class looks like,
   never write a `.cls` (conventions §9). A class recalled rather than read is
   the same defect as a metric recalled rather than imported — it is usually
   close, and "usually close" is not a format a chair accepts.
2. **`manus/` is never edited, and nothing is added to it either.** Not `main.tex`,
   not `secs/`, not `tabs/`, not `bibs/reference.bib`, and not `stys/` — the kit
   lands in `cycls/<cycle>/template/` (step 1). The manuscript tree is read, and
   that is all that happens to it.
3. **Official files are copied byte-for-byte and never patched.** When the venue's
   own class appears to need a change to make the copy compile, the change belongs
   in the generated `compat.sty` or the generated `main.tex` — or, if neither can
   carry it, in the report. Editing a venue class silently makes the submission
   non-conforming.
4. **The copy is generated, never authored.** Nothing under the output directory
   survives the next run. A fix hand-applied there is a fix that disappears; the
   real fix goes to `manus/` (through the skill that owns the file) or to the
   conversion rules here.

## 1. Resolve the kit

**The kit lives at `cycls/<cycle>/template/`** — one kit per cycle, beside that
cycle's `venue.yml`, `reviews/`, and `response/`, because a venue's template
belongs to a venue attempt and has exactly that lifetime. Next year's resubmission
is a different cycle with a different kit, and neither has to be told apart from
the other by a directory name.

`template:` in `venue.yml` names the **class inside the kit**, not a directory:
`template: cvpr` means the generated `main.tex` says `\documentclass{stys/cvpr}`.
A kit ships several class and style files and often more than one plausible entry,
so the field is what picks one.

It is deliberately not under `manus/`. That tree is a **scanned namespace** —
`lint.sh` counts `\todo{` and hunts identity leaks across every `*.tex` in it — and
a kit's own example `.tex` carries sample author names and an Acknowledgments
section. Under `ANON=true` that is a hard lint failure raised by a third-party file
nobody is allowed to edit, on every pack, forever.

- **`kit=<path>` given** — the path is a zip or a directory. Unpack or copy it,
  whole and unmodified, into `cycls/<cycle>/template/`. If that directory already
  exists with different contents, show what differs and ask before replacing it
  (conventions §7.2): a kit swapped underneath a cycle changes the page budget
  every earlier decision was made against.
- **No `kit=`** — `cycls/<cycle>/template/` must already exist. Missing, and the
  run stops with the one thing that unblocks it: the official kit's path.
- **`template:` absent, empty, or `arxiv`** — no conversion. The package is the
  preprint form built from `stys/arxiv.cls`, which is what the manuscript already
  compiles as. Say so rather than converting to nothing.

The kit is tracked, not ignored: a package is only reproducible from a freeze tag
if the class that formatted it is in the same history. Kits that the venue forbids
redistributing are the user's call — say what is being committed and let them
decide (§7.2).

## 2. Read the kit

Read, in the unpacked kit: its example `.tex`, its `.cls` and `.sty` files, its
`.bst` if it ships one, and any README or author-instructions file. Extract, and
write down, six things:

| What | Where it usually is |
|---|---|
| the exact `\documentclass` line and its options | the example `.tex`, first line |
| packages the class does not load but the example does | the example's preamble |
| the native title / author / affiliation macros, with their exact signatures | the example's preamble and the class's `\newcommand`s |
| the bibliography style the kit expects | the example's `\bibliographystyle`, or the shipped `.bst` name |
| the anonymity switch | a `\...finalcopy` command, a `final`/`review` class option, or an `\ifreview`-style conditional |
| whether the abstract is an environment or a command | the example's body |

What the kit does not show is not invented. A venue whose kit ships no anonymity
switch gets none, and the report says the anonymity had to be handled another way
— it does not get a `\cvprfinalcopy` borrowed from a different venue.

## 3. Scaffold the copy

Output directory: `wkdrs/builds/<cycle>_<template>_<date>/` in `convert` mode; the
package's source directory in a pack run. Either way it is regenerated whole.

Copy in, byte-for-byte and unedited:

- every `.cls`, `.sty`, and `.bst` from `cycls/<cycle>/template/` → the copy's `stys/`
  (the kit's example `.tex`, README, and sample figures stay behind — the copy holds
  what compiles the paper, nothing else)
- `manus/stys/stage.sty` → the copy's `stys/` — **the authoring layer ships
  verbatim.** It is a self-contained package, loads its content-level packages
  without options (so a second load under a class that already has them is a
  no-op), and carries `\todo`, `\parahead`, `\cmark`, `\tablestyle`, the `x`/`y`/`z`/
  `P`/`Y` column types, the `Light*` row colors, `\figref`/`\tabref`/`\eqnref`, the
  `accentcolor` fallback, and `\graphicspath{{figs/}}`. This is the layer that was
  designed to survive the swap; do not re-implement any of it in `compat.sty`.
- `manus/secs/`, `manus/tabs/` → unedited
- `manus/figs/*.pdf` → the copy's `figs/`. **Not `figs/srcs/`**: rendered figures
  are what the paper needs, and a plotting script or `.drawio` file can carry a
  path, a username, or a machine name into an anonymous submission.
- `manus/bibs/reference.bib` → the copy's `bibs/`

A venue needing a different citation style is a `\bibliographystyle{...}` change in
the generated `main.tex`, never an edit to `reference.bib`.

## 4. Generate `compat.sty`

`stage.sty` covers the macros the writing skills emit. What it deliberately does
**not** cover is the content-level packages `stys/arxiv.cls` loads on top of it —
and a section or table written against those breaks under a venue class that loads
none of them. `compat.sty` closes exactly that gap:

| Provided by `arxiv.cls`, absent from `stage.sty` | Reaches body files as |
|---|---|
| `algorithm`, `algpseudocode` | `\begin{algorithm}`, `\State`, `\Require` |
| `\algref{alg}{line}` — the class's two-argument form (`arxiv.cls:104`) | a line-level algorithm reference; `stage.sty` provides only the one-argument fallback |
| `mathtools`, `bm` | `\coloneqq`, `\bm{}`, `\DeclarePairedDelimiter` |
| `siunitx` | `\SI{}`, `\num{}` |
| `nicematrix` | `NiceTabular` |
| `enumitem` | `\begin{itemize}[leftmargin=*]` |

**Add only what the copied body files actually use.** Scan `secs/`, `tabs/`, and
`figs/` for each construct and include its package only on a hit. Copying
`arxiv.cls`'s whole `\RequirePackage` list into `compat.sty` is how option clashes
get manufactured: the venue class has usually loaded its own hyperref, geometry,
and caption setup with options that a bare second load will fight.

Load order in the generated `main.tex`: the venue class, then `stys/stage`, then
`compat`. Anything `compat.sty` defines that the venue class already defines uses
`\providecommand` — never `\renewcommand` over a venue macro.

## 5. Generate `main.tex`

Built from the venue's own macros (step 2) filled with values read out of
`manus/main.tex`. Follow `\input` chains reachable from that preamble: values are
not always written literally in `main.tex` — `/skill:stage-outl-planner` moves the
abstract into `manus/secs/0_abstract.tex` and leaves an `\input` behind.

Carried over:

- **Title, authors, affiliations, contribution notes, keywords, metadata links**,
  re-emitted through the venue's macros. See the table below for what each
  `arxiv.cls` command holds.
- **Paper-specific `\newcommand` / `\renewcommand`** from `manus/main.tex`'s own
  preamble — `\method` and its kind. These are the paper's, not the framework's,
  so they are not in `stage.sty` or `compat.sty`, and the body depends on them.
- **The `\input{secs/...}` order**, exactly as `manus/main.tex` fixes it — the
  `<n>_` prefix is load-bearing (conventions §5.5).
- **`\bibliographystyle{...}`** set to the kit's style; `\bibliography{bibs/reference}`.
- **The appendix**, if `manus/main.tex` has one, as the venue's own appendix
  mechanism. Venues differ on whether the appendix precedes or follows the
  references; follow the kit's example, and say in the report which order was used.

### What `arxiv.cls` owns

Every command below is defined by `stys/arxiv.cls` and by nothing else. Under a
venue class each one is either re-expressed through a native equivalent or dropped
— left as-is, it is an undefined control sequence and the copy does not compile.

| `arxiv.cls` command | Line | Becomes |
|---|---|---|
| `\affiliation[key]{...}` | 330 | the venue's affiliation macro |
| `\contribution[mark]{...}` | 335 | the venue's equal-contribution / corresponding-author note, or a `\thanks` |
| `\keywords{...}` | 341 | the venue's keywords macro, or dropped when it has none |
| `\code` `\project` `\dataset` | 351–354 | a links line in the venue's own idiom, or dropped; redacted under anonymity |
| `\correspondence{...}` | 355 | the venue's corresponding-author note |
| `\paperdate{...}` | 356 | dropped — venue classes date the proceedings themselves |
| `\paperstyle{...}` `\papercolor{...}` | 359, 180 | **dropped.** These drive `arxiv.cls`'s title panel and have no venue equivalent |
| `\beginappendix` | 617 | the venue's appendix mechanism, usually `\appendix` |
| `\metadata[label]{value}` | — | a links line, or dropped |

### The abstract moves

The one relocation that is easy to miss and always breaks the build when missed.

`arxiv.cls` takes the abstract as a **preamble command**, `\abstract{...}`, so
`manus/main.tex` calls it before `\begin{document}` and `/skill:stage-outl-planner`'s
`\input{secs/0_abstract}` sits in the preamble too. Nearly every venue class wants
a **body environment**, `\begin{abstract}...\end{abstract}` after `\maketitle`.

So: extract the abstract text — from `\abstract{...}` in `manus/main.tex`, or from
whatever file the preamble `\input`s — and re-emit it through the venue's own
mechanism in the body. Do **not** `\input{secs/0_abstract}` into the generated
preamble: the venue class either does not define `\abstract` at all (compile error)
or defines an incompatible one (silently wrong output). The rest of `secs/` is
`\input` normally inside the body, unchanged.

### Anonymity

Not a separate mode — it follows what the run is already doing:

| Run | `venue.yml` | The copy |
|---|---|---|
| `convert`, or a review pack | `anonymized: true` | anonymous: authors "Anonymous Author(s)", affiliations "Anonymous Institution", `\code`/`\project`/`\dataset` URLs replaced with "Link redacted for review", the kit's anonymity switch on |
| `camera` pack | `anonymized: false` | full metadata, the kit's final-copy switch on |

`.env`'s `ANON` and `venue.yml`'s `anonymized:` disagreeing is already a stop in
the main workflow (conventions §3.4) — the conversion never resolves it by picking
one.

## 6. Build, iterate, count pages

Build the copy through the same entrypoint and the same engine as everything else:

```
bash execs/run.sh --main <copy>/main.tex
```

It compiles with the copy's own directory as the working directory and the copy's
`stys/` on TEXINPUTS, so a build that passes proves the copy is self-contained —
which is the point. Products land in `<copy>/.build/`, never in `wkdrs/builds/`,
so the manuscript build that `lint.sh --no-build` reuses is not clobbered.

`--main` arrived with this feature, so a paper repository whose `execs/run.sh`
predates it would pass the flag to latexmk as an unknown option. Check once, before
building: `bash execs/run.sh --help` lists `--main` or it does not. When it does
not, stop — the copy is written and the build is the step that could not run — and
give the one-line fix: `bash execs/update.sh`, which syncs the entrypoint along with
the skill trees and the workflow docs. If a run of that leaves `--main` still absent,
this repository's `update.sh` predates self-syncing too — a current one installs its
own replacement, an older one cannot — so both entrypoints have to be copied from
upstream by hand, and saying so is the report. Never paper over it with a bare `latexmk`
line: §3.3 puts every build through the entrypoint so the engine comes from one
place, and a package built by a different command is not evidence that
`execs/run.sh` can build it.

On failure, fix `compat.sty` or the generated `main.tex` and rebuild. Never patch a
venue file (contract rule 3), and never drop content to make it compile — content
that cannot be mapped is reported, not deleted.

**The page count from this build is the one that counts.** `lint.sh` measures the
preprint build, which is a different document in a different class: useful as a
drafting proxy, not as the answer to whether the paper fits. Compare this count
against `page_limit_main`:

- **pack run, over the limit** — a hard block, routed to `/skill:stage-copy-editor`.
- **`convert` run, over the limit** — reported with the overflow, no gate.
- **`confirmed:` unset in `venue.yml`** — report the count and say the limit is
  unconfirmed. An unconfirmed limit binds nothing (conventions §9c).

## 7. Report

Two places, and the split is the point: the chat reply is read once, the follow-up
list is read on the next run.

**`tasks/<cycle>_venue.md`** — every finding that needs a human, one `- [ ]` line
each with a stable `V<n>` id and the skill that owns the fix. Written by `convert`
only; a pack run reads it and puts its own findings in `SUBMISSION_<date>.md`
instead. Update it, never regenerate it: read the existing file first, keep every
checked item checked and do not re-raise it, append genuinely new findings with the
next free id, and check — with the reason, never delete — an item that no longer
applies. A conversion run for the twentieth time should produce an empty diff on a
list the user has already worked through.

**The chat reply**, verdict first, then:

- where the copy is and its page count against the limit, with the limit's
  confirmation state
- what was mapped: the class and options, the title-metadata macros used, the
  bibliography style, the anonymity switch, what `compat.sty` had to add
- what was **dropped**, one line each — `\paperstyle`, `\papercolor`, `\paperdate`
  and anything else with no venue equivalent
- what needs a human: a venue rule the conversion does not automate, a package the
  kit does not provide that the content needs, anything that could not be mapped
  one-to-one, the appendix ordering choice

Never let a gap pass silently to make the report look clean. A conversion that
compiled by quietly dropping the keywords is a conversion that will surprise
someone at the portal.
