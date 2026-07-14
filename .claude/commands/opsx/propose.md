---
name: "OPSX: Propose"
description: Propose a new change — create it and write all its planning documents in one step
category: Workflow
tags: [workflow, artifacts, experimental]
---

Propose a new change — create the change and write all its planning documents in one step.

I'll create a change (a named unit of planned work) with these documents:
- proposal.md (what & why)
- design.md (how)
- tasks.md (the steps to build it)

When you're ready to build, run /opsx:apply

---

**Input**: whatever comes after `/opsx:propose` is either the change name (kebab-case) or a description of what the user wants to build.

**Steps**

1. **If there's no input, ask what they want to build**

   Use the **AskUserQuestion tool** (open-ended, no preset options):
   > "What change do you want to work on? Describe what you want to build or fix."

   Turn their description into a kebab-case name (e.g. "add user authentication" → `add-user-auth`).

   **IMPORTANT**: don't proceed until you understand what the user wants to build.

2. **Create the change directory**

   Create `openspec/changes/<name>/` with a `.openspec.yaml` file:
   ```yaml
   schema: spec-driven
   created: YYYY-MM-DD
   ```

   Use today's date for `created`.

3. **Read the project context**

   Read `openspec/config.yaml` for:
   - `context`: project background — use it to guide the documents, but don't copy it into them
   - `rules`: any per-document rules — same idea, follow them but don't copy them in

4. **Write the documents in order**

   Write each one in order, since each builds on the last. Read each finished document before writing the next.

   a. **proposal.md** — what and why
   - the problem, the proposed solution, what's in scope, what's out of scope
   - keep it short

   b. **specs** (optional) — only if the change adds new features that need spelling out in detail
   - create under `openspec/changes/<name>/specs/<capability>/spec.md`
   - each spec covers one feature: what it should do and how you'll know it's done
   - skip this if the proposal and design already cover it

   c. **design.md** — how
   - the technical approach, the key decisions, which files change
   - look back at the proposal and any specs for context

   d. **tasks.md** — the steps to build it
   - a checkbox list of concrete tasks: `- [ ] Task description`
   - keep each task small and focused
   - order them so prerequisites come first

   **If you're missing information to write a document**:
   - use the **AskUserQuestion tool** to clarify
   - then keep going

5. **Show a final summary**

   List every document you created and where it lives.

**Output**

When all the documents are done, summarize:
- the change name and location
- the documents created, each with a short description
- what's ready: "All documents created! Ready to build."
- next step: "Run `/opsx:apply` to start building."

**Guidelines**

- Use the project context and rules from `openspec/config.yaml` to guide the documents — don't copy those blocks into them
- Read each finished document before writing the next
- Keep documents short and specific

**Rules**
- Create all the standard documents (proposal, design, tasks) unless told otherwise
- Always read the previous documents before writing the next
- If the context is badly unclear, ask — but lean toward making a reasonable call and keeping momentum
- If a change with that name already exists, ask whether to continue it or start a new one
- After writing each file, check it exists before moving on
- **Do write clearly** — convey your meaning plainly and without jargon