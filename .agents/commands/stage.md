# Route a STAGE request

Use the roster below to route a paper-writing request to exactly one workflow skill.

| Skill | | Purpose |
| --- | --- | --- |
| `stage-proj-adopt` | † | Adopt an existing paper repository |
| `stage-evid-curator` | | Import and register evidence |
| `stage-stry-coach` | † | Shape the story and seed claims |
| `stage-outl-planner` | † | Plan sections, budgets, figures, tables, and notation |
| `stage-sect-drafter` | | Draft one section |
| `stage-tabs-builder` | | Build one evidence-traced table |
| `stage-figs-designer` | | Plan, build, or audit one figure |
| `stage-refs-curator` | | Curate bibliography records and reading notes |
| `stage-copy-editor` | | Polish prose without changing claims |
| `stage-clms-auditor` | | Trace every manuscript number |
| `stage-cite-auditor` | | Verify every citation assertion |
| `stage-peer-reviewer` | | Simulate a five-perspective review |
| `stage-resp-writer` | † | Draft the response and promise list |
| `stage-subm-packer` | † | Preflight and package the submission |
| `stage-pstr-builder` | † | Plan, build, or check the poster |
| `stage-flow-status` | | Report status and the single next action |

The six skills marked † are explicit-only because each controls an author-owned decision. This generic `/stage` router never starts one: ask for explicit confirmation, give the exact `/stage-<name> <argument>` command, and wait. The other ten may be selected when the request plainly matches.

If the request is empty, select `stage-flow-status`. Otherwise, name the chosen skill, give the one-line reason, and pass through the request as its argument. Start an unmarked skill through the active harness's native skill mechanism and use that harness's owned copy. If two skills are equally plausible, ask one concise question instead of blending their scopes. Never bypass a skill by producing its owned artifact from general knowledge.
