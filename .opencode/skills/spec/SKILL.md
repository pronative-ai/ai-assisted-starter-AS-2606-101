---
name: spec
description: >
  Orchestrates a specification pipeline across Requirements Analysis,
  Acceptance Criteria, and Solution Architecture stages via remote agent APIs.
  Generates specification artifacts and issue manifests for GitHub propagation.
---

Coordinates the ADLC specification pipeline via remote agent APIs.

## Prerequisites

- Network access to the ADLC unified agent API
- GitHub PAT with `repo` + `project` scopes for issue propagation
- `gh` CLI authenticated

## Pipeline Stages

| Stage | Endpoint | Deliverable |
|-------|----------|-------------|
| 1 | `POST /api/requirements/analyze` | Functional & Non-Functional Requirements |
| 2 | `POST /api/acceptance-criteria/generate` | Acceptance Criteria with GWT scenarios |
| 3 | `POST /api/solution-architecture/design` | Architecture design + implementation slices |

## Workflow

1. Each stage writes its response to `specification-{stage}.response.json`
2. Human review required before advancing between stages
3. After all stages approved, compile `issue-manifest.md` from issue candidates
4. Propagate issues via `gh issue create` or `New-GitHubIssue` script

## API Reference

See `references/adlc-agents.json` for the full OpenAPI spec.

### Off-Limit Endpoints
`/api/pipeline/*`, `/api/cost/*`, `/api/runtime/*`, `/api/reports/*`, `/api/reviews/*` — MUST NOT be called.
