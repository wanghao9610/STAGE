// Zero-dependency `/stage` and `/stage-auto` slash commands. Each is a thin
// front door: the handler injects one follow-up turn that reads the shared
// file (`.agents/commands/stage.md` or `stage-auto.md`) and applies it to the
// user's request, so the model routes to the right STAGE skill and executes it,
// or pursues the typed paper goal. The shared files own the routing table, the
// "empty request selects stage-flow-status" rule, and the goal-run procedure;
// this shim only carries the argument across.
//
// No imports on purpose: this file is a project-local package linked into the
// profile, so its module path is the project directory and any `@deepseek-ai/*`
// import would fail parent-walk resolution. `ctx.commands` is injected and the
// follow-up message is built inline with the same shape `createUserMessage`
// produces.

const name = "stage";
const inject = ["commands"];

// DSH invokes a project skill as `/skill:stage-<name>` and registers no
// `/stage-<name>` command, so a command the shared files print for the user to
// type is respelled; every follow-up carries this line. `/stage-auto` is the one
// exception: it is no skill but the command this package registers below.
const spelling = "In DSH, a skill's command is `/skill:stage-<name> <argument>` wherever the shared file writes `/stage-<name> <argument>`, except `/stage-auto <goal>`, which DSH registers as a command and stays as written.";

function apply(ctx) {
  ctx.commands.register({
    name: "stage",
    description: "Route a request to the right STAGE writing workflow skill",
    input: { hint: "[what you want to do]" },
    // The request is injected verbatim as the follow-up message, so the
    // command/run log event must not duplicate it as `args`.
    recordInput: false,
    handler: ({ agent, rawInput }) => {
      const request = rawInput.trim();
      agent.followup({
        id: crypto.randomUUID(),
        role: "user",
        content: [{
          type: "text",
          text: request === ""
            ? "Read `.agents/commands/stage.md` and apply its router to an empty request (select `stage-flow-status`). " + spelling
            : `Read \`.agents/commands/stage.md\` and apply its router to this request: ${request}\n\n${spelling}`,
        }],
        source: { kind: "user" },
      });
      return { kind: "success" };
    },
  });
  ctx.commands.register({
    name: "stage-auto",
    description: "Pursue a stated paper goal across the STAGE skills",
    input: { hint: "GOAL [involve=LEVEL]" },
    // Same as /stage: the invocation is injected verbatim as the follow-up
    // message, so the command/run log event must not duplicate it as `args`.
    recordInput: false,
    handler: ({ agent, rawInput }) => {
      const invocation = rawInput.trim();
      agent.followup({
        id: crypto.randomUUID(),
        role: "user",
        content: [{
          type: "text",
          text: invocation === ""
            ? "Read `.agents/commands/stage-auto.md` and follow it; the invocation carries no goal, so ask for one. " + spelling
            : `Read \`.agents/commands/stage-auto.md\` and follow it with this invocation: ${invocation}\n\n${spelling}`,
        }],
        source: { kind: "user" },
      });
      return { kind: "success" };
    },
  });
}

export { apply, inject, name };
