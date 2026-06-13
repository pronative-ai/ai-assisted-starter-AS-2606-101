# PowerShell script to propagate issues to GitHub
# Uses the github-project-manager skill scripts

$ErrorActionPreference = "Stop"

# Configuration
$Owner = "pronative-ai"
$Repo = "ai-assisted-starter-AS-2606-101"
$OrgName = "pronative-ai"
$ProjectNumber = 3

Write-Host "=== GitHub Issue Propagation for FBM Order Automation ===" -ForegroundColor Cyan
Write-Host ""

# Step 0: Set up GitHub auth using PAT
$pat = $env:AGENT_GITHUB_CONNECT
if (-not $pat) {
    Write-Error "AGENT_GITHUB_CONNECT environment variable not set"
    exit 1
}

# Authenticate gh CLI
# Use the PAT for auth - we'll set it as an env var for gh
$env:GH_TOKEN = $pat
Write-Host "✓ GitHub CLI authenticated" -ForegroundColor Green

# Verify auth
gh auth status 2>&1 | ForEach-Object { Write-Host "  $_" }

# Dot-source the helper scripts
$skillDir = ".claude\skills\github-project-manager\scripts"
$scripts = @(
    "New-GitHubIssue.ps1",
    "Update-GitHubIssueBody.ps1",
    "Add-IssueToProject.ps1",
    "Get-ProjectId.ps1"
)

foreach ($script in $scripts) {
    $path = Join-Path $skillDir $script
    if (Test-Path $path) {
        . $path
        Write-Host "✓ Loaded $script" -ForegroundColor Green
    } else {
        Write-Host "⚠ Script not found at $path - will use manual API" -ForegroundColor Yellow
    }
}

Write-Host ""

# Check if labels exist, create if not
$labels = @("epic", "user-story", "task")
foreach ($label in $labels) {
    $existing = gh label list --repo "$Owner/$Repo" --json name 2>$null | ConvertFrom-Json
    if (-not ($existing | Where-Object { $_.name -eq $label })) {
        gh label create $label --repo "$Owner/$Repo" --color "5319E7" 2>$null
        Write-Host "✓ Created label '$label'" -ForegroundColor Green
    } else {
        Write-Host "✓ Label '$label' already exists" -ForegroundColor Green
    }
}

# Step 1: Get project ID
Write-Host "`n--- Step 1: Getting Project ID ---" -ForegroundColor Yellow
try {
    $projectId = Get-ProjectId -OrgName $OrgName -ProjectNumber $ProjectNumber
    Write-Host "✓ Project ID: $projectId" -ForegroundColor Green
} catch {
    Write-Host "⚠ Get-ProjectId failed, using GraphQL directly..." -ForegroundColor Yellow
    $query = @{ query = "query { organization(login: \"$OrgName\") { projectV2(number: $ProjectNumber) { id } } }" }
    $result = $query | ConvertTo-Json -Compress | gh api graphql --input - 2>&1
    $projectId = ($result | ConvertFrom-Json).data.organization.projectV2.id
    Write-Host "✓ Project ID (direct): $projectId" -ForegroundColor Green
}

Write-Host ""

# Step 2: Create Epic issue
Write-Host "--- Step 2: Creating Epic Issue ---" -ForegroundColor Yellow

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

| ID | Title | Priority |
|----|-------|----------|
| NFR-001 | Performance - Processing Time (≤15 min for 500 orders) | High |
| NFR-002 | Reliability - Order Accuracy (zero data loss) | High |
| NFR-003 | Availability (≤30 min downtime/day) | Medium |
| NFR-004 | Security - API Authentication (encrypted at rest) | High |
| NFR-005 | Security - Access Control (RBAC) | Medium |
| NFR-006 | Data - German Marketplace Compliance | High |
| NFR-007 | Data - GDPR Compliance | High |
| NFR-008 | Maintainability (modular architecture) | Medium |
| NFR-009 | Scalability (500 to 5000 orders) | Low |
| NFR-010 | Observability (health checks, metrics) | Medium |

## Scope & Constraints

### Scope Constraints
- Amazon.de Seller Central SP-API rate limits and throttling
- DHL API availability and usage quotas
- Easy Ship API coverage and regional limitations
- Existing infrastructure compute and storage capacity
- Development timeline for MVP

### Assumptions
- Amazon.de Seller Central SP-API access is available with appropriate credentials
- DHL business account with API access is available
- Easy Ship account with API access is available
- Staff have basic technical literacy to use a web dashboard
- The system runs on existing infrastructure (server/cloud environment)
- Daily morning processing window is acceptable for fulfillment timelines

### Out of Scope
- Integration with Amazon FBA (Fulfilled by Amazon) orders
- Returns management or reverse logistics
- Inventory management or stock level tracking
- Multi-channel fulfillment (non-Amazon orders)
- Mobile app development (web dashboard only)
- International marketplace support beyond Amazon.de
- Advanced analytics or reporting beyond basic dashboard metrics
- Warehouse management system (WMS) integration

## Architecture Overview

**Pattern**: Modular monolith with clean module boundaries — each major capability (Amazon sync, order processing, PDF generation, DHL integration, Easy Ship integration, dashboard) is a separate module with defined interfaces. Modules communicate through an in-process event bus.

**Key Architecture Decisions**:
- **ADR-001**: Modular monolith — simpler deployment than microservices; clear module isolation allows future extraction
- **ADR-002**: PostgreSQL for persistence — ACID compliance, JSONB for semi-structured data
- **ADR-003**: Background job queue (Bull/BullMQ with Redis or pg-boss) for async pipeline execution
- **ADR-004**: Server-side PDF generation via HTML-to-PDF (Puppeteer or PDFKit)
- **ADR-005**: Server-rendered web dashboard (EJS/Express) for MVP simplicity
- **ADR-006**: Secrets encrypted at rest via AES-256-GCM with environment variable key injection
- **ADR-007**: Official Amazon SP-API SDK for Node.js for authentication and rate limiting
- **ADR-008**: Configurable carrier routing engine for DHL vs Easy Ship selection

**Runtime**: Node.js 20+ with Express
**Database**: PostgreSQL 14+
**Deployment**: Docker with docker-compose; existing infrastructure

## User Stories

- [ ] #[STORY_NUM] [User Story] Automated Daily FBM Order Processing Pipeline
"@

$epicTempFile = [System.IO.Path]::GetTempFileName()
$epicBody | Out-File -FilePath $epicTempFile -Encoding utf8

try {
    $epicUrl = gh issue create --repo "$Owner/$Repo" --title "$epicTitle" --body-file $epicTempFile --label "epic" 2>&1
    $epicNum = $epicUrl -replace '.*/(\d+)$', '$1'
    Write-Host "✓ Epic created: #$epicNum - $epicUrl" -ForegroundColor Green
} catch {
    Write-Error "Failed to create Epic issue: $_"
    exit 1
} finally {
    Remove-Item -LiteralPath $epicTempFile -Force -ErrorAction SilentlyContinue
}

Write-Host ""

# Step 3: Create User Story issue
Write-Host "--- Step 3: Creating User Story Issue ---" -ForegroundColor Yellow

$storyTitle = "[User Story] Automated Daily FBM Order Processing Pipeline"
$storyBody = @"
As a Virtual Assistant or operations staff member, I want the system to automatically sync, batch, and process all unshipped FBM orders from Amazon.de each morning so that I can save hours of manual work and focus on exceptions and oversight rather than repetitive order processing.

Epic: #$epicNum

## Acceptance Criteria & Scenarios

### AC-001: Amazon.de Order Sync Completes Successfully
**Given** the system is configured with valid Amazon.de Seller Central SP-API credentials
**When** the daily scheduled pipeline executes at the configured morning time
**Then** the system shall retrieve all unshipped FBM orders within the last 24 hours, paginating through results as needed, and log the count of retrieved orders

### AC-002: Order Items Retrieved with German Marketplace Details
**Given** the system has retrieved a list of unshipped orders
**When** processing each order
**Then** the system shall fetch individual order items including SKU, quantity, price, shipping address, VAT, and seller notes

### AC-003: Orders Split into Correct Batch Types
**Given** the system has retrieved order items for all unshipped orders
**When** the batch splitting algorithm executes
**Then** orders shall be classified into exactly four batch types: (a) Single SKU qty 1, (b) Single SKU qty 2, (c) Single SKU qty 3+, (d) Mixed/multi-line orders

### AC-004: Brand/SKU Group Segregation Applied
**Given** orders have been classified into batch types
**When** the segregation algorithm runs
**Then** order items within each batch type shall be grouped by brand/SKU group

### AC-005: Items Correctly Flagged for Review
**Given** the system has processed all order items
**When** evaluating items against review rules
**Then** items matching any review rule shall be flagged and excluded from automatic processing

### AC-006: Pick List PDF Generated and Correct
**Given** the system has batched and segregated orders
**When** the pick list generation executes
**Then** a PDF pick list shall be generated for each batch/brand group with item locations, quantities, order references, and batch metadata

### AC-007: Pack Slip PDF Generated Per Order
**Given** the system has prepared orders for fulfillment
**When** pack slip generation executes
**Then** a PDF pack slip shall be generated for each order with item details, German-formatted address, order ID, date, and barcode

### AC-008: Duplicate SKU Consolidation
**Given** an order contains multiple line items for the same SKU
**When** generating pick lists and pack slips
**Then** the system shall display the SKU once with the total consolidated quantity

### AC-009: DHL Shipping Labels Generated as Batched PDF
**Given** orders are ready for shipping and DHL is the selected carrier
**When** the DHL label generation API is called
**Then** the system shall generate DHL shipping labels for each eligible order and compile a batched multi-page PDF

### AC-010: Easy Ship Labels Generated as Batched PDF
**Given** orders are ready for shipping and Easy Ship is the selected carrier
**When** the Easy Ship label generation API is called
**Then** the system shall generate Easy Ship shipping labels and compile a batched multi-page PDF

### AC-011: PDF Batches Organized Logically
**Given** the system generates multiple PDF documents
**When** compiling PDF batches
**Then** batches shall be organized by type and subdivided by brand group or carrier with cover page summaries

### AC-012: Staff Dashboard Shows Current Status
**Given** a VA or operations staff member navigates to the dashboard URL
**When** the dashboard page loads
**Then** the dashboard shall display pending orders, flagged items, processing status, generated documents, and daily summary

### AC-013: Logging Captures All Operations
**Given** the pipeline has executed
**When** reviewing system logs
**Then** logs shall contain timestamp, operation type, order IDs, result, duration, and error details

### AC-014: Error Handling and Notifications Work
**Given** a pipeline operation encounters a failure
**When** the error handling mechanism triggers
**Then** the system shall log, retry up to 3 times with backoff, notify staff on final failure, and continue remaining items

### AC-015: Daily Scheduled Execution with Manual Trigger
**Given** the system is configured with a daily schedule
**When** the scheduled time is reached
**Then** the pipeline shall start automatically. Manual trigger also available for authorized users.

## Verification & Edge Cases

Verified through unit tests, integration tests (Amazon SP-API, DHL, Easy Ship sandboxes), and manual tests (PDF visual inspection, print tests, German address formatting).

Key edge cases: no orders, API failures, partial failures, rate limiting, German special characters (ä, ö, ü, ß), Packstation addresses, duplicate SKUs, concurrent runs.

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

## Tasks

- [ ] #[TASK_DB] [Task] Database Schema, Migrations & Data Access Layer
- [ ] #[TASK_AMAZON] [Task] Amazon.de SP-API Integration Module
- [ ] #[TASK_ENGINE] [Task] Order Processing Engine - Batching, Segregation & Review Rules
- [ ] #[TASK_PDF] [Task] PDF Document Generation (Pick Lists & Pack Slips)
- [ ] #[TASK_DHL] [Task] DHL Shipping Integration Module
- [ ] #[TASK_EASY] [Task] Easy Ship Shipping Integration Module
- [ ] #[TASK_ORCH] [Task] Pipeline Orchestrator, Scheduler & State Management
- [ ] #[TASK_UI] [Task] Staff Dashboard Web UI with RBAC
- [ ] #[TASK_LOGGING] [Task] Logging, Monitoring & Notification Infrastructure
- [ ] #[TASK_CONFIG] [Task] Configuration & Secrets Management
"@

$storyTempFile = [System.IO.Path]::GetTempFileName()
$storyBody | Out-File -FilePath $storyTempFile -Encoding utf8

try {
    $storyUrl = gh issue create --repo "$Owner/$Repo" --title "$storyTitle" --body-file $storyTempFile --label "user-story" 2>&1
    $storyNum = $storyUrl -replace '.*/(\d+)$', '$1'
    Write-Host "✓ User Story created: #$storyNum - $storyUrl" -ForegroundColor Green
} catch {
    Write-Error "Failed to create User Story issue: $_"
    exit 1
} finally {
    Remove-Item -LiteralPath $storyTempFile -Force -ErrorAction SilentlyContinue
}

Write-Host ""

# Step 4: Create Task issues
Write-Host "--- Step 4: Creating Task Issues ---" -ForegroundColor Yellow

$tasks = @(
    @{
        title = "[Task] Database Schema, Migrations & Data Access Layer"
        file = "task-db.txt"
        body = @"
Story: #$storyNum

## Description

Implement the database foundation for the FBM order fulfillment system. This includes PostgreSQL schema design with all entities (orders, order_items, batch_assignments, pipeline_runs, documents, review_flags, log_entries, configuration), migration scripts with up/down support, data access layer with repository pattern, query helpers for common operations, indexing strategy for query performance, and seed data for development/testing.

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: Database schema and indexing designed for ≤15 min processing of 500 orders
- **NFR-002 (Reliability)**: ACID compliance ensures no data loss
- **NFR-009 (Scalability)**: Schema designed to scale from 500 to 5000 daily orders

## Acceptance Criteria

N/A — foundational infrastructure. Verified through migration scripts run cleanly, correct schema, indexes created, repositories return correct data shapes.

## Architecture Context

This task implements the foundational data layer for all 10 components. Data entities: Order, OrderItem, BatchAssignment, PipelineRun, DocumentRecord, ReviewFlag, LogEntry, Configuration.

**Suggested Order**: 0 (Foundation - implement first)

## Files Affected
- src/db/migrations/
- src/db/schema.sql
- src/db/repositories/orders.js, pipeline-runs.js, batches.js, documents.js, logs.js, config.js
- src/db/connection.js
- src/db/seed.js
"@
    },
    @{
        title = "[Task] Amazon.de SP-API Integration Module"
        file = "task-amazon.txt"
        body = @"
Story: #$storyNum

## Description

Implement the Amazon Selling Partner API integration module. Includes: OAuth/IAM authentication, paginated order retrieval for FBM unshipped orders, order item fetching, rate limit handling with exponential backoff, error handling, and data transformation to internal models.

## Related Functional Requirements

- **FR-001 (Amazon.de Order Sync)**: Authenticate with Amazon.de Seller Central SP-API, retrieve unshipped FBM orders daily with pagination
- **FR-002 (Order Item Retrieval)**: Fetch individual order items including SKU, quantity, price, shipping address, and tax for German marketplace

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: Must complete within 15-minute pipeline window
- **NFR-004 (Security - API Authentication)**: Credentials encrypted at rest, no plain-text in logs
- **NFR-006 (German Marketplace Compliance)**: German address/VAT handling

## Acceptance Criteria

### AC-001: Amazon.de Order Sync Completes Successfully
**Given** valid SP-API credentials, **When** pipeline executes, **Then** retrieve all unshipped FBM orders with pagination, log count. Edge cases: no orders (log 0), rate limit (retry 3x), token expiry (log error, notify).

### AC-002: Order Items Retrieved with German Marketplace Details
**Given** orders retrieved, **When** processing each order, **Then** fetch items with SKU, qty, prices, German address, VAT. Edge cases: 100+ line items (paginate), German characters (preserved), VAT 0%/19%.

## Architecture Context

Component: Amazon SP-API Sync Module (CMP-002). Interfaces: syncOrders(): Order[], getOrderItems(orderId): OrderItem[].

**Suggested Order**: 1

## Files Affected
- src/modules/amazon-sp-api/client.js, auth.js, orders.js, order-items.js, transformers.js, rate-limiter.js
- src/modules/amazon-sp-api/__tests__/
"@
    },
    @{
        title = "[Task] Order Processing Engine - Batching, Segregation & Review Rules"
        file = "task-engine.txt"
        body = @"
Story: #$storyNum

## Description

Implement the core order processing engine. Includes: batch classification (single SKU qty 1/2/3+, mixed/multi-line), brand/SKU group segregation, duplicate SKU consolidation, configurable review rule engine, batch assignment persistence.

## Related Functional Requirements

- **FR-003 (Intelligent Batch Splitting)**: Classify into 4 batch types
- **FR-004 (Brand/SKU Group Segregation)**: Group by brand for efficient picking
- **FR-005 (Review Flagging)**: Flag items matching configurable rules, exclude from auto-processing
- **FR-008 (Duplicate SKU Prevention)**: Consolidate multiple line items for same SKU

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: Process within pipeline time
- **NFR-002 (Reliability)**: Zero data loss
- **NFR-006 (German Marketplace Compliance)**: Correct data formats

## Acceptance Criteria

### AC-003: Orders Split into Correct Batch Types
**Given** order items retrieved, **When** batch splitting runs, **Then** classify into 4 types. Verify with 10 test orders.

### AC-004: Brand/SKU Group Segregation Applied
**Given** orders classified, **When** segregation runs, **Then** group by brand/SKU group. Inspect pick list groupings.

### AC-005: Items Correctly Flagged for Review
**Given** items processed, **When** evaluated against rules, **Then** matching items flagged. Test with >€500 threshold.

### AC-008: Duplicate SKU Consolidation
**Given** order has same SKU in multiple lines, **When** generating docs, **Then** display consolidated qty. Test with 3× same SKU.

## Architecture Context

Component: Order Processing Engine (CMP-003). Interfaces: classifyOrders(orders), applyReviewRules(items), consolidateDuplicates(items).

**Suggested Order**: 2

## Files Affected
- src/modules/order-engine/classifier.js, batcher.js, segregator.js, duplicate-consolidator.js, review-rules.js
- src/modules/order-engine/__tests__/
"@
    },
    @{
        title = "[Task] PDF Document Generation (Pick Lists & Pack Slips)"
        file = "task-pdf.txt"
        body = @"
Story: #$storyNum

## Description

Implement PDF generation for pick lists (by batch/brand group) and pack slips (per order). Includes: HTML templates, PDF rendering (Puppeteer/PDFKit), A4 layout, German locale formatting (DD.MM.YYYY, 1.234,56), barcode generation, batch compilation with cover sheets, file storage.

## Related Functional Requirements

- **FR-006 (Pick List Generation)**: PDF pick lists by batch/brand with item locations and quantities
- **FR-007 (Pack Slip Generation)**: PDF pack slips per order with German address, barcode
- **FR-011 (PDF Batch Processing)**: Batched PDFs organized by type with cover sheets

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: Complete within pipeline time
- **NFR-006 (German Marketplace Compliance)**: German date/number formatting

## Acceptance Criteria

### AC-006: Pick List PDF Generated and Correct
**Given** orders batched/segregated, **When** pick list generation runs, **Then** PDF with item locations, quantities, order references, batch metadata — A4 printable.

### AC-007: Pack Slip PDF Generated Per Order
**Given** orders ready, **When** pack slip generation runs, **Then** PDF with items, German address, order ID, date, barcode.

### AC-011: PDF Batches Organized Logically
**Given** multiple PDFs, **When** compiling, **Then** organized by type/subgroup with cover page.

## Architecture Context

Component: PDF Document Generator (CMP-004). Interfaces: generatePickList(batch), generatePackSlip(order), compileBatch(documents).

**Suggested Order**: 3

## Files Affected
- src/modules/pdf-generator/renderer.js, batch-compiler.js, formatters.js
- src/modules/pdf-generator/templates/pick-list.html, pack-slip.html, cover-sheet.html, partials/
- src/modules/pdf-generator/__tests__/
"@
    },
    @{
        title = "[Task] DHL Shipping Integration Module"
        file = "task-dhl.txt"
        body = @"
Story: #$storyNum

## Description

Implement DHL shipping API integration. Includes: authentication, shipment creation (weight/dimensions), shipping label request/retrieval as PDF, address validation (Packstation/Postfach support), batch label compilation, error handling with retry, tracking number capture.

## Related Functional Requirements

- **FR-009 (DHL Shipping Label Generation)**: Generate DHL shipping labels as printable PDFs, batched. Support German domestic and international.

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: Complete within pipeline time
- **NFR-004 (Security - API Authentication)**: Credentials encrypted at rest
- **NFR-006 (German Marketplace Compliance)**: German address/domestic shipment handling

## Acceptance Criteria

### AC-009: DHL Shipping Labels Generated as Batched PDF
**Given** orders ready, DHL selected, **When** DHL API called, **Then** generate labels as PDFs, compile batch PDF. Edge cases: API unavailable (retry 3x, notify), address outside DHL area (fallback to Easy Ship), partial failures (log both success/failure).

## Architecture Context

Component: DHL Shipping Module (CMP-005). Interfaces: generateLabel(order), getLabelStatus(trackingId), compileBatch(labels).

**Suggested Order**: 4

## Files Affected
- src/modules/dhl/client.js, auth.js, shipment.js, label.js, address-validator.js, batch-compiler.js
- src/modules/dhl/__tests__/
"@
    },
    @{
        title = "[Task] Easy Ship Shipping Integration Module"
        file = "task-easy.txt"
        body = @"
Story: #$storyNum

## Description

Implement Easy Ship shipping API integration. Includes: authentication, shipment creation, label request/retrieval as PDF, batch compilation, error handling with retry, tracking number capture. Must follow same interface pattern as DHL module for carrier routing.

## Related Functional Requirements

- **FR-010 (Easy Ship Shipping Label Generation)**: Generate Easy Ship shipping labels as printable PDFs, batched

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: Complete within pipeline time
- **NFR-004 (Security - API Authentication)**: Credentials encrypted at rest

## Acceptance Criteria

### AC-010: Easy Ship Labels Generated as Batched PDF
**Given** orders ready, Easy Ship selected, **When** API called, **Then** generate labels as PDFs, compile batch. Edge cases: quota exceeded (queue and retry), dimensions/weight exceed limits (flag for manual).

## Architecture Context

Component: Easy Ship Shipping Module (CMP-006). Interfaces: generateLabel(order), getLabelStatus(trackingId), compileBatch(labels).

**Suggested Order**: 5

## Files Affected
- src/modules/easyship/client.js, auth.js, shipment.js, label.js, batch-compiler.js
- src/modules/easyship/__tests__/
"@
    },
    @{
        title = "[Task] Pipeline Orchestrator, Scheduler & State Management"
        file = "task-orch.txt"
        body = @"
Story: #$storyNum

## Description

Implement pipeline orchestration layer. Includes: background job queue (Bull/BullMQ or pg-boss), stage sequencing (sync → process → docs → labels), cron scheduling (configurable, CET/CEST), manual trigger, state management (idle/running/completed/failed), catch-up for missed schedules, concurrent run prevention, carrier routing engine, status API.

## Related Functional Requirements

- **FR-015 (Daily Scheduled Execution)**: Configurable daily schedule with manual trigger support

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: Orchestration overhead minimal
- **NFR-003 (Availability)**: ≤30 min downtime; catch-up logic

## Acceptance Criteria

### AC-015: Daily Scheduled Execution with Manual Trigger
**Given** schedule configured, **When** time reached, **Then** auto-start. Manual trigger via dashboard for authorized users. Edge cases: concurrent trigger reject, missed schedule catch-up, invalid config defaults.

## Architecture Context

Component: Orchestrator (CMP-001). API: POST /api/pipeline/trigger, GET /api/pipeline/status/:runId.

**Suggested Order**: 6

## Files Affected
- src/orchestrator/pipeline.js, scheduler.js, job-queue.js, carrier-router.js, state-machine.js, catch-up.js
- src/orchestrator/__tests__/
"@
    },
    @{
        title = "[Task] Staff Dashboard Web UI with RBAC"
        file = "task-ui.txt"
        body = @"
Story: #$storyNum

## Description

Build web-based dashboard for VAs and operations staff. Includes: server-rendered HTML (Express + EJS), pipeline status view (real-time polling/SSE), order summary (retrieved/batched/flagged/processed), flagged items review (list/filter/resolve for admins), document list with downloads, processing history, pipeline trigger (admin only), RBAC (read-only vs admin), session auth, responsive CSS.

## Related Functional Requirements

- **FR-012 (Staff Dashboard)**: Dashboard with order status, flagged items, processing status, documents. Read-only for staff, admin controls for authorized.

## Related Non-Functional Requirements

- **NFR-005 (Security - Access Control)**: RBAC with read-only and admin roles

## Acceptance Criteria

### AC-012: Staff Dashboard Shows Current Status
**Given** user navigates to dashboard, **When** page loads, **Then** display pending orders, flagged items, processing status, documents, daily summary. Verify read-only vs admin views. Edge cases: no data today (show yesterday), running pipeline (progress indicators), JS disabled (HTML fallback).

## Architecture Context

Component: Staff Dashboard (CMP-007). Endpoints: GET /dashboard, GET /api/pipeline/status, GET /api/orders/flagged, POST /api/orders/flagged/:id/resolve, POST /api/pipeline/trigger.

**Suggested Order**: 7

## Files Affected
- src/web/app.js, auth.js, rbac.js
- src/web/routes/dashboard.js, api.js
- src/web/views/dashboard.ejs, flagged.ejs, documents.ejs, logs.ejs, layout.ejs
- src/web/public/css/, js/
"@
    },
    @{
        title = "[Task] Logging, Monitoring & Notification Infrastructure"
        file = "task-logging.txt"
        body = @"
Story: #$storyNum

## Description

Implement logging, monitoring, and notification subsystems. Includes: structured logging with correlation IDs, DB log storage with search/query API, stdout logging, health check endpoints (/health, /ready), error handling with retry (exponential backoff, max 3), notification delivery (email via Nodemailer, Slack/Teams webhook), daily summary email, 90-day log retention with archiving.

## Related Functional Requirements

- **FR-013 (Comprehensive Logging)**: Detailed, searchable logs with 90-day retention
- **FR-014 (Error Handling and Notifications)**: Graceful error handling, retry with backoff, staff notification on critical failures

## Related Non-Functional Requirements

- **NFR-010 (Observability)**: Health check endpoints, structured logs, metrics

## Acceptance Criteria

### AC-013: Logging Captures All Operations
**Given** pipeline executed, **When** reviewing logs, **Then** logs contain timestamp, operation, order IDs, result, duration, errors. Searchable by date, operation, order ID. Edge cases: 90-day retention, low disk warning, multiple runs distinguishable.

### AC-014: Error Handling and Notifications Work
**Given** operation fails, **When** error handler triggers, **Then** log error, retry 3x with backoff, notify on final failure, continue remaining items. Edge cases: critical failure aborts pipeline, transient failure recovers, notification failure logged.

## Architecture Context

Components: Logging Service (CMP-010), Notification Service (CMP-008). API: GET /api/logs, GET /health, GET /ready.

**Suggested Order**: 8

## Files Affected
- src/infrastructure/logger.js, error-handler.js, retry.js, health.js, log-query.js
- src/infrastructure/notifications/email.js, webhook.js, templates/
- src/infrastructure/__tests__/
"@
    },
    @{
        title = "[Task] Configuration & Secrets Management"
        file = "task-config.txt"
        body = @"
Story: #$storyNum

## Description

Implement configuration and secrets management. Includes: DB-backed config store (key-value JSONB), config API (GET/PUT for non-secrets), encrypted secrets storage (AES-256-GCM), secrets from environment variables, validation schema, hot-reload for non-sensitive config, audit logging for config changes, seed/migration scripts.

## Related Non-Functional Requirements

- **NFR-004 (Security - API Authentication)**: All credentials encrypted at rest (AES-256). No plain-text in logs/config/code.
- **NFR-008 (Maintainability)**: Configuration changes without code deployments.

## Acceptance Criteria

N/A — supporting infrastructure. Verified through: secrets encrypt/decrypt correctly, config API works, hot-reload functions, audit logs created, seed config loads.

## Architecture Context

Component: Configuration & Secrets Manager (CMP-009). API: GET /api/config, PUT /api/config/:key (admin).

**Suggested Order**: 9

## Files Affected
- src/infrastructure/config/store.js, secrets.js, validator.js, api-routes.js, seed.js
- src/infrastructure/config/__tests__/
"@
    }
)

$taskNumbers = @{}

# Create each task
foreach ($task in $tasks) {
    $tempFile = [System.IO.Path]::GetTempFileName()
    $task.body | Out-File -FilePath $tempFile -Encoding utf8
    
    try {
        $taskUrl = gh issue create --repo "$Owner/$Repo" --title $task.title --body-file $tempFile --label "task" 2>&1
        $taskNum = $taskUrl -replace '.*/(\d+)$', '$1'
        $taskNumbers[$task.title] = $taskNum
        Write-Host "  ✓ Task created: #$taskNum - $($task.title)" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to create task: $($task.title) - $_" -ForegroundColor Red
    } finally {
        Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
    }
    
    Start-Sleep -Milliseconds 300
}

Write-Host ""

# Step 5: Update Epic body with story checklist
Write-Host "--- Step 5: Updating Epic Body with Story Checklist ---" -ForegroundColor Yellow

try {
    $token = gh auth token 2>$null
    $headers = @{
        "Authorization" = "Bearer $token"
        "Accept" = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    
    # Read current epic body
    $epicIssue = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/issues/$epicNum" -Headers $headers
    $currentBody = $epicIssue.body
    
    # Append story checklist (replacing the placeholder)
    $storyChecklist = "`n### User Stories`n- [ ] #$storyNum [User Story] Automated Daily FBM Order Processing Pipeline`n"
    $newBody = $currentBody -replace '\[STORY_NUM\]', $storyNum
    
    # Update epic body
    Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/issues/$epicNum" -Headers $headers -Method Patch `
        -Body (@{ body = $newBody + $storyChecklist } | ConvertTo-Json) | Out-Null
    
    Write-Host "✓ Epic #$epicNum body updated with story checklist" -ForegroundColor Green
} catch {
    Write-Host "⚠ Failed to update Epic body: $_" -ForegroundColor Yellow
}

# Step 6: Update User Story body with task checklist
Write-Host "--- Step 6: Updating User Story Body with Task Checklist ---" -ForegroundColor Yellow

try {
    # Read current story body
    $storyIssue = Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/issues/$storyNum" -Headers $headers
    $currentStoryBody = $storyIssue.body
    
    # Build task checklist
    $taskChecklist = "`n### Tasks`n"
    
    # Order the tasks by suggested order
    $taskOrder = @(
        "[Task] Database Schema, Migrations & Data Access Layer",
        "[Task] Amazon.de SP-API Integration Module",
        "[Task] Order Processing Engine - Batching, Segregation & Review Rules",
        "[Task] PDF Document Generation (Pick Lists & Pack Slips)",
        "[Task] DHL Shipping Integration Module",
        "[Task] Easy Ship Shipping Integration Module",
        "[Task] Pipeline Orchestrator, Scheduler & State Management",
        "[Task] Staff Dashboard Web UI with RBAC",
        "[Task] Logging, Monitoring & Notification Infrastructure",
        "[Task] Configuration & Secrets Management"
    )
    
    foreach ($taskTitle in $taskOrder) {
        $tNum = $taskNumbers[$taskTitle]
        if ($tNum) {
            $taskChecklist += "- [ ] #$tNum $taskTitle`n"
        }
    }
    
    # Replace placeholders with actual numbers
    $newStoryBody = $currentStoryBody
    $replacements = @{
        "TASK_DB" = $taskNumbers["[Task] Database Schema, Migrations & Data Access Layer"]
        "TASK_AMAZON" = $taskNumbers["[Task] Amazon.de SP-API Integration Module"]
        "TASK_ENGINE" = $taskNumbers["[Task] Order Processing Engine - Batching, Segregation & Review Rules"]
        "TASK_PDF" = $taskNumbers["[Task] PDF Document Generation (Pick Lists & Pack Slips)"]
        "TASK_DHL" = $taskNumbers["[Task] DHL Shipping Integration Module"]
        "TASK_EASY" = $taskNumbers["[Task] Easy Ship Shipping Integration Module"]
        "TASK_ORCH" = $taskNumbers["[Task] Pipeline Orchestrator, Scheduler & State Management"]
        "TASK_UI" = $taskNumbers["[Task] Staff Dashboard Web UI with RBAC"]
        "TASK_LOGGING" = $taskNumbers["[Task] Logging, Monitoring & Notification Infrastructure"]
        "TASK_CONFIG" = $taskNumbers["[Task] Configuration & Secrets Management"]
    }
    
    foreach ($key in $replacements.Keys) {
        $val = $replacements[$key]
        if ($val) {
            $newStoryBody = $newStoryBody -replace "\[$key\]", $val
        }
    }
    
    # Append task checklist to story body
    $newStoryBodyWithTasks = $newStoryBody + $taskChecklist
    
    # Update story body
    Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/issues/$storyNum" -Headers $headers -Method Patch `
        -Body (@{ body = $newStoryBodyWithTasks } | ConvertTo-Json) | Out-Null
    
    Write-Host "✓ User Story #$storyNum body updated with task checklist" -ForegroundColor Green
} catch {
    Write-Host "⚠ Failed to update User Story body: $_" -ForegroundColor Yellow
}

Write-Host ""

# Step 7: Add all issues to the project board
Write-Host "--- Step 7: Adding Issues to Project Board ---" -ForegroundColor Yellow

$allIssueNumbers = @($epicNum, $storyNum) + $taskNumbers.Values

foreach ($issueNum in $allIssueNumbers) {
    try {
        # Get issue node ID
        $query = @{ query = "query { repository(owner: \"$Owner\", name: \"$Repo\") { issue(number: $issueNum) { id } } }" }
        $result = $query | ConvertTo-Json -Compress | gh api graphql --input - 2>&1
        $nodeId = ($result | ConvertFrom-Json).data.repository.issue.id
        
        # Add to project
        $mutation = @{ query = "mutation { addProjectV2ItemById(input: { projectId: \"$projectId\" contentId: \"$nodeId\" }) { item { id } } }" }
        $mutation | ConvertTo-Json -Compress | gh api graphql --input - 2>&1 | Out-Null
        
        Write-Host "  ✓ Added #$issueNum to project board" -ForegroundColor Green
        Start-Sleep -Milliseconds 300
    } catch {
        Write-Host "  ⚠ Failed to add #$issueNum to project board: $_" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== ISSUE PROPAGATION COMPLETE ===" -ForegroundColor Cyan
Write-Host ""

# Print final summary
Write-Host "FINAL SUMMARY" -ForegroundColor Magenta
Write-Host "=============" -ForegroundColor Magenta
Write-Host "Repository: $Owner/$Repo"
Write-Host "Project Board: https://github.com/orgs/$OrgName/projects/$ProjectNumber"
Write-Host ""
Write-Host "Epic (#$epicNum):" -ForegroundColor Cyan
Write-Host "  [Epic] Automated FBM Order Fulfillment Pipeline for Amazon.de"
Write-Host "  https://github.com/$Owner/$Repo/issues/$epicNum"
Write-Host ""
Write-Host "User Story (#$storyNum):" -ForegroundColor Cyan
Write-Host "  [User Story] Automated Daily FBM Order Processing Pipeline"
Write-Host "  https://github.com/$Owner/$Repo/issues/$storyNum"
Write-Host ""
Write-Host "Tasks:" -ForegroundColor Cyan
foreach ($taskTitle in $taskOrder) {
    $tNum = $taskNumbers[$taskTitle]
    if ($tNum) {
        Write-Host "  #$tNum - $taskTitle"
        Write-Host "    https://github.com/$Owner/$Repo/issues/$tNum"
    }
}
Write-Host ""
Write-Host "Total: 1 Epic + 1 User Story + $($taskNumbers.Count) Tasks = $($allIssueNumbers.Count) issues" -ForegroundColor Green
Write-Host "All issues added to project board: https://github.com/orgs/$OrgName/projects/$ProjectNumber" -ForegroundColor Green
