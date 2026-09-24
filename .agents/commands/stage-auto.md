# Pursue a paper goal

The user has typed `stage-auto`, and this file is what that invocation runs. Typing it is the goal-run grant of the workflow conventions §11.5: the one request that already authorizes a multi-step pursuit. Every run ends with its report and the exact next command and starts nothing further (conventions §11.4); this command is what continues. While this run pursues its goal, it may start, without asking again, each of the ten unmarked skills that a named next action points to on the way to that goal, and, where a named action does not advance the goal, the unmarked skill that owns the goal's own next step (The loop, step 1). A started run behaves exactly as if the user had typed its name: the same scope, the same confirmation points, the same write limits, the same commit step (conventions §1). The grant covers nothing else. A skill marked † is never started (conventions §11.1). The run never answers a mandatory confirmation point (§7.7) or an ask-first choice of `AGENTS.md` §1 on the user's behalf, and never widens what a started run may write.

Invocation shape: `stage-auto <GOAL> [involve=<level>]`.

## Parse the invocation

- Strip `involve=<level>` first, wherever it sits (conventions §7.7). This run's level is that token; with no token, it is `INVOLVE` in `.env`, and `medium` when that is absent, unset, or invalid. A plain-language instruction during the run changes it as §7.7 says. A goal run has no default of its own: it resolves the level exactly as every skill does.
- What remains is the goal, in the user's own words: `stage-auto the method section drafted and its numbers audited`, `stage-auto a simulated review of the current draft`. With no goal, ask for one. Never infer a goal from the repository.
- One goal per invocation. The next goal is the next invocation.
- A goal that asks where the paper stands, rather than naming a state to reach, is `stage-flow-status`'s: run it once, relay its report, and stop. Such a goal asks to be told, not to have the paper changed, so it starts no writing skill (conventions §11.4).

## Before the loop

Read `STAGE_LANG` and `INVOLVE` from `.env` once (conventions §7.6, §7.7), and reply in the language §7.6 resolves. Snapshot `git status --porcelain` as well: a path dirty now is never staged by a run this invocation starts (conventions §1.5), and the final reply names it. Then turn the goal into a check this run can verify on disk, such as:

- a row status in `notes/outline.md` (§8.5): a section reaching `drafted` or `polished`, a figure or table reaching `draft` or `final`;
- claim statuses in `notes/claims.md`: the claims a section states, audited during this invocation, none left `proposed` or `drafted`;
- a file this invocation writes, such as `cycls/<cycle>/reviews/SIM_REVIEW_<date>.md` or an audit report under `wkdrs/reports/`, created or rewritten during this invocation; a file left by an earlier session, even one dated today, proves nothing;
- a lint finding the goal names, such as the page count under the active cycle's `page_limit_main` or a section's undefined references;
- `bash execs/run.sh` building the manuscript.

A status check trusts only the skill that owns the field: a section row is `drafted` because `stage-sect-drafter` set it and `polished` because `stage-copy-editor` did, and a claim is `verified` only because `stage-clms-auditor` traced it.

A check against a `venue.yml` value, such as `page_limit_main`, holds only while that file's `confirmed:` is set (§9c). With it empty, the goal is not pursued against that value: a limit the goal itself states is checked instead, and with none, the run stops and prints `/stage-stry-coach` as its closing line.

Green lint is never the check, even when the goal mentions lint. A visible `\todo{}` fails lint by design (conventions §9a), and only evidence the user imports can clear it, so a run waiting for green lint would never end: the lint verdict is reported, not pursued. A goal that names lint is turned into the concrete findings it points at, as above, or it is asked about.

A goal that cannot be turned into such a check is asked about, not pursued. A goal that only an action outside the grant could meet (What a goal run never does, below) — a finalized story or outline, imported evidence, a response to reviewers, a frozen submission — is not pursued either: name the command that owns it as the closing line, and stop.

Open with one line stating the check and the resolved level.

## The loop

1. Run `stage-flow-status` through the harness's native skill mechanism and take its one next action. Every next action, from status or from a run, passes the goal filter first. An action that does not advance the goal's check is not taken: say so in one line, list it in the final reply, and take the goal's own next step instead. That step is the skill that owns the goal's target, when the inputs its own `SKILL.md` requires already exist; where one is missing, it is the owner of the first missing input in `stage-flow-status`'s priority order. A red lint gate advances the goal only when it blocks the goal's check — a build that breaks, a page count over the limit the goal names; a `\todo{}` outside the goal's target does not. An action that passes the filter still meets steps 6 and 7 before step 2 takes it.
2. Take what the action names:
   - **One of the ten unmarked skills.** Announce one line (what matched, which target), then start it through the harness's native skill mechanism with this run's resolved level appended as an `involve=<level>` token, or with the level a printed command spelled out when that one asks more; a spelled-out level never lowers this run's. One unit of work per start (conventions §11.3): one section per `stage-sect-drafter` run, one table, one figure. `stage-evid-curator` starts only in its read-only `check` mode, and no start takes a mode that exists to take the author's choice — `stage-refs-curator discover` or `position`, `stage-copy-editor style`, `stage-peer-reviewer extern=`: where the next action needs one, stop and print its command as the closing line.
   - **A skill marked †.** The run never starts one, and dispatches nothing else to run it. Stop, and print its exact `/stage-<name> <argument>` command as the closing line, with `involve=<level>` spelled out when the level differs from the one `.env` resolves to (conventions §7.5).
   - **A STOP-line action** (conventions §2) — an evidence import, a tool install, a submission, an experiment — or any other action outside the grant (below): stop, and print the command or name the action as the closing line, without taking it.
3. Questions. An unsettled target names its candidates and waits (§5.3). A mandatory confirmation point (§7.7) and an `AGENTS.md` §1 ask-first choice are asked and waited on at every involve level, whichever run raises them. The loop never answers one itself; where nobody can answer, as in a headless run, it stops there and reports. A judgment call a started run hands back is answered at `low` with its marked recommendation and logged (§7.8); at `medium` and `high` it goes to the user. Once a question is answered, start the same skill again on the same target, with the question and its answer passed along; a skill that resumes from disk picks up where it stopped.
4. After each run ends, take the next action it names, through the goal filter and step 2. This loop takes it, never the run that named it, even where the goal's words ask for more (conventions §11.4), so nothing is started twice. Where it names none, run `stage-flow-status` again.
5. An action that failed is not retried on the same target. The fix a failure routes to — an unsupported claim to the section that states it, a missing reading note to `stage-refs-curator`, a broken build to the section whose source broke — is itself a next action, taken once through step 2. When that fails too, stop.
6. Skip, one line each, and look for what else bears on the goal: a unit whose owner already ran in this invocation and left its `\todo{}` in place, because only evidence clears it (conventions §9a); a follow-up that routes its fix upstream, to a value `mates/` does not hold; and an open promise in `tasks/<cycle>_promises.md` whose change a run of this invocation already made, because ticking its box stays the author's.
7. The same skill starts on the same target and mode a second time only after another run has made progress (Where it ends), and never a third time; restarting it after an answered question (step 3) continues the first start rather than repeating it. Otherwise stop, with what the earlier run said blocks it.

## What a goal run never does

These stay outside the grant whatever the goal says and whatever level resolves. The run stops at the first one it would need and prints it as its closing line instead of taking it; what step 6 sets aside is the exception, and ends the run only when nothing else bears on the goal (Where it ends):

- start a skill marked †: `stage-proj-adopt`, `stage-stry-coach`, `stage-outl-planner`, `stage-resp-writer`, `stage-subm-packer`, or `stage-pstr-builder`;
- import, register, or refresh evidence: nothing in a goal run writes `mates/` (conventions §10.1);
- enter a venue fact: a `venue.yml` value is only ever user-confirmed (§9c);
- answer a mandatory confirmation point or an `AGENTS.md` §1 ask-first choice on the user's behalf;
- cross the STOP line (§2): the command is handed over exactly as §2 says;
- commit, push, or tag on its own: each started run keeps its own commit step (§1) — offered at `medium` and `high`, taken at `low` — and nothing else commits;
- launch long-running work in the background or wait on it;
- write a note, prose, or report of its own: every file it leaves behind was written by a run it started;
- remove or reword a `\todo{}`, or ask a run to rewrite a sentence so that it no longer needs its value (§9a);
- tick a box in `tasks/<cycle>_promises.md`, or pass a started run a number, reason, or authorization the user did not type, beyond the marked recommendation step 3 takes for a judgment call at `low` (§7.7).

## Where it ends

Report and stop at the first of:

- the goal's check passes;
- the next action that bears on the goal is a skill marked †, a STOP-line action, or another action outside the grant, other than what step 6 skips;
- a mandatory question has nobody to answer it;
- a check needs a `venue.yml` value whose `confirmed:` is empty, and the goal states no limit of its own;
- nothing bearing on the goal is left but what step 6 skipped. Where some of it waits on a value `mates/` does not hold, the evidence route is the author's choice: produce the result in the paired STAR repository, behind its own STOP line, then `/stage-evid-curator import`; or drop the file under `mates/manual/` and run `/stage-evid-curator register <path>`, whose provenance question is the author's. Where some of it is an open promise, the reply lists the boxes to tick, each with the commit that made its change or the paths it left uncommitted;
- step 7 refuses a repeat;
- a full pass made no progress. A pass is one `stage-flow-status` run and every action it led to, a restart after an answered question included. It made no progress when it wrote no durable file under `manus/`, `notes/`, `tasks/`, or `cycls/<cycle>/reviews/` and moved no status field (§8.5 row statuses, ledger statuses) or `tasks/` checkbox. A build, a commit, or a report regenerated under `wkdrs/` is not progress;
- step 5 runs out of moves.

The final reply lists:

- the runs, and the files each one wrote;
- every commit the runs made, with its message and file count (§1.6);
- the build path and page count, and the lint verdict, from the last run that built; red lint from a visible `\todo{}` is a remaining gate, not a failure;
- the ledger rows that changed;
- the goal check's result;
- the actions skipped as not advancing the goal, the units and promises step 6 skipped, the repeats step 7 refused, and the judgment calls taken at `low`, with their count (§7.8);
- each `\todo{}` left in the goal's scope, with its text and what would unblock it;
- every path already dirty when the invocation began, which no run staged; evidence among them under `mates/` — `stage-evid-curator` never commits — wants committing before or with the manuscript commits whose `% src:` anchors cite it;
- why the run stopped: the check passing, the † command or action outside the grant it reached, the pending question verbatim, the unconfirmed venue value, the evidence or promise boxes only the author can supply, the repeat refused, that a full pass made no progress, or the failed action and its error.

It ends with one closing line carrying the exact command (conventions §7.5): the † command or STOP-line command where the run stopped; `/stage-stry-coach` for an unconfirmed venue value; the evidence route's two commands when only evidence the author must supply is left; for a mandatory question nobody could answer, answering it and typing the same `stage-auto` invocation again; after a pass with no progress or a failed fix, the concrete action most likely to clear the block; the earliest remaining step when the check passed and work remains; or, when nothing is left, that plainly. Nothing carries between invocations. Typing the command again resumes from the repository as the runs left it.
