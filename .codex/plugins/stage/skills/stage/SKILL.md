---
name: stage
description: Route an explicitly invoked $stage request to exactly one STAGE academic-writing workflow skill. With no request, show the current paper status. Do not use after a specific stage-* skill has already been selected.
---

# Route a STAGE request

Read `.agents/commands/stage.md` from the current project root and follow it as the authoritative routing roster.
Write the user-facing wording in the language the workflow conventions §7.6 resolve: an explicit request in the conversation first, then `STAGE_LANG=en|zh` in `.env`, then the conversation's language. `.agents/commands/stage.md` is the only roster; its skill names and routing decisions do not change with the language.

Adapt only its invocation spelling for Codex:

- `$stage` is this generic router.
- `$stage-<name> <argument>` invokes the selected project skill where the roster writes `/stage-<name> <argument>`.
- `$stage-auto <goal>` is the spelling where the roster writes `/stage-auto <goal>`: this plugin's goal-run entry, which the user types.

Do not reproduce a selected skill's workflow from this router.
For an unmarked skill, load and follow that `stage-*` skill from the current project's available skills.
For a skill marked `†`, request the confirmation required by the roster, show the exact `$stage-<name> <argument>` invocation, and wait.

If `.agents/commands/stage.md` is missing, report that the project does not contain the STAGE routing roster instead of guessing from the plugin package.
