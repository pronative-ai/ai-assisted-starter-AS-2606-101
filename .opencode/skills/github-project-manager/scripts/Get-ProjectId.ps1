<#
.SYNOPSIS
    Gets a GitHub Project v2 node ID by org and project number.
.PARAMETER OrgName
    Organization name.
.PARAMETER ProjectNumber
    Project number (from URL: /orgs/{org}/projects/{number}).
#>

function Get-ProjectId {
    param(
        [Parameter(Mandatory)] [string] $OrgName,
        [Parameter(Mandatory)] [int] $ProjectNumber
    )

    $queryObj = @{ query = "query { organization(login: `"$OrgName`") { projectV2(number: $ProjectNumber) { id title } } }" }
    $json = $queryObj | ConvertTo-Json -Compress | gh api graphql --input - 2>&1
    $parsed = $json | ConvertFrom-Json

    $project = $parsed.data.organization.projectV2
    $project.id
}

# When invoked directly (not dot-sourced), run the function
if ($MyInvocation.InvocationName -ne '.') {
    if ($args.Count -lt 2) { throw "Usage: $(Split-Path -Leaf $PSCommandPath) <OrgName> <ProjectNumber>" }
    Get-ProjectId -OrgName $args[0] -ProjectNumber $args[1]
}
