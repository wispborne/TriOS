---
status: accepted
---

# Modpacks travel inside links and remain local

A shared modpack link contains its complete compressed definition. TriLink
does not store packs, and TriOS keeps each person's library locally. An
optional update URL can provide a newer integer version, but the embedded copy
keeps the link independent of that host.

## Considered options

- A central pack service or short code would make links smaller, but every
  pack would depend on that service's storage, uptime, abuse controls, and
  continued maintenance.
- Uncompressed definitions would be easier to inspect, but large packs would
  exceed browser and Windows URL limits.

## Consequences

- Links are capped at 30,000 characters and use compressed, versioned
  payloads.
- Pack identity supports duplicate and update handling but does not prove
  authorship across computers.
- TriOS calculates local item coverage instead of tracking a pack-level
  installation record.
