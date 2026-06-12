# AI-Assisted Starter — AS-2606-101

A starter template for AI-assisted software development using [OpenCode](https://opencode.ai). This project provides a specification pipeline agent and GitHub automation skills to streamline the AI development lifecycle (ADLC) for the **pronative.ai** organization.

## Overview

This repository configures an AI-assisted development workflow built around three components:

- **Specification Agent** — An OpenCode agent that orchestrates a multi-stage specification pipeline (Requirements Analysis → Acceptance Criteria → Solution Architecture) via a remote Azure-hosted API, with human review checkpoints between each stage.
- **GitHub Project Management Skill** — PowerShell scripts for automating GitHub Issues and Project v2 boards.
- **OpenAPI Specification** — The API contract for the `PronativeAdlcUnified.Api` running on Azure Container Apps.

## Repository Structure

```
.opencode/
├── agents/
│   └── spec-agent.md             # Specification pipeline agent definition
├── skills/
│   ├── github-project-manager/
│   │   ├── SKILL.md              # Skill documentation
│   │   └── scripts/
│   │       ├── New-GitHubIssue.ps1
│   │       ├── Update-GitHubIssueBody.ps1
│   │       ├── Add-IssueToProject.ps1
│   │       └── Get-ProjectId.ps1
│   └── spec/
│       └── references/
│           └── adlc-agents.json  # OpenAPI 3.1.1 specification
├── package.json                  # @opencode-ai/plugin dependency
└── .gitignore
```

## Prerequisites

- [OpenCode CLI](https://opencode.ai) installed
- [GitHub CLI (`gh`)](https://cli.github.com/) authenticated with scopes: `repo`, `project`, `read:org`
- PowerShell 5.1+
- Environment variable `AGENT_GITHUB_CONNECT` set to a GitHub Personal Access Token

## Usage

### Specification Agent

Run the specification pipeline agent through OpenCode:

```bash
@spec-agent <your-intent>
```

The agent will proceed through three stages with human review gates:

1. **Requirements Analysis** — Analyzes business intent via the remote API
2. **Acceptance Criteria** — Generates acceptance criteria from approved requirements
3. **Solution Architecture** — Designs architecture from approved criteria

Results are propagated to the [pronative-ai GitHub Project](https://github.com/orgs/pronative-ai/projects/3).

### GitHub Automation Scripts

Each script in `.opencode/skills/github-project-manager/scripts/` supports `-Help`:

```powershell
.\scripts\New-GitHubIssue.ps1 -Help
.\scripts\Add-IssueToProject.ps1 -Help
```

## Remote API

The agent communicates with the `PronativeAdlcUnified.Api` hosted on Azure Container Apps:

```
https://ca-adlc-unified-agent.ashyocean-2579666a.westus2.azurecontainerapps.io/
```

See `.opencode/skills/spec/references/adlc-agents.json` for the full OpenAPI specification.

## License

Proprietary — pronative.ai
