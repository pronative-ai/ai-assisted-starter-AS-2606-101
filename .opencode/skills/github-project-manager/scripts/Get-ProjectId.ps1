<#
.SYNOPSIS
    Gets a GitHub Project v2 node ID by org and project number.
.PARAMETER OrgName
    Organization name.
.PARAMETER ProjectNumber
    Project number (from URL: /orgs/{org}/projects/{number}).
#>
[CmdletBinding()]
param(
    [string] $OrgName,
    [int] $ProjectNumber = 0
)

$isDotSourced = $MyInvocation.InvocationName -eq '.'

function Get-ProjectId {
    param(
        [Parameter(Mandatory)] [string] $OrgName,
        [Parameter(Mandatory)] [int] $ProjectNumber
    )

    $queryObj = @{ query = "query { organization(login: `"$OrgName`") { projectV2(number: $ProjectNumber) { id title } } }" }
    $json = $queryObj | ConvertTo-Json -Compress | gh api graphql --input - 2>&1
    $parsed = $json | ConvertFrom-Json

    $project = $parsed.data.organization.projectV2
    Write-Output "Title: $($project.title)"
    Write-Output "ID: $($project.id)"
}

if (-not $isDotSourced) {
    if (-not $OrgName) { throw "Missing required parameter: OrgName" }
    if ($ProjectNumber -eq 0) { throw "Missing required parameter: ProjectNumber" }
    Get-ProjectId -OrgName $OrgName -ProjectNumber $ProjectNumber
}
