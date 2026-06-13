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
    }

    if (-not $ProjectId) {
        throw "Provide either -ProjectId or both -OrgName and -ProjectNumber"
    }

    $queryObj = @{ query = "query { repository(owner: `"$Owner`", name: `"$Repo`") { issue(number: $IssueNumber) { id } } }" }
    $json = $queryObj | ConvertTo-Json -Compress | gh api graphql --input - 2>&1
    $parsed = $json | ConvertFrom-Json
    $nodeId = $parsed.data.repository.issue.id

    $mutationObj = @{ query = "mutation { addProjectV2ItemById(input: { projectId: `"$ProjectId`" contentId: `"$nodeId`" }) { item { id } } }" }
    $mutationObj | ConvertTo-Json -Compress | gh api graphql --input - 2>&1
}

# When invoked directly (not dot-sourced), run the function
if ($MyInvocation.InvocationName -ne '.') {
    $params = @{}
    for ($i = 0; $i -lt $args.Count; $i += 2) {
        $params[$args[$i].Trim('-')] = $args[$i + 1]
    }
    Add-IssueToProject @params
}
