---
name: stage
description: Route an explicitly invoked /stage request to exactly one STAGE academic-writing workflow skill. With no request, show the current paper status. Do not use after a specific stage-* skill has already been selected.
disableModelInvocation: true
---

# Route a STAGE request

Read `.agents/commands/stage.md` from the current project root and follow it as the authoritative routing roster.
Write the user-facing wording in the language the workflow conventions §7.6 resolve: an explicit request in the conversation first, then `STAGE_LANG=en|zh` in `.env`, then the conversation's language, read from the user's latest message in their own words and never from a bare command line. `.agents/commands/stage.md` is the only roster; its skill names and routing decisions do not change with the language.

Adapt only its invocation spelling for Kimi Code:

- `/stage` (shorthand for `/skill:stage`) is this generic router.
- `/skill:stage-<name> <argument>` invokes the selected project skill where the roster writes `/stage-<name> <argument>`.
- `/stage-auto <goal>` (shorthand for `/skill:stage-auto`) stays as the roster writes it: this plugin's goal-run entry, which the user types.

Do not reproduce a selected skill's workflow from this router.
For an unmarked skill, start it with the Skill tool and follow the Kimi-owned copy from the current project's available skills.
For a skill marked `†`, show the exact `/skill:stage-<name> <argument>` invocation and stop; the user typing it is the confirmation.

If `.agents/commands/stage.md` is missing, report that the project does not contain the STAGE routing roster instead of guessing from the plugin package.
