---
name: github-project-manager
description: >
  Use when managing GitHub Issues and Project boards — creating, updating, 
  labeling, commenting on issues, and adding them to GitHub Projects (v2).
  Use ONLY for GitHub repo/project management, not for general Git operations.
---

# GitHub Project Manager Skill

Manages GitHub Issues and Projects (v2) using the `gh` CLI and REST/GraphQL APIs.

## Prerequisites

- `gh` CLI installed and authenticated with scopes: `repo`, `project`, `read:org`
- Verify: `gh auth status`
- Missing scopes? Run: `gh auth refresh -h github.com -s project`

## Scripts

Reusable PowerShell scripts are in the `scripts/` directory alongside this skill. Dot-source them to use:

```
. .opencode/skills/github-project-manager/scripts/New-GitHubIssue.ps1
. .opencode/skills/github-project-manager/scripts/Update-GitHubIssueBody.ps1
. .opencode/skills/github-project-manager/scripts/Add-IssueToProject.ps1
. .opencode/skills/github-project-manager/scripts/Get-ProjectId.ps1
```

### New-GitHubIssue

Creates an issue with labels and optionally adds it to a project board:

```
$issue = New-GitHubIssue -Owner myorg -Repo myrepo -Title "Bug: login crash" `
  -Body "## Steps to reproduce`n1. Go to /login" -Labels @("bug","frontend") `
  -ProjectId "PVT_kwDOEBDK-s4BaTPH"
$issue.number   # issue number
$issue.html_url # browser URL
```

### Update-GitHubIssueBody

Updates or cleans an issue body:

```
# Replace body entirely
Update-GitHubIssueBody -Owner myorg -Repo myrepo -Number 4 -Body $newBody

# Append to existing body
Update-GitHubIssueBody -Owner myorg -Repo myrepo -Number 4 -Body "## Notes`nAdded later" -Append

# Auto-clean literal \n artifacts
Update-GitHubIssueBody -Owner myorg -Repo myrepo -Number 4 -Clean
```

### Add-IssueToProject

Adds an existing issue to a project board:

```
Add-IssueToProject -Owner myorg -Repo myrepo -IssueNumber 4 -ProjectId "PVT_kwDOEBDK-s4BaTPH"

# Or look up project by org + number:
Add-IssueToProject -Owner myorg -Repo myrepo -IssueNumber 4 -OrgName myorg -ProjectNumber 3
```

### Get-ProjectId

Looks up a project (v2) node ID:

```
$projectId = Get-ProjectId -OrgName myorg -ProjectNumber 3
```

## 1. Create Labels

Labels **must exist** before they can be applied to issues:

```
gh label create epic --repo owner/repo --color 5319E7 --description "Large feature area"
```

## 2. Create an Issue (without script)

**DO NOT** use `--json` flag — older `gh` versions don't support it on `issue create`.

```
$url = gh issue create --repo owner/repo --title "Title" --body "Body" --label "label1" 2>&1
$num = $url -replace '.*/(\d+)$', '$1'
```

## 3. Read an Issue Body

Use REST API (not GraphQL) for simple reads — it avoids JSON escaping issues:

```
$token = gh auth token 2>$null
$headers = @{ "Authorization" = "Bearer $token"; "Accept" = "application/vnd.github+json" }
$issue = Invoke-RestMethod -Uri "https://api.github.com/repos/owner/repo/issues/$num" -Headers $headers -Method Get
$body = $issue.body
```

## 4. Update an Issue Body (without script)

Send body via `Invoke-RestMethod` (not `gh issue edit --body`) to avoid shell quoting problems with long markdown:

```
$token = gh auth token 2>$null
$headers = @{ "Authorization" = "Bearer $token"; "Accept" = "application/vnd.github+json"; "X-GitHub-Api-Version" = "2022-11-28" }
$updateBody = @{ body = $newBody } | ConvertTo-Json -Depth 3
Invoke-RestMethod -Uri "https://api.github.com/repos/owner/repo/issues/$num" -Headers $headers -Method Patch -Body $updateBody
```

## 5. Get Issue Node ID

Pass GraphQL query via stdin (avoids shell hyphen-escaping issues with org names):

```
$queryObj = @{ query = "query { repository(owner: `"owner`", name: `"repo`") { issue(number: $num) { id } } }" }
$json = $queryObj | ConvertTo-Json -Compress | gh api graphql --input - 2>&1
$parsed = $json | ConvertFrom-Json
$nodeId = $parsed.data.repository.issue.id
```

## 6. Add Issue to a Project Board (v2)

Requires `project` OAuth scope on the token. Get the project ID first:

```
$queryObj = @{ query = "query { organization(login: `"org`") { projectV2(number: 3) { id title } } }" }
$json = $queryObj | ConvertTo-Json -Compress | gh api graphql --input - 2>&1
$parsed = $json | ConvertFrom-Json
$projectId = $parsed.data.organization.projectV2.id
```

Then add the issue:

```
$mutationObj = @{ query = "mutation { addProjectV2ItemById(input: { projectId: `"$projectId`" contentId: `"$nodeId`" }) { item { id } } }" }
$mutationObj | ConvertTo-Json -Compress | gh api graphql --input - 2>&1
```

## 7. Clean Body Text (Remove Escaped Newlines)

GitHub API may store `\n` as literal text. Clean it before display or re-submission:

```
$clean = $body
$clean = $clean -replace "`r`n", "`n"
$clean = $clean -replace [regex]::Escape('\n'), "`n"
$clean = $clean -replace "\\`n", "`n"
$clean = $clean -replace "`n`n`n+", "`n`n"
$clean = $clean.Trim()
```

## 8. Batch Operations

Iterate over a list of issues. Always add a 300ms delay between API calls to avoid rate limits:

```
foreach ($issue in $issues) {
  New-GitHubIssue -Owner o -Repo r -Title $issue.title -Body $issue.body -Labels $issue.labels -ProjectId $pid
  Start-Sleep -Milliseconds 300
}
```

## Windows PowerShell Gotchas

| Pitfall | Fix |
|---------|------|
| `\n` in double quotes is literal text, not newline | Use `` "`n" `` (backtick-n) for real newlines |
| Hyphens in org names break `-f` flag parsing | Pipe JSON via stdin with `--input -` |
| `gh issue create` has no `--json` flag | Parse URL: `$url -replace '.*/(\d+)$', '$1'` |
| Long body strings break shell parsing | Use `Update-GitHubIssueBody` script or `Invoke-RestMethod -Method Patch` |
| `2>&1` mixes stdout and stderr | Use `2>$null` to discard stderr |
| Labels must exist before use | Create with `gh label create` first |
