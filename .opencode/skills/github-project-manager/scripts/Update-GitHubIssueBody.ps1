<#
.SYNOPSIS
    Updates GitHub issue body with cleaned text.

.PARAMETER Owner
    Repository owner.

.PARAMETER Repo
    Repository name.

.PARAMETER Number
    Issue number.

.PARAMETER Body
    New body text (markdown). Replaces the entire body.

.PARAMETER Append
    If set, appends to the existing body instead of replacing.

.PARAMETER Clean
    If set, cleans the existing body (removes literal \n artifacts) without changing content.

.EXAMPLE
    Update-GitHubIssueBody -Owner myorg -Repo myrepo -Number 4 -Body $newBody

.EXAMPLE
    Update-GitHubIssueBody -Owner myorg -Repo myrepo -Number 4 -Clean
#>
param(
    [Parameter(Mandatory)] [string] $Owner,
    [Parameter(Mandatory)] [string] $Repo,
    [Parameter(Mandatory)] [int] $Number,
    [string] $Body = "",
    [switch] $Append,
    [switch] $Clean
)

$ErrorActionPreference = "Stop"
$token = gh auth token 2>$null
$headers = @{
    "Authorization" = "Bearer $token"
    "Accept" = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

# Read current issue
$issue = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/issues/$Number" -Headers $headers -Method Get
$currentBody = $issue.body

if ($Clean) {
    # Auto-clean existing body
    $clean = Clean-BodyText -Body $currentBody
    $payload = @{ body = $clean }
} elseif ($Append) {
    $payload = @{ body = "$currentBody`n`n$Body" }
} else {
    $payload = @{ body = $Body }
}

$result = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/issues/$Number" `
    -Headers $headers -Method Patch -Body ($payload | ConvertTo-Json -Depth 3)

Write-Output $result
