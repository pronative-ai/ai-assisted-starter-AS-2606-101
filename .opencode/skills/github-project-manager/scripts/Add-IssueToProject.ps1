<#
.SYNOPSIS
    Adds an existing GitHub issue to a Project (v2) board.

.PARAMETER Owner
    Repository owner.

.PARAMETER Repo
    Repository name.

.PARAMETER IssueNumber
    Issue number to add.

.PARAMETER ProjectId
    Project (v2) node ID (e.g., "PVT_kwDOEBDK-s4BaTPH").

.PARAMETER OrgName
    Organization name (needed to look up a project by number instead of ID).

.PARAMETER ProjectNumber
    Project number (alternative to ProjectId — looks up the ID first).

.EXAMPLE
    Add-IssueToProject -Owner myorg -Repo myrepo -IssueNumber 4 -ProjectId "PVT_kwDOEBDK-s4BaTPH"

.EXAMPLE
    Add-IssueToProject -Owner myorg -Repo myrepo -IssueNumber 4 -OrgName myorg -ProjectNumber 3
#>
param(
    [Parameter(Mandatory)] [string] $Owner,
    [Parameter(Mandatory)] [string] $Repo,
    [Parameter(Mandatory)] [int] $IssueNumber,
    [string] $ProjectId = "",
    [string] $OrgName = "",
    [int] $ProjectNumber = 0
)

$ErrorActionPreference = "Stop"

# Resolve project ID if not provided
if (-not $ProjectId -and $OrgName -and $ProjectNumber) {
    $queryObj = @{ query = "query { organization(login: `"$OrgName`") { projectV2(number: $ProjectNumber) { id } } }" }
    $json = $queryObj | ConvertTo-Json -Compress | gh api graphql --input - 2>&1
    $parsed = $json | ConvertFrom-Json
    $ProjectId = $parsed.data.organization.projectV2.id
    Write-Output "Resolved project ID: $ProjectId"
}

if (-not $ProjectId) {
    throw "Provide either -ProjectId or both -OrgName and -ProjectNumber"
}

# Get issue node ID
$queryObj = @{ query = "query { repository(owner: `"$Owner`", name: `"$Repo`") { issue(number: $IssueNumber) { id } } }" }
$json = $queryObj | ConvertTo-Json -Compress | gh api graphql --input - 2>&1
$parsed = $json | ConvertFrom-Json
$nodeId = $parsed.data.repository.issue.id

# Add to project
$mutationObj = @{ query = "mutation { addProjectV2ItemById(input: { projectId: `"$ProjectId`" contentId: `"$nodeId`" }) { item { id } } }" }
$result = $mutationObj | ConvertTo-Json -Compress | gh api graphql --input - 2>&1

Write-Output "Added issue #$IssueNumber to project"
Write-Output $result
