---
name: "OPSX: Propose"
description: Propose a new change - create it and generate all artifacts in one step
category: Workflow
tags: [workflow, artifacts, experimental]
---

Propose a new change - create the change and generate all artifacts in one step.

I'll create a change with artifacts:
- proposal.md (what & why)
- design.md (how)
- tasks.md (implementation steps)

When ready to implement, run /opsx:apply

---

**Input**: The argument after `/opsx:propose` is the change name (kebab-case), OR a description of what the user wants to build.

**Steps**

1. **If no input provided, ask what they want to build**

   Use the **AskUserQuestion tool** (open-ended, no preset options) to ask:
   > "What change do you want to work on? Describe what you want to build or fix."

   From their description, derive a kebab-case name (e.g., "add user authentication" → `add-user-auth`).

   **IMPORTANT**: Do NOT proceed without understanding what the user wants to build.

2. **Create the change directory**

   Create `openspec/changes/<name>/` with a `.openspec.yaml` file:
   ```yaml
   schema: spec-driven
   created: YYYY-MM-DD
   ```

   Use today's date for the `created` field.

3. **Read project context**

   Read `openspec/config.yaml` for:
   - `context`: Project background (use as constraints when writing artifacts — do NOT include in output files)
   - `rules`: Per-artifact rules if any (use as constraints — do NOT include in output files)

4. **Create artifacts in sequence**

   Create each artifact in dependency order. Read each completed artifact before writing the next.

   a. **proposal.md** — What and why
      - Problem statement, proposed solution, scope, non-goals
      - Keep it concise

   b. **specs** (optional) — Only if the change introduces new capabilities that need formal specification
      - Create under `openspec/changes/<name>/specs/<capability>/spec.md`
      - Each spec covers one capability with requirements, acceptance criteria
      - Skip if the change is simple enough that proposal + design cover it

   c. **design.md** — How
      - Technical approach, key decisions, file changes
      - Reference proposal and any specs for context

   d. **tasks.md** — Implementation steps
      - Checkbox list of concrete tasks: `- [ ] Task description`
      - Each task should be small and focused
      - Order tasks by dependency (do prerequisite work first)

   **If an artifact requires user input** (unclear context):
   - Use **AskUserQuestion tool** to clarify
   - Then continue with creation

5. **Show final summary**

   List all artifacts created and their locations.

**Output**

After completing all artifacts, summarize:
- Change name and location
- List of artifacts created with brief descriptions
- What's ready: "All artifacts created! Ready for implementation."
- Prompt: "Run `/opsx:apply` to start implementing."

**Artifact Creation Guidelines**

- Use project context from `openspec/config.yaml` as constraints, not content — do NOT copy context blocks into artifacts
- Read each completed artifact before writing the next one
- Keep artifacts concise and actionable

**Guardrails**
- Create ALL standard artifacts (proposal, design, tasks) unless explicitly told otherwise
- Always read previous artifacts before creating the next one
- If context is critically unclear, ask the user — but prefer making reasonable decisions to keep momentum
- If a change with that name already exists, ask if user wants to continue it or create a new one
- Verify each artifact file exists after writing before proceeding to next
