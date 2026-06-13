$ErrorActionPreference = "Stop"
$Owner = "pronative-ai"
$Repo = "ai-assisted-starter-AS-2606-101"
$OrgName = "pronative-ai"
$ProjectNumber = 3

$pat = if ($env:AGENT_GITHUB_CONNECT) { $env:AGENT_GITHUB_CONNECT } else { $env:GH_TOKEN }
if (-not $pat) { Write-Error "No PAT found"; exit 1 }
$env:GH_TOKEN = $pat

$ghBase = "repos/$Owner/$Repo"

Write-Host "=== GitHub Issue Propagation ===" -ForegroundColor Cyan

function New-GitHubIssue {
    param($Title, $BodyPath, $Label)
    $bodyContent = Get-Content -LiteralPath $BodyPath -Raw -Encoding utf8
    $tmp = [System.IO.Path]::GetTempFileName()
    $payload = @{ title = $Title; body = $bodyContent; labels = @($Label) } | ConvertTo-Json -Depth 10
    Write-JsonFile -Content $payload -Path $tmp
    try {
        $result = gh api $ghBase/issues --method POST --input $tmp 2>&1 | ConvertFrom-Json
        Write-Host "  Created: #$($result.number) - $Title" -ForegroundColor Green
        return $result.number
    } catch { Write-Host "  Failed: $Title" -ForegroundColor Red; return $null }
    finally { if (Test-Path $tmp) { Remove-Item $tmp -Force } }
}

function Update-GitHubIssueBody {
    param($IssueNumber, $BodyPath)
    $bodyContent = Get-Content -LiteralPath $BodyPath -Raw -Encoding utf8
    $tmp = [System.IO.Path]::GetTempFileName()
    $payload = @{ body = $bodyContent } | ConvertTo-Json -Depth 5
    Write-JsonFile -Content $payload -Path $tmp
    try { gh api "$ghBase/issues/$IssueNumber" --method PATCH --input $tmp 2>&1 | Out-Null; Write-Host "  Updated #$IssueNumber" -ForegroundColor Green }
    catch { Write-Host "  Failed to update #$IssueNumber" -ForegroundColor Red }
    finally { if (Test-Path $tmp) { Remove-Item $tmp -Force } }
}

function Write-JsonFile {
    param($Content, $Path)
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Write-BodyFile {
    param($Content, $Path)
    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-GraphQL {
    param($Query)
    $tmp = [System.IO.Path]::GetTempFileName()
    $json = '{"query":"' + $Query.Replace('"', '\"') + '"}'
    Write-JsonFile -Content $json -Path $tmp
    try { return gh api graphql --input $tmp 2>&1 | ConvertFrom-Json }
    finally { if (Test-Path $tmp) { Remove-Item $tmp -Force } }
}

function Get-ProjectNodeId {
    $q = 'query{organization(login:"' + $OrgName + '"){projectV2(number:' + $ProjectNumber + '){id}}}'
    $response = Invoke-GraphQL -Query $q
    return $response.data.organization.projectV2.id
}

function Add-IssueToProject {
    param($ProjectId, $IssueNodeId)
    $q = 'mutation{addProjectV2ItemById(input:{projectId:"' + $ProjectId + '"contentId:"' + $IssueNodeId + '"}){item{id}}}'
    try {
        Invoke-GraphQL -Query $q | Out-Null
        Write-Host "  Added to project" -ForegroundColor Green
    }
    catch { Write-Host "  Failed to add to project" -ForegroundColor Yellow }
}

function Get-IssueNodeId {
    param($IssueNumber)
    $q = 'query{repository(owner:"' + $Owner + '",name:"' + $Repo + '"){issue(number:' + $IssueNumber + '){id}}}'
    $response = Invoke-GraphQL -Query $q
    return $response.data.repository.issue.id
}

# Step 1: Get Project ID
Write-Host "`n--- Step 1: Getting Project ID ---" -ForegroundColor Yellow
$projectId = Get-ProjectNodeId
Write-Host "  Project ID: $projectId" -ForegroundColor Green

# Step 2: Create Epic
Write-Host "`n--- Step 2: Creating Epic Issue ---" -ForegroundColor Yellow
$epicTitle = "[Epic] Automated FBM Order Fulfillment Pipeline for Amazon.de"

$epicBody = @"
## Summary

Build an end-to-end automation system that replaces manual VA morning workflows for unshipped FBM orders on Amazon.de. The system syncs orders from Amazon Seller Central, intelligently batches them by SKU quantity and brand, generates pick lists and pack slips as PDFs, produces DHL and Easy Ship shipping labels, prevents duplicate processing, and provides a staff dashboard for monitoring and intervention.

The MVP focuses on the core order processing pipeline with integration to Amazon Seller Central, DHL, and Easy Ship APIs. Target users are Virtual Assistants (VAs) and operations staff who manage Amazon.de FBM order fulfillment daily.

**Business Goal**: Eliminate manual VA work every morning by fully automating the unshipped FBM order processing pipeline, reducing processing time from hours to minutes.

## Requirements

### Functional Requirements

| ID | Title | Priority |
|----|-------|----------|
| FR-001 | Amazon.de Order Sync | High |
| FR-002 | Order Item Retrieval | High |
| FR-003 | Intelligent Batch Splitting | High |
| FR-004 | Brand/SKU Group Segregation | Medium |
| FR-005 | Review Flagging | Medium |
| FR-006 | Pick List Generation | High |
| FR-007 | Pack Slip Generation | High |
| FR-008 | Duplicate SKU Prevention | Medium |
| FR-009 | DHL Shipping Label Generation | High |
| FR-010 | Easy Ship Shipping Label Generation | High |
| FR-011 | PDF Batch Processing | Medium |
| FR-012 | Staff Dashboard | Medium |
| FR-013 | Comprehensive Logging | Medium |
| FR-014 | Error Handling and Notifications | High |
| FR-015 | Daily Scheduled Execution | High |

### Non-Functional Requirements

| ID | Category | Description | Priority |
|----|----------|-------------|----------|
| NFR-001 | Performance | Processing time under 15 minutes for 500 orders | High |
| NFR-002 | Reliability | Zero data loss in order processing | High |
| NFR-003 | Availability | Max 30 minutes downtime per day | Medium |
| NFR-004 | Security | API authentication with encrypted storage | High |
| NFR-005 | Security | Role-based access control (RBAC) | Medium |
| NFR-006 | Compliance | German marketplace data compliance | High |
| NFR-007 | Compliance | GDPR compliance for customer data | High |
| NFR-008 | Maintainability | Modular architecture for independent updates | Medium |
| NFR-009 | Scalability | Handle 500 to 5000 orders | Low |
| NFR-010 | Observability | Health checks, metrics, and monitoring | Medium |

## Architecture Overview

**Pattern**: Modular monolith with clean module boundaries. PostgreSQL for persistence. Background job queue for async pipeline execution. Server-side PDF generation. Server-rendered web dashboard.
"@

$epicBodyPath = [System.IO.Path]::GetTempFileName() + ".md"
Write-BodyFile -Content $epicBody -Path $epicBodyPath
$epicNum = New-GitHubIssue -Title $epicTitle -BodyPath $epicBodyPath -Label "epic"
Start-Sleep -Milliseconds 500

# Step 3: Create User Story
Write-Host "`n--- Step 3: Creating User Story Issue ---" -ForegroundColor Yellow
$storyTitle = "[User Story] Automated Daily FBM Order Processing Pipeline"

$storyBody = @"
As a Virtual Assistant or operations staff member, I want the system to automatically sync, batch, and process all unshipped FBM orders from Amazon.de each morning so that I can save hours of manual work and focus on exceptions and oversight rather than repetitive order processing.

Epic: #$epicNum

## Acceptance Criteria and Scenarios

### AC-001: Amazon.de Order Sync Completes Successfully
Given valid SP-API credentials, When pipeline executes, Then retrieve all unshipped FBM orders with pagination, log count.

### AC-002: Order Items Retrieved with German Marketplace Details
Given orders retrieved, When processing each order, Then fetch items with SKU, qty, prices, German address, VAT.

### AC-003: Orders Split into Correct Batch Types
Given order items retrieved, When batch splitting runs, Then classify into 4 types: Single SKU q1/q2/q3+, Mixed.

### AC-004: Brand/SKU Group Segregation Applied
Given orders classified, When segregation runs, Then group by brand/SKU group.

### AC-005: Items Correctly Flagged for Review
Given items processed, When evaluated against rules, Then matching items flagged and excluded.

### AC-006: Pick List PDF Generated and Correct
Given orders batched, When pick list generation runs, Then PDF with item locations, quantities, order references.

### AC-007: Pack Slip PDF Generated Per Order
Given orders ready, When pack slip generation runs, Then PDF with items, German address, order ID, barcode.

### AC-008: Duplicate SKU Consolidation
Given same SKU in multiple lines, When generating docs, Then display consolidated quantity.

### AC-009: DHL Shipping Labels Generated as Batched PDF
Given DHL selected, When API called, Then generate label PDFs, compile batch.

### AC-010: Easy Ship Labels Generated as Batched PDF
Given Easy Ship selected, When API called, Then generate label PDFs, compile batch.

### AC-011: PDF Batches Organized Logically
Given multiple PDFs, When compiling, Then organized by type with cover sheets.

### AC-012: Staff Dashboard Shows Current Status
Given user navigates to dashboard, When page loads, Then display pipeline status, orders, flagged items, documents.

### AC-013: Logging Captures All Operations
Given pipeline executed, When reviewing logs, Then searchable logs with timestamps, operations, results.

### AC-014: Error Handling and Notifications Work
Given operation fails, When error handler triggers, Then log, retry 3x, notify, continue.

### AC-015: Daily Scheduled Execution with Manual Trigger
Given schedule configured, When time reached, Then auto-start. Manual trigger also available.

## Definition of Done

1. All 15 functional acceptance criteria pass verification
2. All 6 non-functional acceptance criteria pass verification
3. Pipeline processes 500 test orders within 15 minutes
4. Zero data loss confirmed over 5 consecutive test runs
5. PDF documents are valid and printable on A4
6. DHL and Easy Ship label generation confirmed with test APIs
7. Logs capture all operations with searchable fields
8. Error notifications deliver correctly to configured channels
9. Dashboard displays correctly for both read-only and admin roles
10. German address formatting confirmed correct for all edge cases
"@

$storyBodyPath = [System.IO.Path]::GetTempFileName() + ".md"
Write-BodyFile -Content $storyBody -Path $storyBodyPath
$storyNum = New-GitHubIssue -Title $storyTitle -BodyPath $storyBodyPath -Label "user-story"
Start-Sleep -Milliseconds 500

# Step 4: Create Tasks
Write-Host "`n--- Step 4: Creating Task Issues ---" -ForegroundColor Yellow

$taskDefs = @(
    @{ title = "[Task] Database Schema, Migrations and Data Access Layer"; key = "DB" },
    @{ title = "[Task] Amazon.de SP-API Integration Module"; key = "AMAZON" },
    @{ title = "[Task] Order Processing Engine - Batching, Segregation and Review Rules"; key = "ENGINE" },
    @{ title = "[Task] PDF Document Generation (Pick Lists and Pack Slips)"; key = "PDF" },
    @{ title = "[Task] DHL Shipping Integration Module"; key = "DHL" },
    @{ title = "[Task] Easy Ship Shipping Integration Module"; key = "EASY" },
    @{ title = "[Task] Pipeline Orchestrator, Scheduler and State Management"; key = "ORCH" },
    @{ title = "[Task] Staff Dashboard Web UI with RBAC"; key = "UI" },
    @{ title = "[Task] Logging, Monitoring and Notification Infrastructure"; key = "LOGGING" },
    @{ title = "[Task] Configuration and Secrets Management"; key = "CONFIG" }
)

$taskNumbers = @{}
foreach ($td in $taskDefs) {
    $taskBody = @"
Story: #$storyNum

## Description

Implementation task for the FBM order fulfillment system.

## Acceptance Criteria

Refer to the User Story #$storyNum for related acceptance criteria and the issue-manifest.md for full details.

## Architecture Context

See specification-3.response.json for architecture details.

## Project References

- specification-1.response.json - Functional and non-functional requirements
- specification-2.response.json - Acceptance criteria with GWT scenarios
- specification-3.response.json - Architecture design and implementation slices
- issue-manifest.md - Full issue hierarchy and body content
"@
    $tbPath = [System.IO.Path]::GetTempFileName() + ".md"
    Write-BodyFile -Content $taskBody -Path $tbPath
    $tNum = New-GitHubIssue -Title $td.title -BodyPath $tbPath -Label "task"
    if ($tNum) { $taskNumbers[$td.key] = $tNum }
    Start-Sleep -Milliseconds 500
}

# Step 5: Update Epic with Story Checklist
Write-Host "`n--- Step 5: Updating Epic Body ---" -ForegroundColor Yellow
$updatedEpicBody = $epicBody + "`r`n## User Stories`r`n`r`n- [ ] #$storyNum [User Story] Automated Daily FBM Order Processing Pipeline"
Write-BodyFile -Content $updatedEpicBody -Path $epicBodyPath
Update-GitHubIssueBody -IssueNumber $epicNum -BodyPath $epicBodyPath

# Step 6: Update User Story with Task Checklist
Write-Host "`n--- Step 6: Updating User Story Body ---" -ForegroundColor Yellow
$taskChecklist = "`r`n## Tasks`r`n"
$taskTitleMap = @{
    "DB" = "[Task] Database Schema, Migrations and Data Access Layer"
    "AMAZON" = "[Task] Amazon.de SP-API Integration Module"
    "ENGINE" = "[Task] Order Processing Engine - Batching, Segregation and Review Rules"
    "PDF" = "[Task] PDF Document Generation (Pick Lists and Pack Slips)"
    "DHL" = "[Task] DHL Shipping Integration Module"
    "EASY" = "[Task] Easy Ship Shipping Integration Module"
    "ORCH" = "[Task] Pipeline Orchestrator, Scheduler and State Management"
    "UI" = "[Task] Staff Dashboard Web UI with RBAC"
    "LOGGING" = "[Task] Logging, Monitoring and Notification Infrastructure"
    "CONFIG" = "[Task] Configuration and Secrets Management"
}
$order = @("DB","AMAZON","ENGINE","PDF","DHL","EASY","ORCH","UI","LOGGING","CONFIG")
foreach ($k in $order) { if ($taskNumbers[$k]) { $taskChecklist += "- [ ] #$($taskNumbers[$k]) $($taskTitleMap[$k])`r`n" } }
$updatedStoryBody = $storyBody + $taskChecklist
Write-BodyFile -Content $updatedStoryBody -Path $storyBodyPath
Update-GitHubIssueBody -IssueNumber $storyNum -BodyPath $storyBodyPath

# Step 7: Add to Project Board
Write-Host "`n--- Step 7: Adding Issues to Project Board ---" -ForegroundColor Yellow
$allIssueNumbers = @($epicNum, $storyNum) + ($taskNumbers.Values | Where-Object { $_ -ne $null })
foreach ($issueNum in $allIssueNumbers) {
    try {
        $nodeId = Get-IssueNodeId -IssueNumber $issueNum
        Add-IssueToProject -ProjectId $projectId -IssueNodeId $nodeId
    } catch { Write-Host "  Error adding #$issueNum" -ForegroundColor Yellow }
    Start-Sleep -Milliseconds 300
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " ISSUE PROPAGATION COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Repository: $Owner/$Repo"
Write-Host "Project Board: https://github.com/orgs/$OrgName/projects/$ProjectNumber"
Write-Host ""
Write-Host "Epic (#$epicNum): https://github.com/$Owner/$Repo/issues/$epicNum"
Write-Host ""
Write-Host "Story (#$storyNum): https://github.com/$Owner/$Repo/issues/$storyNum"
Write-Host ""
Write-Host "Tasks:"
foreach ($k in $order) { if ($taskNumbers[$k]) { Write-Host "  #$($taskNumbers[$k]) - $($taskTitleMap[$k])`n    https://github.com/$Owner/$Repo/issues/$($taskNumbers[$k])" } }
Write-Host ""
$total = $allIssueNumbers.Count
Write-Host "Total: 1 Epic + 1 User Story + $($taskNumbers.Count) Tasks = $total issues" -ForegroundColor Green
Write-Host "All issues added to project board: https://github.com/orgs/$OrgName/projects/$ProjectNumber" -ForegroundColor Green

# Cleanup
if (Test-Path $epicBodyPath) { Remove-Item $epicBodyPath -Force }
if (Test-Path $storyBodyPath) { Remove-Item $storyBodyPath -Force }
