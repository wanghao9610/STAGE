# Poster Layout

How `stage-pstr-builder` turns a confirmed sheet size and an approved cut into a source file that
compiles to one page of the right dimensions. Loaded before `plan`, `render`, or `check`. `SKILL.md`
states the rules; this file is the procedure and the numbers.

The shape in one line: **the sheet size is a venue fact, the layout is a choice made once and
recorded in the plan, and the font sizes are arithmetic.**

## 1. Sheet sizes

The size comes from `cycls/<cycle>/venue.yml` with `confirmed:` set (conventions §9c). This table
exists to check a confirmed value against a plausible one and to convert units — never to supply a
size the user has not confirmed.

| Name | Portrait (w × h) | Landscape (w × h) |
|---|---|---|
| A0 | 841 × 1189 mm | 1189 × 841 mm |
| A1 | 594 × 841 mm | 841 × 594 mm |
| US large | 36 × 48 in (914 × 1219 mm) | 48 × 36 in (1219 × 914 mm) |
| US board | — | 4 × 8 ft board (1219 × 2438 mm) — the *board*, not the sheet |

Two traps. A venue that states a **board** size is stating the furniture, not the paper: the sheet
must fit inside it with margin, and the sheet size is still the user's to confirm. And a venue that
states a maximum ("posters must not exceed A0") has given a bound, not a size — record what the
user chooses to print, and note the bound beside it.

## 2. The two layouts

Chosen at `plan` time, recorded as `layout:` in `POSTER_PLAN.md`, and not changed by a later `render`
without going back through `plan`.

### `billboard` (default)

The takeaway owns the middle of the sheet and everything else is support. This is the layout the
poster-design literature converged on because it matches how a hall is actually read — someone
decides from across the aisle whether to walk over.

```
┌───────────────────────────────────────────────┐
│ T  title · authors · affiliations             │  ~10% height
├───────────┬───────────────────────┬───────────┤
│ L         │ K                     │ R         │
│ problem   │ THE TAKEAWAY          │ results   │  ~65% height
│ method    │ one sentence, largest │ evidence  │
│           │ type on the sheet     │           │
│  ~22%     │  ~46% width           │  ~22%     │
├───────────┴───────────────────────┴───────────┤
│ F  QR · contact · bibkey                      │  ~10% height
└───────────────────────────────────────────────┘
```

Zone K carries the takeaway sentence and at most one supporting graphic — usually the teaser. The
sidebars carry the claims that did not make the centre, one block each, figure over caption. Nothing
in L or R may be required to understand K.

### `imrad` (classic)

Three columns, reading left to right, for venues and fields that expect the paper's own structure.
Use it when the venue's guidance asks for it, not by preference.

```
┌───────────────────────────────────────────────┐
│ T  title · authors · affiliations             │
├───────────────┬───────────────┬───────────────┤
│ C1            │ C2            │ C3            │
│ motivation    │ method        │ results       │
│ contribution  │ setup         │ conclusion    │
├───────────────┴───────────────┴───────────────┤
│ F  QR · contact · bibkey                      │
└───────────────────────────────────────────────┘
```

The takeaway still exists in this layout: it is the first block of C1, set at title scale. A poster
whose reader must reach column 3 to learn the result has been laid out wrong whatever the venue asked.

## 3. Point-size floors

**Where these numbers come from.** They are the design conventions the poster-guidance literature
agrees on, not measurements taken in this repository, and they are stated here so the gate has
something to check rather than an impression. A venue that publishes its own minimums outranks this
table; record the venue's numbers in `POSTER_PLAN.md` and check against those instead.

| Element | Floor (effective pt) | Read from |
|---|---|---|
| Takeaway / title | 72 | ~4 m |
| Authors, affiliations | 36 | ~3 m |
| Block headers | 36 | ~2 m |
| Body text, figure captions | 24 | ~1.5 m |
| Smallest text anywhere (contact, bibkey, axis labels inside a figure) | 20 | ~1 m |

**Effective size is arithmetic, not appearance.** A poster class sets a base size for the sheet it
declares; anything authored at one size and printed at another scales with the ratio:

```
effective_pt = authored_pt × (print_width / authored_width)
```

So a body font of 25pt authored on A0 (841 mm wide) and printed at 36 in (914 mm) is effectively
25 × 914/841 ≈ 27pt — above the floor. The same file printed on A1 (594 mm) is effectively
25 × 594/841 ≈ 18pt, and fails. Compute it; do not look at it.

Two sizes escape the class's base font and must be checked separately: text **inside** an included
figure PDF, which scales with the box the figure is placed in, not with the document font; and
anything set in an explicit `\fontsize`. The `check` gate names the smallest text on the sheet with
its computed size, and a figure whose internal labels fall under 20pt at its placed width is a
finding for `/stage-figs-designer` — never a re-plot here (SKILL.md Principle 4).

## 4. The house template

Used when the venue supplies a size but no kit. `tikzposter` is the class: it is standalone, its
block model maps one-to-one onto the plan's zone table, and one `\block` per zone row keeps
generation mechanical enough to audit.

```latex
\documentclass[a0paper, portrait, 25pt]{tikzposter}
\usepackage{graphicx}
% \usepackage{qrcode}   % only when a QR target was supplied

\title{...}                    % the paper title, verbatim from manus/main.tex
\author{...}                   % supplied by the user; ANON is not inherited
\institute{...}

\begin{document}
\maketitle                                        % zone T

\begin{columns}
  \column{0.22}
    \block{...}{...}                              % zone L
  \column{0.46}
    \block{\Huge ...}{...}                        % zone K — the takeaway
  \column{0.22}
    % src: mates/<slug>/<file>#<anchor>
    \block{...}{...}                              % zone R
\end{columns}
\end{document}
```

Rules that hold whichever class is in play:

1. **One block per zone row, in the plan's order.** A block with no row, or a row with no block, is
   the drift the no-argument audit reports.
2. **`% src:` sits on the line above the number it sources**, one comment per number — the same
   discipline `/stage-tabs-builder` applies to table rows, so `/stage-clms-auditor` can walk the
   poster the way it walks a table.
3. **Figures are included by relative path from `manus/figs/`**, unmodified. Scale with the
   `width` argument only; never `trim`, `clip`, or a recolor.
4. **No `\todo` macro is defined here at all.** The manuscript's third state does not exist on a
   poster (SKILL.md Principle 3), and a class where the macro is undefined fails loudly at compile
   time rather than printing a marker onto a wall.
5. **Column widths sum to less than 1.** `tikzposter` adds inter-column spacing; widths that sum to
   exactly 1 overflow the sheet, which the `fits` check catches only after a wasted render.

## 5. When the venue supplies a kit

Copy it whole into `cycls/<cycle>/poster/template/`, byte-for-byte, unedited, and record
`poster_template:` in `venue.yml` naming the class inside it. Then §4's house skeleton is not used:
the kit's own class, its own block or column commands, and its own title macros are, and the zone
map is a mapping onto whatever structure the kit provides rather than onto `tikzposter`'s.

Everything in §3 still applies — a supplied kit sets a look, not a legibility floor, and its example
content is an example, not a constraint. When the kit will not compile as delivered, the fix goes in
the generated `poster.tex` or in the report, never in the kit's files: this is
`/stage-subm-packer`'s Principle 7 boundary, and it holds for the same reason — a class edited to
compile locally is wrong in a way that surfaces at the print shop.

## 6. Checks that need a command

- **Page size and count.** Read them off the render rather than trusting the class:
  `pdfinfo wkdrs/builds/poster/poster.pdf` reports `Page size` in points (1 in = 72 pt) and `Pages`,
  which must be exactly 1. Compare against the confirmed sheet within a millimetre.
- **Grayscale.** Convert a copy and look at it — every distinction the poster relies on (series,
  highlight, panel grouping) must survive. Where the toolchain cannot convert, say so and name what
  was checked by reasoning about the palette instead; do not report a check that was not run.
- **QR target.** The URL or DOI is the user's, supplied and recorded in the plan's frontmatter. Fetch
  nothing to construct it, and never recall an arXiv id — a wrong QR code sends a whole hall to
  someone else's paper.
