# Evidence manifest

Ledger of everything under `mates/`. One `##` entry per file. Entries with
`source-type: star` are managed by `execs/scpts/import.sh` and rewritten on re-import;
entries with `source-type: manual` are written by `/stage-evid-curator` when registering
hand-dropped evidence, and `import.sh` never touches them. Entry format — see
`docs/mds/stage-workflow/writing-workflow-conventions.md` §8.

Evidence files are read-only: to fix a number, fix it at the source and re-import
(conventions §9). An evidence file with no entry here does not exist as far as the
writing skills are concerned.

<!-- entries below -->
