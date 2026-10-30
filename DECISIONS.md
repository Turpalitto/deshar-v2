# Decisions

<!-- PROJECT-MEMORY-KIT:GENERATED -->
Record only important decisions using the ADR format in `memory/decisions/` or below.

## ADR-001 — Project Memory protocol

Status: Accepted
Date: 2026-10-23

### Context
Agents need a portable, project-local continuity layer.

### Decision
Use Markdown, JSON, Git, and the local stdlib-only Project Memory Kit.

### Why
Readable, portable, dependency-light, and independent of external LLM APIs.

### Alternatives considered
External vector/database memory; rejected for the initial implementation.

### Consequences
Agents must follow the repository protocol and keep summaries concise.


## ADR-002 — Native offline TV screensaver for native speakers

Use a separate Android DreamService app so background and vocabulary are independent and no 100-card player limit applies to words. Keep all media offline and decode at most two photos for crossfades. The primary lexicon targets native Chechen speakers; low-use evidence is linked per entry and exact Maciev glosses are validated. Raw full-dictionary records remain an explicit separate mode. Personal known-word marks accommodate variation between speakers.
