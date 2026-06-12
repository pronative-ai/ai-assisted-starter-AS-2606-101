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
| 1 | `POST /api/requirements/analyze` | Functional & Non-Functional Requirements, **1 Epic issue candidate** |
| 2 | `POST /api/acceptance-criteria/generate` | Acceptance Criteria with GWT scenarios, **refined Epic + task-level issue candidates** |
| 3 | `POST /api/solution-architecture/design` | Architecture design + **implementation slices** — each slice becomes 1 Task issue |

## Issue Hierarchy Standard

Each business intent produces the following issue structure:

| Level | Type | Content | Label |
|-------|------|---------|-------|
| 1 | **Epic** | One issue representing the overall business intent. Contains the full specification summary, scope, and references to child user stories. | `epic` |
| 2 | **User Story** | One issue per distinct user need, phrased as "As a <persona>, I want <capability> so that <benefit>". Contains the acceptance criteria relevant to that story. References parent Epic via `Epic: #<number>`. | `user-story` |
| 3 | **Task** | One issue per implementation slice from Stage 3. Each task covers a specific technical slice (e.g., frontend JSX change, CSS styling, tests, a11y). References parent User Story via `Story: #<number>`. | `task` |

The Epic body MUST include a story checklist (e.g., `- [ ] #2 Request count display`). Each User Story body MUST include an `Epic:` reference and a task checklist. Each Task body MUST include a `Story:` reference pointing to the parent user story.

## Workflow

1. Each stage writes its response to `specification-{stage}.response.json`
2. Human review required before advancing between stages
3. After all stages approved, compile `issue-manifest.md` containing:
   - **1 Epic issue** — consolidated from all stage outputs
   - **1 User Story issue** — per distinct persona/user need from the business intent
   - **N Task issues** — one per implementation slice from Stage 3, nested under the User Story
4. Propagate issues to GitHub:
   a. Create the **Epic** issue first — capture its issue number
   b. Create the **User Story** issue with `Epic: #<epic-number>` reference in body — capture its issue number
   c. Create each **Task** issue with `Story: #<story-number>` reference in body
   d. Update the Epic body with the story checklist (e.g., `- [ ] #2 User story title`)
   e. Update the User Story body with the task checklist (e.g., `- [ ] #4 JSX change`)
   f. Use `gh issue create` or `New-GitHubIssue` script, then add all to project board
   g. Print summary with all issue URLs

## API Reference

See `references/adlc-agents.json` for the full OpenAPI spec.

### Off-Limit Endpoints
`/api/pipeline/*`, `/api/cost/*`, `/api/runtime/*`, `/api/reports/*`, `/api/reviews/*` — MUST NOT be called.
