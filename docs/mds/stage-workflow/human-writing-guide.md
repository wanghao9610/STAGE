# Clear writing in an evidence-bound paper

This guide applies shared checks for formulaic writing to STAGE manuscript prose.
The goal is clear, natural scholarship in the author's voice, not authorship detection or detector evasion.
It governs `stage-sect-drafter`, `stage-copy-editor`, and the clarity review in `stage-peer-reviewer`; the [writing workflow conventions](writing-workflow-conventions.md) remain authoritative.

## 1. Preserve content and provenance

A style edit may reorganize prose, but it must not change what the paper can claim.

- Read the controlling records first: `notes/story.md`, `notes/outline.md`, `notes/claims.md`, mapped `mates/` evidence, `notes/refs/`, `notes/notation.md`, `notes/style.md`, and the active venue and anonymity rules.
  Report conflicts instead of resolving them in prose; evidence, citations, and the claim ledger outrank style.
- Preserve numbers, math, citations, keys, labels, LaTeX, `% src:` comments, `\todo{}`, canonical terms, claim strength and scope, attribution, comparison sets, conditions, uncertainty, and required qualifiers.
- Every number and assertion about cited work must retain its trace.
  Missing support stays visible through `\todo{...}` or the owning workflow; never supply a plausible value, source, or fact.
- If a revision would add, remove, move, weaken, or strengthen a claim, it is not style-only.
  Route it through the owning workflow and update `notes/claims.md` in the same change.

## 2. Match the writer and the paper

Follow an author-confirmed sample when one exists.
Match its observable vocabulary, sentence movement, punctuation, transitions, qualification, first-person practice, and deliberate repetition without borrowing sentences or adding facts, opinions, humor, or disorder.
Without a sample, use restrained, direct scholarly prose.

- Lead with the substantive point and prefer canonical terms and simple verbs.
  Name the actor when agency affects interpretation.
- Organize each paragraph around its mapped claim–support–inference sequence and the job assigned in `notes/outline.md`.
- State results under their exact conditions, separate observation from inference, and keep limitations as visible as positive findings.
- Keep manuscript prose in English, preserve anonymity, and use only the space the argument needs.
- Let sentence length and paragraph shape follow the reasoning.
  End on a supported result, limitation, or useful transition, not generic optimism.
- Add personality only when the author-confirmed voice and scholarly context call for it.
  Never manufacture a persona.

## 3. Review pattern clusters

Treat these as editing signals, not banned forms or evidence of AI authorship.
Rewrite at paragraph scale when several signals accumulate, one template recurs, or a pattern introduces an unsupported claim.

| Review for | Rewrite toward |
| --- | --- |
| Inflated significance, sales language, name-dropping, unsupported superlatives, or stock optimism | The exact result and only its supported consequence. |
| Vague attribution, knowledge-limit disclaimers, or plausible guesses | A named, verified source and checkable proposition; otherwise an explicit gap or deletion. |
| Shallow analytical tails, abstract action chains, hidden actors, or stacked qualifiers | A direct fact–inference link, a clear actor where needed, and only evidentially necessary qualification. |
| Repeated “not X but Y,” forced triads or ranges, fake objections or alternatives, staged candor, slogans, or a claimed “deeper truth” | The real relation, constraint, or choice without drafting scaffolds. |
| Stock signposting, repeated headings, filler, greetings, praise, apologies, previews, service offers, or generic endings | The content itself and only navigation the reader needs. |
| Synonym cycling, stock diction, repeated openings, uniform cadence, dramatic fragments, excessive dashes, decorative emphasis, label-heavy lists, or emojis | Stable names and syntax, rhythm, or formatting that has a clear function. |

Do not ban a word, transition, passive construction, first person, long sentence, list, or dash in isolation.
Keep a form when it carries a real relation, preserves technical meaning, or matches the author.
Never rewrite quotations, titles, notation, data, or literal fields merely because they match a watched pattern.
`lint.sh` labels configured instances such as `chatbot-residue`, `inflated-significance`, `vague-attribution`, `formulaic-contrast`, `stock-signposting`, `shallow-analysis`, `generic-outlook`, `manufactured-depth`, and `stock-diction`.
Its warnings locate passages for review; a clean scan only means that no configured pattern fired.
Do not assign a numerical “human score.”

## 4. Rewrite and verify

1. Resolve the section through `notes/outline.md` and state its job in terms of mapped claims.
2. Read the controlling records and mark all protected literal and semantic content.
3. Map the claim–support–inference sequence and diagnose patterns by paragraph.
4. Rewrite the unit around its substantive point; do not patch watched words one by one.
5. Compare the revision with the ledger, evidence, reading notes, notation, style profile, and original prose.
   Restore every dropped qualifier, trace, or attribution, and remove every added or strengthened claim.
6. Preserve one sentence per source line, then run `bash execs/run.sh` and `bash execs/scpts/lint.sh` after any `manus/` edit.

Leave the passage unchanged and report the issue if smoother prose would require unimported evidence, a different claim, an unsupported statement about prior work, a new canonical term, or removal of a necessary qualifier.
A revision is ready only when every number and cited assertion still traces, claim strength and attribution remain intact, and the paragraph performs its assigned job.
