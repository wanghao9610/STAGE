# Project Memory — index

What earlier sessions in this repository learned, one line per memory, newest
first. The session hooks under `.claude/hooks/`, `.codex/hooks/`, `.cursor/hooks/`
and `.kimi-code/hooks/` parse these lines byte-exactly, so the shape is fixed:

    - <type> · <scope> · <verified> · [<slug>](<slug>.md) — <one line>
    - env · machine:mbp-a · 2026-08-03 · [xelatex-only](xelatex-only.md) — arxiv.cls builds here only under xelatex

`<type>` is `env`, `pref`, `insight`, or `deadend`. `<scope>` is `global`,
`machine:<name>`, `cycle:<cycle>`, or `manus:<path>`. `<verified>` is the date
the fact was last confirmed true, as `YYYY-MM-DD`. The separator between the
first four fields is a space, a middle dot, and a space; everything after the em
dash is free text. Only lines starting with `- ` are read.

Nothing that a repository file already owns goes here — a number belongs to
`mates/`, a claim to `notes/claims.md`, a page limit to the cycle's `venue.yml`.
Machine-specific memories live in `local/`, which git ignores. Full rules — what
belongs here, the file format, how a memory is retired:
`docs/mds/stage-workflow/memory_spec.md`.

<!-- entries below -->
