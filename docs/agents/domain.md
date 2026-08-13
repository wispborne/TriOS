# Domain Docs

How the engineering skills should consume this repo's domain documentation when
exploring the codebase.

This repo is single-context: one `CONTEXT.md` and one `docs/adr/` folder, both
at the repo root.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root — the glossary of domain terms.
- **`docs/adr/`** — read the ADRs that touch the area you're about to work in.

If these files don't exist, **proceed silently**. Don't flag their absence;
don't suggest creating them upfront. The `/domain-modeling` skill (reached via
`/grill-with-docs` and `/improve-codebase-architecture`) creates them lazily
when terms or decisions actually get resolved.

## File structure

```
/
├── CONTEXT.md
├── docs/adr/
│   ├── 0001-some-decision.md
│   └── 0002-another-decision.md
└── lib/
```

## Use the glossary's vocabulary

When your output names a domain concept (in a change proposal, a task, a
refactor plan, a hypothesis, a test name), use the term as defined in
`CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either
you're inventing language the project doesn't use (reconsider) or there's a
real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than
silently overriding:

> _Contradicts ADR-0007 (event-sourced orders) — but worth reopening because…_
