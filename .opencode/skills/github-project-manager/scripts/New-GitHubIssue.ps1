<#
.SYNOPSIS
    Creates a GitHub issue with optional project board add.
.PARAMETER Owner
    Repository owner.
.PARAMETER Repo
    Repository name.
.PARAMETER Title
    Issue title.
.PARAMETER Body
    Issue body (markdown). Use `n for newlines.
.PARAMETER Labels
    Label names (must exist in repo).
.PARAMETER ProjectId
    Project v2 node ID to add the issue to (optional).
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

$payload = @{ title = $Title; body = $Body }
if ($Labels.Count -gt 0) { $payload.labels = $Labels }

$issue = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/issues" `
    -Headers $headers -Method Post -Body ($payload | ConvertTo-Json -Depth 3)

Write-Output $issue

if ($ProjectId -and $issue.node_id) {
    $mutation = @{ query = "mutation { addProjectV2ItemById(input: { projectId: `"$ProjectId`" contentId: `"$($issue.node_id)`" }) { item { id } } }" }
    $mutation | ConvertTo-Json -Compress | gh api graphql --input - 2>$null
    Write-Output "Added to project: $ProjectId"
}
