---
name: spec
description: >
  Orchestrates a specification pipeline across Requirements Analysis,
  Acceptance Criteria, and Solution Architecture stages via remote agent APIs.
  Generates specification artifacts and issue manifests for GitHub propagation.
permission:
  skill:
    spec: allow
    github-project-manager: allow
---

Coordinates the ADLC specification pipeline via remote agent APIs. The [github-project-manager](../github-project-manager/SKILL.md) skill is used **only** for GitHub issue/project operations — it never calls ADLC APIs.

## Subagent Mode

This skill is designed to be driven by the `spec-agent` subagent defined in `opencode.json`. When invoked, the subagent:

1. Prompts the user for the business intent inputs (business idea, target users, goals, constraints)
2. Calls each pipeline stage sequentially via the ADLC unified agent API
3. Pauses after each stage for human review before advancing
4. After all stages approved, compiles the issue manifest and propagates issues to GitHub
5. Stops after issue propagation — no source code is generated

The subagent acts as the orchestrator, reading this SKILL.md for workflow instructions and referencing `references/adlc-agents.json` for API schemas.

## Prerequisites

- Network access to the ADLC unified agent API
- [github-project-manager](../github-project-manager/SKILL.md) prerequisites met (`gh` CLI with `repo`, `project`, `read:org` scopes)

## Input Schema

The pipeline is initiated by sending a `BusinessIntentRequest` payload to Stage 1:

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `business_idea` | string | yes | High-level description of the product or feature idea |
| `target_users` | string | yes | Target audience for the product or feature |
| `business_goal` | string | yes | Measurable outcome or objective |
| `known_constraints` | string | yes | Technical, timeline, or resource limitations |
| `existing_context` | string | yes | Current system state or relevant background |
| `scope_level` | string | yes | Scope granularity (e.g. `feature`, `product`, `MVP`) |

See `references/adlc-agents.json` → `BusinessIntentRequest` for the full schema definition.

### Stage Payloads

| Stage | Endpoint | Request Schema | Output File |
|-------|----------|----------------|-------------|
| 1 | `POST /api/requirements/analyze` | `BusinessIntentRequest` | `specification-1.response.json` |
| 2 | `POST /api/acceptance-criteria/generate` | `AgentPayload` (Stage 1 output) | `specification-2.response.json` |
| 3 | `POST /api/solution-architecture/design` | `AgentPayload` (Stage 2 output) | `specification-3.response.json` |

## Pipeline Stages

| Stage | Endpoint | Deliverable |
|-------|----------|-------------|
| 1 | `POST /api/requirements/analyze` | Functional & Non-Functional Requirements, **1 Epic issue candidate** |
| 2 | `POST /api/acceptance-criteria/generate` | Acceptance Criteria with GWT scenarios, **refined Epic + task-level issue candidates** |
| 3 | `POST /api/solution-architecture/design` | Architecture design + **implementation slices** — each slice becomes 1 Task issue |

## Issue Hierarchy Standard

Each business intent produces the following issue structure:

| Level | Type | Title Prefix | Label |
|-------|------|--------------|-------|
| 1 | **Epic** | `[Epic]` | `epic` |
| 2 | **User Story** | `[User Story]` | `user-story` |
| 3 | **Task** | `[Task]` | `task` |

### Epic
- One issue representing the overall business intent.
- Contains the full specification summary, scope, architecture overview, and references to child user stories.
- Body MUST include a story checklist (e.g., `- [ ] #2 [User Story] Show request count`).

### User Story
- One issue per distinct user need, phrased as "As a <persona>, I want <capability> so that <benefit>".
- Contains the acceptance criteria relevant to that story.
- Body MUST include `Epic: #<epic-number>` reference and a task checklist (e.g., `- [ ] #3 [Task] Add JSX count display`).

### Task
- One issue per implementation slice from Stage 3.
- Each task covers a specific technical slice (e.g., frontend JSX change, CSS styling, tests, a11y).
- Body MUST include `Story: #<story-number>` reference pointing to the parent user story.
- Body MUST contain ALL of the following inline:
  - Related **functional requirements** (from Stage 1) that this task implements
  - Related **non-functional requirements** (from Stage 1) that this task addresses  
  - Full **acceptance criteria** text (not just IDs) relevant to this slice
  - Implementation description and architecture context

## Workflow

1. Each stage writes its response to `specification-{stage}.response.json`
2. Human review required before advancing between stages
3. Compile `issue-manifest.md` by mapping stage output fields into each issue body:

   | Issue | Source File | Source Fields | Body Section |
   |-------|-------------|---------------|--------------|
   | **Epic** | `specification-1.response.json` | `requirement_summary` | Summary / Description |
   | | `specification-1.response.json` | `functional_requirements[]`, `non_functional_requirements[]` | Requirements |
   | | `specification-1.response.json` | `scope_constraints`, `assumptions`, `out_of_scope`, `open_questions` | Scope & Constraints |
   | | `specification-3.response.json` | `architecture_summary`, `architecture_decisions[]` | Architecture Overview |
   | | — | compiled child issue numbers | Story Checklist |
   | **User Story** (per persona) | `specification-2.response.json` | `acceptance_criteria[]`, `given_when_then[]` | Acceptance Criteria & Scenarios |
   | | `specification-2.response.json` | `verification_checks[]`, `edge_cases[]` | Verification & Edge Cases |
   | | `specification-2.response.json` | `test_guidance` (unit / integration / manual) | Test Guidance |
   | | `specification-2.response.json` | `definition_of_done[]` | Definition of Done |
   | | — | parent Epic number | `Epic: #<epic-number>` |
   | | — | compiled child issue numbers | Task Checklist |
| **Task** (per slice) | `specification-3.response.json` | `implementation_slices[n].title`, `.description` | Title & Description |
| | `specification-1.response.json` | `functional_requirements[]` (filtered to slice) | Related Functional Requirements |
| | `specification-1.response.json` | `non_functional_requirements[]` (filtered to slice) | Related Non-Functional Requirements |
| | `specification-2.response.json` | `acceptance_criteria[]` (filtered to slice) | Acceptance Criteria (inline, not by reference ID) |
| | `specification-3.response.json` | `implementation_slices[n].suggested_order` | Slice Metadata |
| | `specification-3.response.json` | `component_model[]`, `api_boundary_guidance[]`, `data_model_guidance[]` | Architecture Context |
| | — | parent User Story number | `Story: #<story-number>` |

   The compiled `issue-manifest.md` must contain the full rendered body for each issue.

4. Propagate issues to GitHub using the [github-project-manager](../github-project-manager/SKILL.md) scripts (GitHub operations only — this skill handles all ADLC API calls):

   ```powershell
   # Dot-source the scripts (each defines a function with the same name)
   . .opencode/skills/github-project-manager/scripts/New-GitHubIssue.ps1
   . .opencode/skills/github-project-manager/scripts/Update-GitHubIssueBody.ps1
   . .opencode/skills/github-project-manager/scripts/Get-ProjectId.ps1
   . .opencode/skills/github-project-manager/scripts/Add-IssueToProject.ps1
   ```

   > **⚠️ Body content from heredocs**: PowerShell heredocs (`@' '@`) do NOT pipe reliably to `gh issue create --body-file -`. Always write body content to a temp file and pass it via `@`file or use `gh api --field body=@tempFile`:
   > ```powershell
   > $tempFile = [System.IO.Path]::GetTempFileName()
   > $body | Out-File -FilePath $tempFile -Encoding utf8
   > gh api "repos/$Owner/$Repo/issues" --method POST --field "title=$Title" --field "body=@$tempFile" --field "labels[]=$Label"
   > Remove-Item -LiteralPath $tempFile -Force
   > ```
   > Or use `Invoke-RestMethod` (REST API) directly to avoid shell quoting issues altogether.

   a. Create the **Epic** issue — prefix title with `[Epic]` — capture its issue number
   b. Create each **User Story** issue — prefix title with `[User Story]`, include `Epic: #<epic-number>` in body — capture its issue number
   c. Create each **Task** issue — prefix title with `[Task]`, include `Story: #<story-number>` in body. Each Task body MUST contain:
      - Related **functional requirements** (from specification-1.response.json) that this task implements
      - Related **non-functional requirements** (from specification-1.response.json) that this task addresses
      - Full **acceptance criteria** text (not just IDs), filtered to those relevant for this slice
      - Implementation description, files affected, and architecture context (from specification-3.response.json)
   d. Update the Epic body with the story checklist (e.g., `- [ ] #2 [User Story] Show request count`)
   e. Update the User Story body with the task checklist (e.g., `- [ ] #4 [Task] Add JSX count display`)
   f. Add all issues to the project board (see [Get-ProjectId](../github-project-manager/SKILL.md#scripts) / [Add-IssueToProject](../github-project-manager/SKILL.md#scripts))
   g. Print summary with all issue URLs
   h. Verify each issue on GitHub has the correct title prefix, cross-references, and complete body content

## API Reference

See `references/adlc-agents.json` for the full OpenAPI spec.

### Off-Limit Endpoints
`/api/pipeline/*`, `/api/cost/*`, `/api/runtime/*`, `/api/reports/*`, `/api/reviews/*` — MUST NOT be called.

## Error Handling

### API Failures
- Each POST endpoint may return `4xx` (bad request / auth failure) or `5xx` (server error)
- On failure, log the response body and **do not proceed** to the next stage
- Retry `5xx` responses up to 3 times with a 5-second backoff between attempts
- If a `specification-{stage}.response.json` file is missing or malformed after a successful API call, treat it as a terminal error

### Recovery
- If a stage fails, correct the input and re-call the stage — earlier stage outputs remain valid
- Partial pipeline progress: completed `specification-*.response.json` files are preserved; only re-run from the failed stage onward
- Use standard PowerShell try/catch around API and script calls

See [github-project-manager Error Handling](../github-project-manager/SKILL.md#windows-powershell-gotchas) for issue-level error resilience.
