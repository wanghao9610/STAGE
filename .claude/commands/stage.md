---
description: Route a request to the right STAGE skill, or report the next action
argument-hint: "[what you want to do]"
disable-model-invocation: true
---

Read `.agents/commands/stage.md` and apply its router to this request: [$ARGUMENTS]

For an unmarked skill, start the Claude-owned copy with the Skill tool so its model, effort, and fork settings apply. An empty request selects `stage-flow-status` with no argument.
