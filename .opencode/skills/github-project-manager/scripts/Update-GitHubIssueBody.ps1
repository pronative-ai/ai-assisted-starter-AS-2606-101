<#
.SYNOPSIS
    Updates or cleans a GitHub issue body.
.PARAMETER Owner
    Repository owner.
.PARAMETER Repo
    Repository name.
.PARAMETER Number
    Issue number.
.PARAMETER Body
    New body text (replaces entirely unless -Append).
.PARAMETER Append
    Appends to existing body instead of replacing.
.PARAMETER Clean
    Cleans literal \n artifacts from existing body.
#>
[CmdletBinding()]
param(
    [string] $Owner,
    [string] $Repo,
    [int] $Number = 0,
    [string] $Body = "",
    [switch] $Append,
    [switch] $Clean
)

$isDotSourced = $MyInvocation.InvocationName -eq '.'

function Update-GitHubIssueBody {
    param(
        [Parameter(Mandatory)] [string] $Owner,
        [Parameter(Mandatory)] [string] $Repo,
        [Parameter(Mandatory)] [int] $Number,
        [string] $Body = "",
        [switch] $Append,
        [switch] $Clean
    )

    $ErrorActionPreference = "Stop"

    function Clean-BodyText {
        param([string]$Body)
        $clean = $Body
        $clean = $clean -replace "`r`n", "`n"
        $clean = $clean -replace [regex]::Escape('\n'), "`n"
        $clean = $clean -replace "\\`n", "`n"
        $clean = $clean -replace "`n`n`n+", "`n`n"
        return $clean.Trim()
    }

    $token = gh auth token 2>$null
    $headers = @{
        "Authorization" = "Bearer $token"
        "Accept" = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    $issue = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/issues/$Number" -Headers $headers -Method Get
    $currentBody = $issue.body

    if ($Clean) {
        $payload = @{ body = Clean-BodyText -Body $currentBody }
    } elseif ($Append) {
        $payload = @{ body = "$currentBody`n`n$Body" }
    } else {
        $payload = @{ body = $Body }
    }

    $result = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/issues/$Number" `
        -Headers $headers -Method Patch -Body ($payload | ConvertTo-Json -Depth 3)

    Write-Output $result
}

if (-not $isDotSourced) {
    if (-not $Owner) { throw "Missing required parameter: Owner" }
    if (-not $Repo) { throw "Missing required parameter: Repo" }
    if ($Number -eq 0) { throw "Missing required parameter: Number" }
    Update-GitHubIssueBody -Owner $Owner -Repo $Repo -Number $Number -Body $Body -Append:$Append -Clean:$Clean
}
