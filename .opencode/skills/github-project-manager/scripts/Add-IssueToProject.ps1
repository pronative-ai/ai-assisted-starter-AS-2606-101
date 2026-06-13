<#
.SYNOPSIS
    Adds a GitHub issue to a Project v2 board.
.PARAMETER Owner
    Repository owner.
.PARAMETER Repo
    Repository name.
.PARAMETER IssueNumber
    Issue number.
.PARAMETER ProjectId
    Project v2 node ID (e.g., "PVT_kw...").
.PARAMETER OrgName
    Org name (needed to look up project by number).
.PARAMETER ProjectNumber
    Project number (alternative to ProjectId).
#>
[CmdletBinding()]
param(
    [string] $Owner,
    [string] $Repo,
    [int] $IssueNumber = 0,
    [string] $ProjectId = "",
    [string] $OrgName = "",
    [int] $ProjectNumber = 0
)

$isDotSourced = $MyInvocation.InvocationName -eq '.'

function Add-IssueToProject {
    param(
        [Parameter(Mandatory)] [string] $Owner,
        [Parameter(Mandatory)] [string] $Repo,
        [Parameter(Mandatory)] [int] $IssueNumber,
        [string] $ProjectId = "",
        [string] $OrgName = "",
        [int] $ProjectNumber = 0
    )

    $ErrorActionPreference = "Stop"

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

    $queryObj = @{ query = "query { repository(owner: `"$Owner`", name: `"$Repo`") { issue(number: $IssueNumber) { id } } }" }
    $json = $queryObj | ConvertTo-Json -Compress | gh api graphql --input - 2>&1
    $parsed = $json | ConvertFrom-Json
    $nodeId = $parsed.data.repository.issue.id

    $mutationObj = @{ query = "mutation { addProjectV2ItemById(input: { projectId: `"$ProjectId`" contentId: `"$nodeId`" }) { item { id } } }" }
    $result = $mutationObj | ConvertTo-Json -Compress | gh api graphql --input - 2>&1

    Write-Output "Added issue #$IssueNumber to project"
    Write-Output $result
}

if (-not $isDotSourced) {
    if (-not $Owner) { throw "Missing required parameter: Owner" }
    if (-not $Repo) { throw "Missing required parameter: Repo" }
    if ($IssueNumber -eq 0) { throw "Missing required parameter: IssueNumber" }
    Add-IssueToProject -Owner $Owner -Repo $Repo -IssueNumber $IssueNumber -ProjectId $ProjectId -OrgName $OrgName -ProjectNumber $ProjectNumber
}
