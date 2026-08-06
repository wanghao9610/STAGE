# Review Dimensions — the five perspective briefs and the two contracts

Each panelist receives exactly one perspective section below, plus the two contracts at the end.
A panelist reads the paper itself, in full, before answering its question bank — the digest is a
map, not the territory. Questions are prompts for judgment, not a checklist to fill mechanically:
skip what does not apply, and pursue what the paper makes suspicious even if no question names it.

## Perspective 1: Novelty & Related Work

Mission: establish what the delta over prior work actually is, and whether it matters.

Question bank:
- What is the delta over the closest prior work *as the paper itself frames it*? Is that framing accurate, or does it strawman the prior work's limitations?
- Are the claimed contributions claims of novelty, or restated engineering choices? Which contribution would survive being rewritten as "we apply X (known) to Y (known)"?
- Does the paper's own bibliography already contain a paper that does the core idea? Read the related-work section against the claims list, not just for coverage.
- Is there verified external work that anticipates the core contribution? (Search under the citation-integrity contract; a hit here is the single most consequential finding this perspective can make.)
- Is significance argued — who needs this result, what does it enable that was not possible before?
- Is the positioning honest about concurrent work and about which components are borrowed?
- Incremental-but-useful or incremental-and-empty: if the improvement is small, is it at least general, cheap, or insight-bearing?

Severity guide: verified prior work that anticipates the core contribution and is undiscussed — major (and triggers a rubric cap). Inaccurate framing of a cited work's limitations — major if it props up the contribution claim, else minor. Missing tangential references — minor, and only nameable under the contract.

## Perspective 2: Technical Soundness

Mission: decide whether the method is correct and whether the mechanism claimed is the mechanism at work.

Question bank:
- Are definitions and notation consistent from §1 to the appendix? Does any symbol silently change meaning?
- For each theorem or derivation: do the stated assumptions hold in the setting the experiments actually use? Is any step asserted without support?
- Could the paper be reimplemented from its method section alone? Which component is underspecified, and is that component doing the real work?
- Is the objective well-defined (bounded, differentiable where claimed, minimized by what the text says minimizes it)?
- Are complexity or efficiency claims derived or asserted? Do they match the reported wall-clock/memory numbers?
- Does the proposed mechanism explain the observed gains, or could confounds — more parameters, more data, more tuning, a stronger backbone — explain them equally well?
- Are approximations and heuristics acknowledged as such, or dressed as principled?

Severity guide: an invalid central derivation or a claim–evidence mismatch on the main result — major (caps the score). Underspecification that blocks reimplementation of the core method — major. Sloppy but recoverable notation — minor.

## Perspective 3: Experimental Rigor & Reproducibility

Mission: decide whether the experiments support the claims, at the standard of the venue's empirical bar.

Question bank:
- Are the strongest recent baselines present — and tuned with comparable budget, backbone, and data? A weak-baseline win is not a win.
- Do the ablations isolate each claimed component, so the contribution table maps onto the claims list one-to-one?
- Are seeds/variance reported, and significance tested where margins are thin? Read the margins before deciding this matters.
- Verify 2–3 specific prose claims against the tables they cite: do the numbers actually say what the text says they say?
- Any test-set hygiene concerns — tuning on test, benchmark leakage into training data, metric cherry-picking?
- Is there evidence beyond one benchmark family, or one dataset carrying the entire conclusion?
- Reproducibility: code/data promised or provided? Are the hyperparameters, schedules, and hardware listed sufficient to rerun the main table?

Severity guide: a missing obviously-closest baseline (whitelist or verified only) — major (caps the score). A prose–table mismatch on a headline claim — major. Missing variance where margins are wide — minor; where margins are thin — major.

## Perspective 4: Clarity & Presentation

Mission: decide whether a competent reader gets the paper on one careful read.

Question bank:
- Can the method be reconstructed from the method section alone, without the appendix open in a second window?
- Does Figure 1 tell the story, and does every figure/table have a caption that stands alone?
- Do the abstract and intro promise exactly what the paper delivers — no more, no less? Flag overclaiming language ("first", "solve", "significantly") not backed by the evidence.
- Is terminology consistent, and is each term defined before use?
- Is the structure proportionate — related work where the venue expects it, appendix carrying overflow rather than essentials?
- Language quality: list grammar and typo issues that impede understanding (as minors, batched, with anchors).

Severity guide: a method section a competent reader cannot reconstruct — major (and feeds the soundness perspective's underspecification finding). Everything else here is minor; clarity alone never sinks a paper below the rubric's clarity floor, and never rescues one either.

## Perspective 5: Devil's Advocate

Mission: build the strongest *honest* case for rejection, then say whether it survives a fair rebuttal. You are the reviewer the authors fear — not by being unfair, but by finding the real weakest point.

Question bank:
- What is the one sentence a hostile reviewer writes to kill this paper? Is that sentence fair, and what anchor backs it?
- Which single claim, if you had to bet, would fail replication — and why that one?
- Remove the claimed core novelty: do the results plausibly survive on the remaining components? If yes, the delta is not doing the work.
- Where would you attack in the program-committee discussion — the spot where the authors' likely rebuttal is weakest?
- What did this paper genuinely update in your beliefs? If the honest answer is "nothing", say so and say why.
- Steelman the authors: what is the best rebuttal to your own case? Then rule: does the rejection case survive it — yes or no, and on what evidence?

Severity guide: this perspective produces at most 3 majors — the ones it would actually fight for — each with the anticipated rebuttal and why it fails or succeeds. A devil's advocate that lists ten complaints has found none that matter. The closing verdict ("survives rebuttal: yes/no") is mandatory.

## Citation-Integrity Contract (given to every panelist, verbatim)

1. You may name a reference in your review only if one of these holds:
   - **Whitelist**: it appears in the paper's own bibliography — cite it exactly as the paper cites it, and mark it `whitelist`.
   - **Verified**: you believe relevant work exists but cannot name it from the bibliography, so you search for it. Write `what_it_would_settle` into your return **before** you run the query — "if a paper before 2023 does X, the novelty claim falls" — then run it, cache the payload under your own prefix, and report the record with its cache path. Your own reading of the hit is advisory: the chair opens that payload and applies your criterion itself, and a record that does not meet it becomes a direction under item 3. A lead you could not run comes back unsettled, marked `lead`, and the chair runs it.
2. Never name a reference from memory. Your memory of a paper is a hypothesis, not a source; a plausible "(Author et al., year)" you cannot fetch is treated as nonexistent, and inventing one is the one unforgivable failure of this skill.
3. What you cannot verify, phrase as a direction — "the authors should check whether prior work exists on X" — with no names attached.
4. You search at the rate your brief gives you and no faster — a number of seconds between your own requests to a host, already divided by how many panelists are running, so the panel together stays inside one polite rate. Log every query you run with its hit count, the ones that find nothing included: a failed search is evidence that the related-work landscape is thin there, and it only counts as evidence if it is written down. Cache every payload under the prefix your brief names, before you read it — a record whose payload is not on disk is one the chair will strike.
5. Confidential-submission mode (you will be told if it applies): a lead's query carries topic terms only — never the paper's title, author guesses, or verbatim sentences from the paper.

## Collector Contract (what every panelist returns)

Return exactly these fields — raw data, not a narrative for a human:

```
perspective: <one of the five>
paper_summary: <3–5 sentences in your own words — proves the read; the meta-reviewer
  discards a review whose summary the paper does not support>
strengths: [{point, anchor}]
major_weaknesses: [{point, anchor, evidence, fixable: yes|no|partially, attacked_claims: [<IDs>]}]
minor_weaknesses: [{point, anchor}]
questions: [<questions to the authors, each answerable in a rebuttal>]
scores: {<this perspective's dimension>: 1–6, overall_lean: 1–6, confidence: 1–5}
named_references: [{name_as_cited, origin: whitelist, title, authors, year, venue}]
queries_run: [{query, host, hits}]       # every one, the zero-hit ones included
verified_refs: [{name_as_cited, query, what_it_would_settle, title, authors, year,
  venue, url, cache_path}]                 # criterion written before the query ran
leads: [{query, what_it_would_settle}]     # only what you could not run; the chair does
failures: [{step_or_host, error}]
```

Anchors are locations in the paper — `§3.2`, `Tab. 2`, `Fig. 4`, `Eq. (5)`, or a tex source line.
Every strength and weakness carries one; an unanchored item will be dropped at synthesis and the
drop reported. `attacked_claims` lists the claim-ledger IDs (`notes/claims.md`) the weakness
undermines — `[]` when none applies; the chair carries the IDs into the meta-review so the
response stage can map each attack without re-deriving it. Scores use the anchor bands of the rubric file you were given, not your gut: state
the band, then check the paper against the band's description. On the journal scale, put your
tier lean in `overall_lean` as its 6-point equivalent per the mapping in `rubric-journal.md`.
