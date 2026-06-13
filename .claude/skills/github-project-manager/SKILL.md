---
name: github-project-manager
description: >
  Use when managing GitHub Issues and Project boards — creating, updating, 
  labeling, commenting on issues, and adding them to GitHub Projects (v2).
  Use ONLY for GitHub repo/project management, not for general Git operations.
---

Manages GitHub Issues and Projects (v2) via `gh` CLI and REST/GraphQL APIs.

## Prerequisites

- `gh` CLI authenticated with scopes: `repo`, `project`, `read:org`
- Verify: `gh auth status`
- Missing scopes: `gh auth refresh -h github.com -s project`

## Scripts (`.opencode/skills/github-project-manager/scripts/`)

Dot-source first to load all functions into your session:
```powershell
. .opencode/skills/github-project-manager/scripts/New-GitHubIssue.ps1
. .opencode/skills/github-project-manager/scripts/Update-GitHubIssueBody.ps1
. .opencode/skills/github-project-manager/scripts/Add-IssueToProject.ps1
. .opencode/skills/github-project-manager/scripts/Get-ProjectId.ps1
```
Each script supports dual-mode: **dot-sourcing** defines a function; **direct invocation** runs immediately.

| Script | Purpose |
|--------|---------|
| `New-GitHubIssue` | Create issue with labels + optional project board add |
| `Update-GitHubIssueBody` | Replace, append, or clean (`-Clean`) issue body |
| `Add-IssueToProject` | Add existing issue to project (by ID or org+number) |
| `Get-ProjectId` | Lookup project v2 node ID by org+number |

### Examples

```powershell
# Create issue + add to project
$issue = New-GitHubIssue -Owner myorg -Repo myrepo -Title "Bug: login crash" `
  -Body "Steps:\n1. Go to /login" -Labels @("bug") -ProjectId "PVT_kw..."

# Append to existing body
Update-GitHubIssueBody -Owner myorg -Repo myrepo -Number 4 -Body "## Notes`nAdded later" -Append

# Add issue to project by org+number
Add-IssueToProject -Owner myorg -Repo myrepo -IssueNumber 4 -OrgName myorg -ProjectNumber 3
```

## Manual API Operations (when scripts aren't available)

**Labels must exist** before use: `gh label create epic --repo owner/repo --color 5319E7 --description "Large feature"`

**Create issue** (no `--json` flag on older `gh`):
```powershell
$url = gh issue create --repo owner/repo --title "Title" --body "Body" --label "label1" 2>&1
$num = $url -replace '.*/(\d+)$', '$1'
```

**Read/update body** via REST (avoids shell quoting issues):
```powershell
$token = gh auth token 2>$null
$headers = @{ "Authorization" = "Bearer $token"; "Accept" = "application/vnd.github+json"; "X-GitHub-Api-Version" = "2022-11-28" }
# Read
$issue = Invoke-RestMethod -Uri "https://api.github.com/repos/owner/repo/issues/$num" -Headers $headers
$body = $issue.body
# Update (PATCH)
Invoke-RestMethod -Uri "https://api.github.com/repos/owner/repo/issues/$num" -Headers $headers -Method Patch -Body (@{ body = $newBody } | ConvertTo-Json)
```

**GraphQL** (get issue node ID, add to project):
```powershell
# Get issue node ID
@{ query = "query { repository(owner: \"owner\", name: \"repo\") { issue(number: $num) { id } } }" } | ConvertTo-Json -Compress | gh api graphql --input - 2>&1 | ConvertFrom-Json | % { $_.data.repository.issue.id }

# Add to project (requires `project` OAuth scope)
$pid = @{ query = "query { organization(login: \"org\") { projectV2(number: 3) { id } } }" } | ConvertTo-Json -Compress | gh api graphql --input - 2>&1 | ConvertFrom-Json | % { $_.data.organization.projectV2.id }
@{ query = "mutation { addProjectV2ItemById(input: { projectId: \"$pid\" contentId: \"$nodeId\" }) { item { id } } }" } | ConvertTo-Json -Compress | gh api graphql --input - 2>&1
```

**Clean literal `\n` artifacts from body:**
```powershell
$clean = $body -replace "`r`n", "`n" -replace [regex]::Escape('\n'), "`n" -replace "\\`n", "`n" -replace "`n`n`n+", "`n`n"; $clean.Trim()
```

**Batch operations** (300ms delay between calls):
```powershell
foreach ($issue in $issues) {
  New-GitHubIssue -Owner o -Repo r -Title $issue.title -Body $issue.body -Labels $issue.labels -ProjectId $pid
  Start-Sleep -Milliseconds 300
}
```

## Windows PowerShell Gotchas

| Pitfall | Fix |
|---------|------|
| `\n` in double-quotes = literal text | Use `` `n `` (backtick-n) |
| Hyphens in org names break `-f` flags | Pipe JSON via `gh api graphql --input -` |
| No `--json` on `gh issue create` | Parse URL: `$url -replace '.*/(\d+)$', '$1'` |
| Long body strings break shell parsing | Use `Invoke-RestMethod -Method Patch` |
| `2>&1` mixes stdout/stderr | Use `2>$null` to discard stderr |
