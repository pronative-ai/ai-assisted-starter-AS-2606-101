# GitHub Issue Propagation Instructions

## Overview

The repo `ai-assisted-starter-AS-2606-101` does not yet exist on GitHub under `pronative-ai`. Before propagating issues, the repository must be created.

## Prerequisites

1. Create the repository `ai-assisted-starter-AS-2606-101` under `pronative-ai` on GitHub
2. Ensure you have a PAT with `repo` and `project` scopes

## Option 1: Use the PowerShell script

Run the following in PowerShell:

```powershell
# Set the PAT (already in AGENT_GITHUB_CONNECT env var)
$env:GH_TOKEN = $env:AGENT_GITHUB_CONNECT

# Run the propagation script
.\run-propagation.ps1
```

## Option 2: Manual `gh` CLI approach

```powershell
# Authenticate
echo $env:AGENT_GITHUB_CONNECT | gh auth login --with-token

# Create labels
gh label create epic --repo pronative-ai/ai-assisted-starter-AS-2606-101 --color 5319E7 --description "Large feature"
gh label create user-story --repo pronative-ai/ai-assisted-starter-AS-2606-101 --color 006B75 --description "User story"
gh label create task --repo pronative-ai/ai-assisted-starter-AS-2606-101 --color 0E8A16 --description "Implementation task"

# Create Epic
$epicUrl = gh issue create --repo pronative-ai/ai-assisted-starter-AS-2606-101 --title "[Epic] Automated FBM Order Fulfillment Pipeline for Amazon.de" --body-file issue-manifest.md --label "epic"
$epicNum = $epicUrl -replace '.*/(\d+)$', '$1'

# Then create User Story with Epic ref, then Tasks with Story ref
# See run-propagation.ps1 for full automated logic
```

## Option 3: Use issue-manifest.md

The file `issue-manifest.md` contains the full rendered body for each issue. Copy-paste content from it when creating issues manually through the GitHub UI.

## Created Artifacts

- `specification-1.response.json` - Requirements Analysis (Stage 1)
- `specification-2.response.json` - Acceptance Criteria (Stage 2)
- `specification-3.response.json` - Solution Architecture (Stage 3)
- `issue-manifest.md` - Full issue hierarchy with bodies
- `run-propagation.ps1` - Automated PowerShell script for GitHub propagation
