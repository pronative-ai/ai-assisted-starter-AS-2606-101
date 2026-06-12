<#
.SYNOPSIS
    Creates a GitHub issue with labels and adds it to a project board.

.PARAMETER Owner
    Repository owner (org or user).

.PARAMETER Repo
    Repository name.

.PARAMETER Title
    Issue title.

.PARAMETER Body
    Issue body (markdown). Supports real newlines with `n.

.PARAMETER Labels
    Array of label names. Labels must already exist in the repo.

.PARAMETER ProjectId
    Optional. Project (v2) node ID to add the issue to.

.EXAMPLE
    New-GitHubIssue -Owner "myorg" -Repo "myrepo" -Title "Fix login" -Body "## Description`nThe login page crashes." -Labels @("bug")

.EXAMPLE
    New-GitHubIssue -Owner "myorg" -Repo "myrepo" -Title "Epic: Auth" -Body "..." -Labels @("epic") -ProjectId "PVT_kw..."
#>
param(
    [Parameter(Mandatory)] [string] $Owner,
    [Parameter(Mandatory)] [string] $Repo,
    [Parameter(Mandatory)] [string] $Title,
    [Parameter(Mandatory)] [string] $Body,
    [string[]] $Labels = @(),
    [string] $ProjectId = ""
)

$ErrorActionPreference = "Stop"
$headers = @{
    "Authorization" = "Bearer $(gh auth token 2>$null)"
    "Accept" = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

# Create issue via REST API to avoid shell quoting issues
$payload = @{ title = $Title; body = $Body }
if ($Labels.Count -gt 0) { $payload.labels = $Labels }

$issue = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/issues" `
    -Headers $headers -Method Post -Body ($payload | ConvertTo-Json -Depth 3)

Write-Output $issue

# Add to project board if requested
if ($ProjectId -and $issue.node_id) {
    $mutation = @{ query = "mutation { addProjectV2ItemById(input: { projectId: `"$ProjectId`" contentId: `"$($issue.node_id)`" }) { item { id } } }" }
    $mutation | ConvertTo-Json -Compress | gh api graphql --input - 2>$null
    Write-Output "Added to project: $ProjectId"
}
