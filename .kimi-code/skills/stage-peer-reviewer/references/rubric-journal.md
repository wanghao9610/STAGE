# Journal Rubric — decision tiers and the required-revisions discipline

Journals decide a *process*, not just a verdict: the tier states what happens next and who checks
it. Choose the tier by answering, in order: (1) is the contribution at the journal's bar at all?
(2) do the required changes need new experiments or re-derivation? (3) does checking the changes
need a re-review, or can an editor confirm them?

## The tiers

**Accept.** Publishable as is, or with editorial fixes an editor can confirm without re-review
(typos, formatting, a clarified sentence). Rare on a first round; recommending it means the
majors list is empty and the minors are cosmetic.

**Minor Revision.** The contribution is at the bar and the claims are sound; every required
change is bounded and needs no new experiments to validate a core claim — added discussion, a
clarified proof step, an extra ablation that decorates rather than carries. The same reviewer can
confirm the changes quickly, and rejection is off the table if the authors do what is asked.

**Major Revision.** The core promise is there, but at least one gap touches the validity or
completeness of the main claims — missing experiments, a derivation to repair, a comparison to
run. Acceptance is genuinely uncertain pending the result: if the requested experiment could not
plausibly change the decision, it belongs in Minor; if no result could save the paper, the honest
tier is Reject, and asking for a revision anyway wastes a year of everyone's time.

**Reject (& Resubmit, where the journal offers it).** The contribution is below the journal's bar
or a flaw is beyond repair within a revision: the delta over verified prior work is not there,
the central claim is unsound, or the scope mismatches the journal. Use Resubmit only when a
genuinely different paper — new method, new evidence — could emerge from the same line of work.

## Required-revisions list

Every tier below Accept carries a numbered list; it is the contract the revision will be judged
against, so write it like one:

- Each item is imperative, specific, and traceable to an anchored weakness in the reviews — "Add
  a comparison to the paper's own [ref 23] under equal training budget (Tab. 2)" — never "improve
  the experiments".
- Split **Required** from **Suggested**. Required items decide the next round; suggested items may
  not be used to reject a revision that did the required ones. Blurring the two is how review
  processes turn adversarial.
- For Major Revision, state for each required item what outcome would satisfy it — the authors
  should be able to know, before resubmitting, whether they have met the bar.

## Caps and the conference mapping

The caps logic of `rubric-conference.md` binds here through the tiers: an unsound central claim
or verified undiscussed prior art doing the core contribution → Reject; a missing closest
baseline or a reparable soundness gap → Major Revision at best; presentation problems alone never
push below Minor Revision.

For the collector contract's `overall_lean` (a 6-point value), map: Accept→5–6, Minor
Revision→4, Major Revision→3, Reject & Resubmit→2, Reject→1–2.

## Journal notes

Verify against the journal's live author/reviewer guidelines before relying on any of these;
policies change.

- **TPAMI-style extension rules**: an extension of a conference paper must carry substantial new
  material (commonly cited around 30%+: new method components, new theory, or significantly
  expanded evaluation). An extension whose delta is prose alone is a Reject on policy, not on
  science — check the conference version (whitelist or verified only) and review the *delta*.
- **Length-flexible venues** (TPAMI, IJCV, JMLR): "the appendix will fix it" is not available as
  an excuse — completeness of proofs and experimental detail is judged in the main text.
- **Letters/short-format venues** (SPL-style): judge the contribution at the format's size; do not
  require the breadth of a full paper, do require the one claim to be airtight.
