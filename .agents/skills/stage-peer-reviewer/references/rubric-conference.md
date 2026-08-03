# Conference Rubric — the 6-point scale, confidence, and caps

The score is the band whose description the paper matches — found by reading the bands, not by
averaging the panel. When two bands both seem to fit, the caps table below decides; when it is
silent, take the lower band and say in the justification what would have earned the higher one.

## The six bands

**6 — Strong Accept.** Top handful of papers in its area this cycle. The contribution changes how
people will work on the problem, the evidence is thorough enough that the panel found no major
weakness, and the writing lets a non-specialist see why it matters. You would champion it in the
committee and spend credibility on it.

**5 — Accept.** A solid, clearly-above-bar contribution. The claims are supported, the closest
baselines are beaten fairly or the insight stands without a leaderboard, and the majors list is
empty — what weaknesses exist are minors the camera-ready can absorb. You would argue for it,
without needing to spend credibility.

**4 — Borderline Accept.** The contribution outweighs the flaws. There is at least one real major
weakness, but it is fixable within a revision cycle and does not touch the core claim. You would
not fight for this paper, but you would not object to its acceptance; a good rebuttal moves it up.

**3 — Borderline Reject.** The flaws outweigh the contribution as submitted. The core idea may be
sound, but a major weakness touches the main claim — a missing closest baseline, an
underspecified core component, an overclaim the evidence cannot carry. A strong rebuttal could
convince you; the default is rejection.

**2 — Reject.** A significant flaw in novelty, soundness, or experiments that a rebuttal cannot
repair: the central claim is unsupported or the delta over verified prior work is not there. The
work needs another research cycle, not another draft.

**1 — Strong Reject.** Fatally flawed, out of scope for the venue, or ethically compromised
(plagiarism signals, undisclosed test-set use, fabricated-looking results). State the fatal flaw
in one sentence; if ethics are involved, note that it would be flagged to the chairs, and stop
elaborating the science.

## Confidence (1–5)

- **5** — You checked the math and the tables line by line and know the closest prior work firsthand.
- **4** — You checked the parts the score rests on; an expert could still surprise you on details.
- **3** — You understood the paper but did not verify the derivations, or the area is adjacent to your depth.
- **2** — Substantial parts are outside what you could verify; the score leans on the parts you could.
- **1** — An educated guess; say so, and say what expertise the area chair should recruit.

The panel's synthesis usually lands at 3–4. Claim 5 only when a derivation or table was actually
re-verified during the run; the justification must say which.

## Caps table

A cap binds regardless of every other merit. Apply the lowest triggered cap, and name the cap in
the justification.

| Confirmed finding | Cap |
|---|---|
| Central claim unsound — invalid derivation, broken proof, or evaluation that does not measure the claim | 2 |
| Verified prior work does the core contribution and is undiscussed | 2 |
| Verified prior work overlaps the core contribution substantially but partially, undiscussed | 3 |
| Obviously-closest baseline missing or run at an unfair disadvantage | 3 |
| Core method underspecified past reimplementation, and the appendix does not repair it | 3 |
| Headline prose claim contradicted by the paper's own table | 3 |
| Single benchmark carries the entire conclusion where the venue expects breadth | 4 |
| Ethics signal (plagiarism, data misuse, fabrication suspicion) | 1–2, flagged to chairs |

Clarity alone neither caps below 3 nor lifts anything: a paper the panel could not evaluate for
its writing gets 3 with confidence ≤2 and an explicit statement of what could not be judged.

## Venue mapping

The 6-point score is this skill's native scale. When the target venue's form differs, report the
native score plus the mapped value. Scales drift year to year — confirm against the venue's live
review form before pasting anything into it.

| Venue family (typical form) | Mapping from the 6-point score |
|---|---|
| NeurIPS / ICLR-style 1–10 overall | 1→1–2, 2→3, 3→4–5, 4→6, 5→7–8, 6→9–10 |
| ACL Rolling Review 1–5 overall (half points) | 1→1–1.5, 2→2, 3→2.5–3, 4→3.5, 5→4–4.5, 6→5 |
| CVPR/ICCV-style ordinal labels (SR/R/WR/WA/A/SA) | one-to-one, 1→Strong Reject … 6→Strong Accept |
| AAAI-style 1–10 | as the NeurIPS row |

The justification paragraph is written once, against the native band — the mapping changes the
number, never the argument.
