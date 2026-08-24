# Natural scholarly prose in STAGE

**Language:** English | [简体中文](human-writing-guide.zh-CN.md)

STAGE produces one research paper whose claims remain traceable from manuscript sentence to evidence.
In this workflow, natural writing is not a cosmetic pass applied after the scholarship is finished.
It is the act of making that traceable argument easy for a reviewer to follow without adding importance, certainty, detail, or personality that the repository does not support.

This guide governs prose decisions made by `stage-sect-drafter`, `stage-copy-editor`, and the clarity perspective of `stage-peer-reviewer`.
The fabrication, citation, attribution, and ownership rules in [writing-workflow-conventions.md](writing-workflow-conventions.md) remain authoritative.

## 1. Read the paper's records before judging its voice

Naturalness in STAGE is constrained by records, not by a generic style prompt.
Before drafting or revising a passage, load the records that control it:

| Record | What it decides about the prose |
|---|---|
| `notes/story.md` | the paper's pitch, problem, key idea, and claimed contributions; prose may sharpen these but not broaden them |
| `notes/claims.md` | the exact claim, its type, where it is stated, its evidence, and its current strength; this is the semantic boundary of a rewrite |
| `mates/MANIFEST.md` and the mapped `mates/` file | whether a result is fingerprinted and what the evidence actually contains |
| `notes/refs/<ABBREV>.md` | what the paper may say about a cited work; the `## Citable facts` section, not the bibliography entry alone, backs the sentence |
| `notes/outline.md` | the job and page budget of each `manus/secs/<n>_<slug>.tex` file |
| `notes/notation.md` | canonical terms, symbols, abbreviations, and first-use locations |
| `notes/style.md`, when present | author-confirmed choices about voice and cadence; it supplies preferences, never facts or claims |
| `cycls/<cycle>/venue.yml` and `.env` `ANON` | confirmed length and anonymity constraints |

If these records disagree, prose is not the place to reconcile them silently.
Report the conflict to the workflow that owns the record.

## 2. The trace must survive the edit

STAGE has two different units: the **paragraph is the unit of composition**, while the **sentence is the unit of audit**.
A paragraph may be reorganized to improve reasoning, but every resulting sentence must still preserve its place in the traceability chain.

### Results and other external numbers

A number in prose must remain connected to its claim-ledger row, the row's evidence link, and a fingerprinted `mates/` entry.
A `% src:` comment covers exactly the sentence it heads.
Do not move a sourced sentence away from its comment, merge it with a sentence governed by another source, or split it without deciding which source covers each result.

If an edit exposes an unsupported number, retain or add `\todo{...}` and make the ledger debt visible through the owning workflow.
Never improve specificity by supplying a remembered value.

### Statements about cited work

Keep a literature sentence no stronger or broader than the corresponding reading note.
Grouped citations are not decorative: if a sentence attributes one property to three papers, each paper's note must support that property.
Changing “uses” to “requires”, or “evaluates” to “demonstrates”, is a claim change even when the sentence sounds smoother.

### Claim strength and attribution

Preserve whether a claim is `proposed`, `drafted`, `verified`, `unsourced`, `weakened`, or `dropped` in `notes/claims.md`.
Do not turn an observed association into a causal result, a result under evaluated conditions into a universal conclusion, or a component contribution into a paper-level contribution.
The actor also matters: keep separate what this paper establishes, what the evidence source reports, what prior work claims, and what remains the authors' interpretation.

### Protected manuscript structure

Treat citation keys, labels, references, equations, LaTeX commands, `\todo{}` markers, `% src:` comments, canonical terms, and venue-required wording as protected.
Keep one sentence per source line so that a source comment and the sentence it governs retain a stable two-line shape.
An edit may change punctuation or sentence boundaries only after rechecking that these structural relationships still hold.

## 3. Write each paper component for its actual job

Formulaic prose often appears when a passage performs a generic academic function instead of the function assigned to it by STAGE.
Use the repository's structure to recover that function.

| Passage | STAGE check | Revise toward |
|---|---|---|
| Abstract | pitch and contribution claim IDs in `notes/story.md`; verified scope in the ledger | problem, method distinction, supported result, and bounded contribution without ceremonial setup |
| Introduction | section brief and contribution rows | the concrete gap and why the proposed idea addresses it; no unsupported “paradigm shift” framing |
| Related work | reading notes and terminology canon | proposition–source–difference relationships; no anonymous “prior studies show” narration |
| Method | notation, claim type, and section brief | actor, operation, inputs, outputs, and design reason; passive voice is fine when agency is immaterial |
| Experiments | fingerprinted evidence and result claims | setup sufficient to interpret the result, the result itself, then only the inference the evidence supports |
| Table or figure caption | the artifact's purpose in the outline and its source mapping | what is shown, how to read it, and the supported takeaway; never a second abstract |
| Limitations | evaluated scope and weakened or unsourced claims | the exact boundary, its consequence, and what evidence would resolve it |
| Conclusion | pitch, verified claims, and unresolved boundaries | the question answered by this paper; no generic promise that the field will continue to flourish |

Page pressure does not authorize meaning loss.
When trimming toward the active cycle's confirmed budget, remove repeated setup, duplicated interpretation, and empty signposting before qualifications, evidence, or technical distinctions.

## 4. Diagnose failures in the argument, not forbidden words

`lint.sh` uses category labels so it can point a human to likely review sites.
The labels describe possible failures in a STAGE argument; they are not a blacklist and do not classify authorship.

- `inflated-significance`: the prose claims importance beyond the mapped contribution or verified consequence.
- `vague-attribution`: a source-bearing assertion has no identifiable paper, evidence producer, or authorial owner.
- `shallow-analysis`: a result is followed by “highlighting”, “underscoring”, “从而彰显”, or a similar tail that skips the actual inference.
- `formulaic-contrast`: “not only X but Y”, “不仅……而且……”, or a balanced triad stages a distinction that the method or claim ledger does not need.
- `stock-signposting`: the prose announces a section or observation that the heading and paragraph order already make clear.
- `generic-outlook`: a limitation or conclusion ends in optimism without naming an unresolved claim, missing evidence, or concrete research question.
- `manufactured-depth`: a slogan, dramatic fragment, or “the real question is” construction supplies emphasis that the evidence has not earned.
- `stock-diction`: several decorative abstractions accumulate where the canonical technical term would be more precise.
- `chatbot-residue`: greetings, praise, apologies, knowledge-cutoff disclaimers, or invitations to continue have leaked into manuscript prose.

One occurrence of *however*, an em dash, passive voice, a three-item list, a long sentence, or a formal term is not a defect.
Keep any construction that performs a necessary comparison, marks a real inference, preserves conventional technical wording, or matches an author-confirmed sample.
Except for clear chatbot residue, review a passage because several signals reinforce one another or because the same template recurs across sections.

## 5. Use the author profile without manufacturing a persona

`notes/style.md` is optional and `stage-copy-editor style` is its only writer.
When it exists, use its samples to recover observable choices: sentence length and rhythm, voice, paragraph openers, transitions, hedging, enumeration, tense, math density, punctuation, and constructions the paper avoids.

The precedence is fixed:

1. evidence and citation boundaries;
2. the claim ledger;
3. `notes/notation.md` and venue rules;
4. the style profile.

A sample supplies settings, never reusable sentences.
Do not infer a paper-wide persona from one paragraph, import the voice of a cited author, or add humor, emotion, autobiography, deliberate errors, or first-person commentary to appear less machine-like.
When no profile exists, use a restrained scholarly default: concrete claim first, stable terminology, explicit agency where it affects interpretation, and sentence length driven by the reasoning.

The profile binds prose under `manus/` only.
It does not rewrite workflow records or override the venue-defined register of a response to reviewers.

## 6. Rewrite with a protected-content comparison

For a section draft or polish pass:

1. Resolve the section through `notes/outline.md` and state the paragraph's job in terms of its assigned claims.
2. Freeze literal invariants: numbers, math, keys, labels, references, `% src:` comments, `\todo{}` markers, and canonical terms.
3. Freeze semantic invariants: claim strength, scope, attribution, comparison set, experimental condition, and evidence-required qualifiers.
4. Identify the paragraph's current claim–support–inference sequence.
5. Rewrite the paragraph around that sequence; do not replace watched words one by one.
6. Compare the result against both inventories and the relevant ledger and reading-note rows.
7. Restore one sentence per line, then build with `bash execs/run.sh` and inspect `bash execs/scpts/lint.sh`.

Leave a passage unchanged and report it when natural wording would require any of the following:

- evidence that has not been imported or fingerprinted;
- a stronger or different ledger claim;
- a fact absent from a cited work's reading note;
- a new canonical term or a changed technical distinction;
- removal of a qualifier needed to remain within the evaluated conditions.

Those are research-record decisions, not copy edits.

## 7. Separate the three workflow roles

The same guide supports three different responsibilities:

- `stage-sect-drafter` forms the first claim–support–inference structure from the section brief, mapped claims, and evidence.
  It updates the section and its bookkeeping together; it never fills a gap with plausible prose.
- `stage-copy-editor` is the only role that rewrites prose for naturalness.
  It freezes protected content, edits at paragraph scale, checks the section budget, builds, and records anything it cannot safely change.
- `stage-peer-reviewer` is read-only.
  Its clarity perspective compares openings, contribution statements, related-work summaries, result interpretations, and conclusions across the paper, then anchors formulaic or promotional passages as review findings.

The deterministic lint is narrower than these judgment passes.
It scans section prose and table-caption prose, ignores LaTeX comments and structural commands, warns on standalone high-confidence chatbot residue or clustered ordinary patterns, and never blocks a submission solely for style.
A clean lint result therefore means “no configured pattern fired”, not “the prose is natural”.

## 8. Completion criteria

A passage is ready when all of the following hold:

- **traceability:** every external number and cited assertion still reaches its required STAGE record;
- **claim fidelity:** no assertion became broader, stronger, more causal, or differently attributed;
- **local function:** the paragraph performs the job assigned by its section brief and claims;
- **technical stability:** notation and terminology agree with the canon;
- **economy:** every sentence advances the claim, support, inference, limitation, or necessary navigation;
- **authorial consistency:** observable choices agree with `notes/style.md`, when one exists;
- **review resistance:** importance, novelty, and conclusions are stated at the strength a skeptical reviewer can verify.

There is deliberately no numerical “human score”.
Prose features cannot establish whether AI produced a passage, and evading an AI detector is not a STAGE objective.
