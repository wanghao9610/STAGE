---
name: stage-auto
description: Pursue the paper goal an explicitly invoked /stage-auto request states, starting each next unmarked STAGE skill under that invocation's grant and stopping at any skill marked †. Do not use unless the user typed /stage-auto.
disableModelInvocation: true
---

# Pursue a paper goal

Read `.agents/commands/stage-auto.md` from the current project root and follow it as the authoritative procedure.
Write the user-facing wording in the language the workflow conventions §7.6 resolve: an explicit request in the conversation first, then `STAGE_LANG=en|zh` in `.env`, then the conversation's language. `.agents/commands/stage-auto.md` is the only procedure; its decisions do not change with the language.

Adapt only its invocation spelling for Kimi Code:

- `/stage-auto` (shorthand for `/skill:stage-auto`) `<goal> [involve=<level>]` is this command.
- `/skill:stage-<name> <argument>` is the spelling where the shared file writes `/stage-<name> <argument>`.

For an unmarked skill, start it with the Skill tool and follow the Kimi-owned copy from the current project's available skills.
A skill marked `†` is never started: show the exact `/skill:stage-<name> <argument>` invocation as the run's closing line and stop, as the shared file says.

If `.agents/commands/stage-auto.md` is missing, report that the project does not contain the STAGE goal-run procedure instead of guessing from the plugin package.
