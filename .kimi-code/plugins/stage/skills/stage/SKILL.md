---
name: stage
description: Route an explicitly invoked /stage request to exactly one STAGE academic-writing workflow skill. With no request, show the current paper status. Do not use after a specific stage-* skill has already been selected.
disableModelInvocation: true
---

# Route a STAGE request

Read `.agents/commands/stage.md` from the current project root and follow it as the authoritative routing roster.

Adapt only its invocation spelling for Kimi Code:

- `/stage` (shorthand for `/skill:stage`) is this generic router.
- `/skill:stage-<name> <argument>` invokes the selected project skill where the roster writes `/stage-<name> <argument>`.

Do not reproduce a selected skill's workflow from this router. For an unmarked skill, start it with the Skill tool and follow the Kimi-owned copy from the current project's available skills. For a skill marked `†`, request the confirmation required by the roster, show the exact `/skill:stage-<name> <argument>` invocation, and wait.

If `.agents/commands/stage.md` is missing, report that the project does not contain the STAGE routing roster instead of guessing from the plugin package.
