
# GLOBAL TECHNICAL DESIGN

## Repository Context
- Repository: pronative-ai/ai-assisted-student-AS-2606-101-ST-2606-<Student Id>
- Program: AI-Assisted Phase 1
- Student ID: <Student Id>
- Batch ID: 2606
- Azure Resource Group: rg-as-2606-101-st-2606-<Student Id>

## Core Stack
- Frontend: React / Vite or Next.js
- Backend: C# / .NET or Node.js API
- Cloud: Azure Container Apps, Static Web Apps, Cosmos DB, Storage, Key Vault
- Observability: Application Insights, Log Analytics, Azure Monitor

## Engineering Workflow
- Source Control: GitHub
- Branching: feature branches from main
- Implementation Boundary: GitHub Issue
- Pull Requests: required for merge
- CI/CD: GitHub Actions
- Coding Assistant: OpenCode or approved agentic IDE

## ADLC Golden Thread
- Every intent receives an immutable Intent ID.
- Every GitHub issue must include Intent ID.
- Every PR must reference the GitHub issue and Intent ID.
- Every deployment should preserve Intent ID through metadata, tags, logs, or release notes.
- Every incident should link back to Intent ID where possible.

## Testing Standard
- Build must pass before PR review.
- Unit tests should be added or updated for changed logic.
- API changes should include smoke validation.
- UI changes should include visual/manual validation notes.

## Security And Access
- Do not hardcode secrets.
- Use GitHub secrets or Azure Key Vault.
- Respect student resource group boundary.
- Do not access another student's repo or Azure resources.

## Observability
- Use structured logs where possible.
- Include correlation identifiers in important logs.
- Application telemetry should support troubleshooting through Application Insights.

## Agent Rules
- Read this file before implementing any GitHub issue.
- Read the full GitHub issue before coding.
- Stay within the defined implementation scope.
- Do not implement out-of-scope items.
- If requirements are unclear, ask for clarification or document assumptions.
