# STAGE skill roots (Pi)

Pi can discover the same sixteen `stage-*` skills from `.pi/skills/` and `.agents/skills/`. `.pi/settings.json` excludes the shared root so only the Pi-native copy is loaded and no name collision is reported.

If that exclusion is removed, follow `.pi/skills/`. The shared `.agents/skills/` root is deliberately tool-neutral; the Pi copy names Pi's own tools and the extensions below.

Skills are invoked as `/stage-<name>` through `.pi/prompts/`. `enableSkillCommands` is false, so there is no duplicate `/skill:stage-<name>` command. This keeps the six slash-only skills reachable only through their prompt templates.

## What `.pi/extensions/` adds

- `stage_subagent`: delegates to `.pi/agents/` as `stage-collector`, `stage-implementer`, or `stage-auditor`.
- `stage_questionnaire`: asks one structured question with the recommended option marked.
- `/stage-plan`: the user's read-only exploration switch; a skill cannot turn it on for them.
- A confirmation gate for `rm -rf`, `sudo`, and `chmod 777`.

These extensions load only after the project is trusted. If one is unavailable, follow the skill's stated fallback without weakening any confirmation or evidence rule.
