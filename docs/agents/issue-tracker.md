# Issue tracker: OpenSpec

This repo does not track agent work in GitHub Issues. Everything lives in
`openspec/`, as files in the repo. Do not run `gh issue ...`.

## Layout

- `openspec/changes/<change-id>/` — one in-flight piece of work. Contains
  `proposal.md` (the problem and the plan), `design.md` (decisions), and
  `tasks.md` (a numbered checklist of the actual work).
- `openspec/changes/archive/<YYYY-MM-DD>-<change-id>/` — finished changes.
- `openspec/specs/<capability>/spec.md` — docs for shipped capabilities.
- `openspec/config.yaml` — project context and writing rules that apply to
  everything in here.

A "ticket" is one numbered checkbox line in a change's `tasks.md`
(for example `1.2`). A change folder is the unit that holds them.

## Conventions

- **Create work**: use the `/opsx:propose` skill. It creates the change folder
  and writes `proposal.md`, `design.md`, and `tasks.md` together. Don't
  hand-create a change folder unless the user asks.
- **Read work**: read the three files in `openspec/changes/<change-id>/`.
  Check `openspec/changes/archive/` too if the change might already be done.
- **List open work**: list the directories in `openspec/changes/`, skipping
  `archive`.
- **Implement**: use `/opsx:apply`. Tick tasks off in `tasks.md` as they land.
- **Comment**: append to the bottom of `proposal.md` under a `## Notes`
  heading. There is no comment thread.
- **Close**: use `/opsx:archive`, which moves the folder into
  `openspec/changes/archive/` and updates `openspec/specs/`.

## When a skill says "publish to the issue tracker"

Write an OpenSpec change: run `/opsx:propose`, or add tasks to the `tasks.md`
of an existing change if the work belongs to one already.

## When a skill says "fetch the relevant ticket"

Read `openspec/changes/<change-id>/proposal.md`, `design.md`, and `tasks.md`.
If the user gave a task number like `3.1`, that line in `tasks.md` is the ticket.

## Wayfinding operations

Used by `/wayfinder`. The map is a change folder; the children are its tasks.

- **Map**: `openspec/changes/<change-id>/proposal.md`, with Notes,
  Decisions-so-far, and Fog as headings at the bottom.
- **Child ticket**: a numbered checkbox in `tasks.md`. Mark type inline, e.g.
  `1.2 (research) ...`, using `research`/`prototype`/`grilling`/`task`.
- **Blocking**: write `blocked by 1.1` at the end of the task line. A task is
  unblocked once every task it names is ticked.
- **Frontier**: first unticked, unblocked, unclaimed task in file order.
- **Claim**: append `(claimed)` to the task line and save before starting.
- **Resolve**: tick the checkbox, then add the answer under
  Decisions-so-far in `proposal.md`.
