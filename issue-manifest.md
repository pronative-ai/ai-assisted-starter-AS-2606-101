# Issue Manifest: Automated FBM Order Fulfillment Pipeline for Amazon.de

## Issue Hierarchy

- **Epic**: #? (to be created)
  - **User Story**: #? (to be created)
    - Task: #? Database Schema & Migrations
    - Task: #? Amazon.de SP-API Integration Module
    - Task: #? Order Processing Engine - Batching & Segregation
    - Task: #? PDF Document Generation (Pick Lists & Pack Slips)
    - Task: #? DHL Shipping Integration Module
    - Task: #? Easy Ship Shipping Integration Module
    - Task: #? Pipeline Orchestrator, Scheduler & State Management
    - Task: #? Staff Dashboard Web UI with RBAC
    - Task: #? Logging, Monitoring & Notification Infrastructure
    - Task: #? Configuration & Secrets Management

---

## 1. Epic Issue

**Title**: [Epic] Automated FBM Order Fulfillment Pipeline for Amazon.de

**Labels**: epic

**Body**:

```
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

### Open Questions
- What is the exact daily processing window (time of day)?
- What are the thresholds for flagging items for review?
- Should DHL or Easy Ship be the default carrier, or is it order-dependent?
- What is the maximum number of concurrent API calls allowed by the integrations?
- Should the system support partial fulfillment (splitting orders across multiple shipments)?
- What notification channels are preferred for alerts (email, Slack, etc.)?

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

**Component Modules**: Orchestrator, Amazon SP-API Sync Module, Order Processing Engine, PDF Document Generator, DHL Shipping Module, Easy Ship Shipping Module, Staff Dashboard, Notification Service, Configuration & Secrets Manager, Logging Service

**Data Entities**: Order, OrderItem, BatchAssignment, PipelineRun, DocumentRecord, ReviewFlag, LogEntry, Configuration

## User Stories

- [ ] #? [User Story] Automated Daily FBM Order Processing Pipeline
```

---

## 2. User Story Issue

**Title**: [User Story] Automated Daily FBM Order Processing Pipeline

**Labels**: user-story

**Body**:

```
As a Virtual Assistant or operations staff member, I want the system to automatically sync, batch, and process all unshipped FBM orders from Amazon.de each morning so that I can save hours of manual work and focus on exceptions and oversight rather than repetitive order processing.

Epic: #<epic-number>

## Acceptance Criteria & Scenarios

### AC-001: Amazon.de Order Sync Completes Successfully
**Given** the system is configured with valid Amazon.de Seller Central SP-API credentials
**When** the daily scheduled pipeline executes at the configured morning time
**Then** the system shall retrieve all unshipped FBM orders within the last 24 hours, paginating through results as needed, and log the count of retrieved orders

### AC-002: Order Items Retrieved with German Marketplace Details
**Given** the system has retrieved a list of unshipped orders
**When** processing each order
**Then** the system shall fetch individual order items including SKU, quantity 1–n, unit price, extended price, shipping address (Str., Hausnummer, PLZ, Ort, Land), VAT rate and amount, and any seller notes

### AC-003: Orders Split into Correct Batch Types
**Given** the system has retrieved order items for all unshipped orders
**When** the batch splitting algorithm executes
**Then** orders shall be classified into exactly four batch types: (a) Single SKU qty 1, (b) Single SKU qty 2, (c) Single SKU qty 3+, (d) Mixed/multi-line orders with multiple distinct SKUs

### AC-004: Brand/SKU Group Segregation Applied
**Given** orders have been classified into batch types
**When** the segregation algorithm runs
**Then** order items within each batch type shall be grouped by brand/SKU group, and items from the same brand shall appear consecutively on pick lists

### AC-005: Items Correctly Flagged for Review
**Given** the system has processed all order items
**When** evaluating items against review rules
**Then** items matching any review rule shall be flagged and excluded from automatic document and label generation

### AC-006: Pick List PDF Generated and Correct
**Given** the system has batched and segregated orders
**When** the pick list generation executes
**Then** a PDF pick list shall be generated for each batch/brand group containing item locations, quantities, order references, and batch metadata

### AC-007: Pack Slip PDF Generated Per Order
**Given** the system has prepared orders for fulfillment
**When** pack slip generation executes
**Then** a PDF pack slip shall be generated for each order containing item details, German-formatted address, order ID, date, and barcode/QR code

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
**Then** logs shall contain timestamp, operation type, order IDs, result, duration, and error details — searchable by date range and operation

### AC-014: Error Handling and Notifications Work
**Given** a pipeline operation encounters a failure
**When** the error handling mechanism triggers
**Then** the system shall log, retry up to 3 times with backoff, notify staff on final failure, and continue remaining items

### AC-015: Daily Scheduled Execution with Manual Trigger
**Given** the system is configured with a daily schedule
**When** the scheduled time is reached
**Then** the pipeline shall start automatically. Manual trigger shall also be available via the dashboard for authorized users.

## Verification & Edge Cases

Verified through unit tests, integration tests (Amazon SP-API, DHL, Easy Ship sandboxes), and manual tests (PDF visual inspection, print tests, German address formatting).

Key edge cases: no orders, API failures, partial failures, rate limiting, German special characters (ä, ö, ü, ß), Packstation addresses, duplicate SKUs, concurrent runs.

## Test Guidance

- **Unit Tests**: Batch splitting, brand segregation, duplicate consolidation, review rules, PDF metadata, German locale formatting
- **Integration Tests**: Amazon SP-API sync with pagination, DHL/Easy Ship label generation, error notification delivery, RBAC enforcement
- **Manual Tests**: Full end-to-end pipeline with real Amazon.de seller account (sandbox), PDF visual inspection, dashboard UX, A4 print test

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

- [ ] #? [Task] Database Schema, Migrations & Data Access Layer
- [ ] #? [Task] Amazon.de SP-API Integration Module
- [ ] #? [Task] Order Processing Engine - Batching, Segregation & Review Rules
- [ ] #? [Task] PDF Document Generation (Pick Lists & Pack Slips)
- [ ] #? [Task] DHL Shipping Integration Module
- [ ] #? [Task] Easy Ship Shipping Integration Module
- [ ] #? [Task] Pipeline Orchestrator, Scheduler & State Management
- [ ] #? [Task] Staff Dashboard Web UI with RBAC
- [ ] #? [Task] Logging, Monitoring & Notification Infrastructure
- [ ] #? [Task] Configuration & Secrets Management
```

---

## 3. Task Issues

### Task 1: [Task] Database Schema, Migrations & Data Access Layer

**Labels**: task

**Body**:

```
Story: #<story-number>

## Description

Implement the database foundation for the FBM order fulfillment system. This includes PostgreSQL schema design with all entities (orders, order_items, batch_assignments, pipeline_runs, documents, review_flags, log_entries, configuration), migration scripts with up/down support, data access layer with repository pattern, query helpers for common operations, indexing strategy for query performance, and seed data for development/testing.

## Related Functional Requirements

None directly — this is foundational infrastructure enabling all functional requirements.

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: Database schema and indexing designed for ≤15 min processing of 500 orders
- **NFR-002 (Reliability)**: ACID compliance ensures no data loss
- **NFR-009 (Scalability)**: Schema designed to scale from 500 to 5000 daily orders

## Acceptance Criteria

N/A — this is foundational infrastructure. Verified through:
- Migration scripts run cleanly up and down
- All entity tables created with correct columns, types, and constraints
- Indexes created for query performance
- Seed data loads successfully
- Repositories return correct data shapes

## Architecture Context

**Component Model**: This task implements foundational data layer for all 10 components. See specification-3.response.json CMP-001 through CMP-010.

**Data Model Entities**:
- Order, OrderItem, BatchAssignment, PipelineRun, DocumentRecord, ReviewFlag, LogEntry, Configuration
- Full schema defined in specification-3.response.json data_model_guidance

**Suggested Order**: 0 (Foundation - implement first)

**Files Affected**:
- src/db/migrations/
- src/db/schema.sql
- src/db/repositories/orders.js
- src/db/repositories/pipeline-runs.js
- src/db/repositories/batches.js
- src/db/repositories/documents.js
- src/db/repositories/logs.js
- src/db/repositories/config.js
- src/db/connection.js
- src/db/seed.js
```

---

### Task 2: [Task] Amazon.de SP-API Integration Module

**Labels**: task

**Body**:

```
Story: #<story-number>

## Description

Implement the Amazon Selling Partner API integration module. This includes: OAuth/IAM authentication flow with Amazon's security model, paginated order retrieval for FBM unshipped orders, order item fetching per order, rate limit handling with exponential backoff, error handling for API failures and token expiry, and a data transformation layer that maps Amazon's response structure to the internal Order/OrderItem data models.

## Related Functional Requirements

- **FR-001 (Amazon.de Order Sync)**: The system shall authenticate with Amazon.de Seller Central SP-API and retrieve all unshipped FBM orders daily with pagination and rate limit respect
- **FR-002 (Order Item Retrieval)**: The system shall fetch individual order items including SKU, quantity, price, shipping address, and tax information specific to the German marketplace

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: Order sync must complete within the 15-minute total pipeline time
- **NFR-004 (Security - API Authentication)**: Credentials shall be stored encrypted at rest; no plain-text in logs
- **NFR-006 (German Marketplace Compliance)**: Correct handling of German address formats, VAT, and marketplace specifics

## Acceptance Criteria

### AC-001: Amazon.de Order Sync Completes Successfully
**Given** the system is configured with valid Amazon.de Seller Central SP-API credentials
**When** the daily scheduled pipeline executes at the configured morning time
**Then** the system shall retrieve all unshipped FBM orders within the last 24 hours, paginating through results as needed, and log the count of retrieved orders

**Verification**: Check pipeline logs for successful sync completion with order count matching Amazon Seller Central dashboard

**Edge Cases**:
- No unshipped orders exist — system logs '0 orders retrieved' and skips processing
- API returns rate limit error — system backs off and retries up to 3 times
- API token has expired — system logs authentication failure and sends notification

### AC-002: Order Items Retrieved with German Marketplace Details
**Given** the system has retrieved a list of unshipped orders
**When** processing each order
**Then** the system shall fetch individual order items including SKU, quantity 1–n, unit price, extended price, shipping address (Str., Hausnummer, PLZ, Ort, Land), VAT rate and amount, and any seller notes

**Verification**: Spot-check 5 random orders against Amazon Seller Central order details page

**Edge Cases**:
- Order has more than 100 line items — system fetches all pages
- Shipping address contains special German characters (ä, ö, ü, ß) — preserved correctly
- VAT is 0% or 19% (German standard) — handled correctly

## Architecture Context

**Component**: Amazon SP-API Sync Module (CMP-002) — authenticates, retrieves orders with pagination, fetches order items, handles rate limiting and retries.

**API Boundary**:
- syncOrders(): Order[]
- getOrderItems(orderId): OrderItem[]

**Suggested Order**: 1

**Files Affected**:
- src/modules/amazon-sp-api/client.js
- src/modules/amazon-sp-api/auth.js
- src/modules/amazon-sp-api/orders.js
- src/modules/amazon-sp-api/order-items.js
- src/modules/amazon-sp-api/transformers.js
- src/modules/amazon-sp-api/rate-limiter.js
- src/modules/amazon-sp-api/__tests__/
```

---

### Task 3: [Task] Order Processing Engine - Batching, Segregation & Review Rules

**Labels**: task

**Body**:

```
Story: #<story-number>

## Description

Implement the core order processing engine. This includes: batch classification algorithm (single SKU qty 1/2/3+, mixed/multi-line), brand/SKU group segregation logic, duplicate SKU consolidation, configurable review rule engine (high-value thresholds, address pattern matching, special handling flags), batch assignment data persistence, and pipeline state transitions for the processing stage.

## Related Functional Requirements

- **FR-003 (Intelligent Batch Splitting)**: Split orders into (a) Single SKU qty 1, (b) Single SKU qty 2, (c) Single SKU qty 3+, (d) Mixed/multi-line orders
- **FR-004 (Brand/SKU Group Segregation)**: Segregate order items by brand/SKU group for efficient picking
- **FR-005 (Review Flagging)**: Flag items matching configurable review rules; exclude from automatic processing until reviewed
- **FR-008 (Duplicate SKU Prevention)**: Consolidate multiple line items for the same SKU into a single line

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: Processing must complete within the 15-minute total pipeline time
- **NFR-002 (Reliability)**: 100% of unshipped orders processed each run with zero data loss
- **NFR-006 (German Marketplace Compliance)**: Correct handling of German data formats

## Acceptance Criteria

### AC-003: Orders Split into Correct Batch Types
**Given** the system has retrieved order items for all unshipped orders
**When** the batch splitting algorithm executes
**Then** orders shall be classified into exactly four batch types
**Verification**: For 10 test orders with known compositions, verify each is assigned to the correct batch type

### AC-004: Brand/SKU Group Segregation Applied
**Given** orders have been classified into batch types
**When** the segregation algorithm runs
**Then** order items within each batch type shall be grouped by brand/SKU group
**Verification**: Inspect generated pick list groupings for correct brand segregation

### AC-005: Items Correctly Flagged for Review
**Given** the system has processed all order items
**When** evaluating items against review rules
**Then** items matching any review rule shall be flagged and excluded from automatic document and label generation
**Verification**: Configure test rule (e.g., value > €500), verify matching items are flagged

### AC-008: Duplicate SKU Consolidation
**Given** an order contains multiple line items for the same SKU
**When** generating pick lists and pack slips
**Then** the system shall display the SKU once with the total consolidated quantity
**Verification**: Test order with 3 line items of same SKU — pick list shows 1 line with qty 3

## Architecture Context

**Component**: Order Processing Engine (CMP-003) — classifies orders, segregates by brand, applies review rules, consolidates duplicates.

**Interfaces**:
- classifyOrders(orders): BatchAssignment[]
- applyReviewRules(items): FlaggedItem[]
- consolidateDuplicates(items): ConsolidatedItem[]

**Suggested Order**: 2

**Files Affected**:
- src/modules/order-engine/classifier.js
- src/modules/order-engine/batcher.js
- src/modules/order-engine/segregator.js
- src/modules/order-engine/duplicate-consolidator.js
- src/modules/order-engine/review-rules.js
- src/modules/order-engine/__tests__/
```

---

### Task 4: [Task] PDF Document Generation (Pick Lists & Pack Slips)

**Labels**: task

**Body**:

```
Story: #<story-number>

## Description

Implement the PDF generation module. This includes: HTML template creation for pick lists (organized by batch and brand/SKU group with item locations and quantities), HTML templates for pack slips (per order with German-formatted addresses, item details, barcode/QR code for tracking), PDF rendering via server-side library (Puppeteer or PDFKit), A4 page layout with proper margins, German locale formatting (date format DD.MM.YYYY, number format 1.234,56), batch PDF compilation with cover sheets, and file storage with database metadata.

## Related Functional Requirements

- **FR-006 (Pick List Generation)**: Generate PDF pick lists organized by batch/brand group showing item locations, quantities, and order references
- **FR-007 (Pack Slip Generation)**: Generate PDF pack slips per order with item details, German-formatted shipping address, and order metadata
- **FR-011 (PDF Batch Processing)**: Generate batched PDFs organized by type with cover page summaries

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: PDF generation must complete within the 15-minute total pipeline time
- **NFR-006 (German Marketplace Compliance)**: Correct German date/number formatting and address formats in generated documents

## Acceptance Criteria

### AC-006: Pick List PDF Generated and Correct
**Given** the system has batched and segregated orders
**When** the pick list generation executes
**Then** a PDF pick list shall be generated for each batch/brand group with item locations, quantities, order references, and batch metadata — A4 printable

### AC-007: Pack Slip PDF Generated Per Order
**Given** the system has prepared orders for fulfillment
**When** pack slip generation executes
**Then** a PDF pack slip shall be generated for each order with item details, German-formatted address (Name, Straße, PLZ Ort, Land), order ID, date, and barcode/QR code

### AC-011: PDF Batches Organized Logically
**Given** the system generates multiple PDF documents
**When** compiling PDF batches
**Then** batches shall be organized by type, subdivided by brand group or carrier, with cover page summary metadata

## Architecture Context

**Component**: PDF Document Generator (CMP-004) — generates pick lists and pack slips as PDFs using HTML templates rendered to PDF. Handles German locale formatting, barcode generation, A4 layout.

**Interfaces**:
- generatePickList(batch): PDF
- generatePackSlip(order): PDF
- compileBatch(documents): PDF

**Suggested Order**: 3

**Files Affected**:
- src/modules/pdf-generator/renderer.js
- src/modules/pdf-generator/templates/pick-list.html
- src/modules/pdf-generator/templates/pack-slip.html
- src/modules/pdf-generator/templates/cover-sheet.html
- src/modules/pdf-generator/templates/partials/
- src/modules/pdf-generator/batch-compiler.js
- src/modules/pdf-generator/formatters.js
- src/modules/pdf-generator/__tests__/
```

---

### Task 5: [Task] DHL Shipping Integration Module

**Labels**: task

**Body**:

```
Story: #<story-number>

## Description

Implement the DHL shipping API integration. This includes: DHL authentication (API key/user credentials), shipment order creation with weight/dimensions (German domestic and international), shipping label request and retrieval as PDF, label format validation, DHL-specific address validation, batch label PDF compilation, error handling with retry logic, and tracking number capture for order records.

## Related Functional Requirements

- **FR-009 (DHL Shipping Label Generation)**: Integrate with DHL shipping API to generate shipping labels as printable PDFs batched for efficiency. Support DHL-specific requirements for German domestic and international shipments.

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: Label generation must complete within the 15-minute total pipeline time
- **NFR-004 (Security - API Authentication)**: DHL API credentials stored encrypted at rest
- **NFR-006 (German Marketplace Compliance)**: Correct address handling for DHL German domestic shipments (Packstation, Postfach support)

## Acceptance Criteria

### AC-009: DHL Shipping Labels Generated as Batched PDF
**Given** orders are ready for shipping and DHL is the selected carrier
**When** the DHL label generation API is called
**Then** the system shall generate DHL shipping labels for each eligible order, produce them as individual PDFs, and compile a batched multi-page PDF for bulk printing

**Verification**: Verify DHL label PDFs are valid (can be opened), check batch PDF contains all labels in order

**Edge Cases**:
- DHL API is unavailable — system retries 3 times with backoff, then logs error and notifies staff
- Order shipping address is outside DHL service area — system attempts Easy Ship or flags for manual handling
- DHL label generation partially fails (e.g., 8/10 succeed) — success and failure both logged

## Architecture Context

**Component**: DHL Shipping Module (CMP-005) — integrates with DHL API to request and retrieve shipping labels. Handles authentication, shipment details, address validation, batch compilation.

**Interfaces**:
- generateLabel(order): PDF
- getLabelStatus(trackingId): Status
- compileBatch(labels): PDF

**Suggested Order**: 4

**Files Affected**:
- src/modules/dhl/client.js
- src/modules/dhl/auth.js
- src/modules/dhl/shipment.js
- src/modules/dhl/label.js
- src/modules/dhl/address-validator.js
- src/modules/dhl/batch-compiler.js
- src/modules/dhl/__tests__/
```

---

### Task 6: [Task] Easy Ship Shipping Integration Module

**Labels**: task

**Body**:

```
Story: #<story-number>

## Description

Implement the Easy Ship shipping API integration. This includes: Easy Ship authentication, shipment order creation, label request and retrieval as PDF, label format validation, batch label PDF compilation, error handling with retry logic, and tracking number capture. Module shall follow the same interface pattern as the DHL module to support the carrier routing engine.

## Related Functional Requirements

- **FR-010 (Easy Ship Shipping Label Generation)**: Integrate with Easy Ship shipping API to generate shipping labels as printable PDFs batched for efficiency

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: Label generation must complete within the 15-minute total pipeline time
- **NFR-004 (Security - API Authentication)**: Easy Ship API credentials stored encrypted at rest

## Acceptance Criteria

### AC-010: Easy Ship Labels Generated as Batched PDF
**Given** orders are ready for shipping and Easy Ship is the selected carrier
**When** the Easy Ship label generation API is called
**Then** the system shall generate Easy Ship shipping labels for each eligible order, produce them as individual PDFs, and compile a batched multi-page PDF for bulk printing

**Verification**: Verify Easy Ship label PDFs are valid, check batch PDF contents

**Edge Cases**:
- Easy Ship API returns quota exceeded error — queue remaining and retry after delay
- Order dimensions/weight exceed Easy Ship limits — flag for manual handling

## Architecture Context

**Component**: Easy Ship Shipping Module (CMP-006) — integrates with Easy Ship API, mirrors DHL module interface for carrier routing consistency.

**Interfaces**:
- generateLabel(order): PDF
- getLabelStatus(trackingId): Status
- compileBatch(labels): PDF

**Suggested Order**: 5

**Files Affected**:
- src/modules/easyship/client.js
- src/modules/easyship/auth.js
- src/modules/easyship/shipment.js
- src/modules/easyship/label.js
- src/modules/easyship/batch-compiler.js
- src/modules/easyship/__tests__/
```

---

### Task 7: [Task] Pipeline Orchestrator, Scheduler & State Management

**Labels**: task

**Body**:

```
Story: #<story-number>

## Description

Implement the pipeline orchestration layer. This includes: background job queue setup (Bull/BullMQ with Redis or pg-boss), pipeline stage sequencing (sync → process → generate docs → generate labels), scheduled execution via cron (configurable time, timezone-aware for CET/CEST), manual trigger endpoint, pipeline state management (idle/running/completed/failed with progress per stage), catch-up logic for missed schedules, concurrent run prevention, carrier routing engine (configurable rules for DHL vs Easy Ship selection), and pipeline status API for the dashboard.

## Related Functional Requirements

- **FR-015 (Daily Scheduled Execution)**: Execute full order processing pipeline on configurable daily schedule with manual trigger support

## Related Non-Functional Requirements

- **NFR-001 (Performance)**: Pipeline orchestration overhead must not significantly impact the 15-minute total time
- **NFR-003 (Availability)**: Maximum 30 minutes downtime per day; catch-up logic for missed schedules

## Acceptance Criteria

### AC-015: Daily Scheduled Execution with Manual Trigger
**Given** the system is configured with a daily schedule (e.g., 06:00 CET)
**When** the scheduled time is reached
**Then** the pipeline shall start automatically without manual intervention. Additionally, an authorized user shall be able to trigger the pipeline manually via the dashboard at any time.

**Verification**: Set schedule to 2 minutes from now, verify auto-start; trigger manually via dashboard, verify execution

**Edge Cases**:
- Manual trigger while pipeline is already running — second trigger rejected with 'Pipeline already running' message
- Scheduled time missed (system was down) — catch-up logic triggers on restart
- Schedule configuration invalid — system uses default schedule and logs warning

## Architecture Context

**Component**: Orchestrator (CMP-001) — coordinates pipeline execution across all stages, manages state, handles scheduling.

**API Endpoints**:
- POST /api/pipeline/trigger (admin) — manual trigger
- GET /api/pipeline/status/:runId — real-time status

**Suggested Order**: 6

**Files Affected**:
- src/orchestrator/pipeline.js
- src/orchestrator/scheduler.js
- src/orchestrator/job-queue.js
- src/orchestrator/carrier-router.js
- src/orchestrator/state-machine.js
- src/orchestrator/catch-up.js
- src/orchestrator/__tests__/
```

---

### Task 8: [Task] Staff Dashboard Web UI with RBAC

**Labels**: task

**Body**:

```
Story: #<story-number>

## Description

Build the web-based dashboard for VAs and operations staff. This includes: server-rendered HTML pages (Express + EJS or similar), pipeline status view with real-time polling/SSE, order processing summary (retrieved, batched, flagged, processed), flagged items review interface (list, filter, resolve for admins), generated documents list with download links, daily processing history calendar, pipeline manual trigger button (admin only), role-based access control (read-only vs admin roles), simple authentication (session-based or API key), responsive CSS for desktop use, and basic error states and loading indicators.

## Related Functional Requirements

- **FR-012 (Staff Dashboard)**: Provide a simple web-based dashboard showing pending orders, flagged items, batch processing status, generated documents, shipping label status, and daily processing summary. Read-only for regular staff, administrative functions for authorized users.

## Related Non-Functional Requirements

- **NFR-005 (Security - Access Control)**: Role-based access control with read-only and admin roles. Administrative functions require elevated privileges.

## Acceptance Criteria

### AC-012: Staff Dashboard Shows Current Status
**Given** a VA or operations staff member navigates to the dashboard URL
**When** the dashboard page loads
**Then** the dashboard shall display: pending orders count, flagged items requiring review, processing status (idle/running/completed/failed), generated documents summary, daily processing summary with timestamps, and quick actions for authorized users

**Verification**: Login as read-only user, verify all sections load; login as admin, verify quick actions visible

**Edge Cases**:
- No processing has run today — dashboard shows 'No data for today' with yesterday's summary
- Dashboard loads while pipeline is running — shows real-time progress indicators
- User has JavaScript disabled — basic HTML fallback shows key metrics

## Architecture Context

**Component**: Staff Dashboard (CMP-007) — server-rendered web UI with pipeline status, flagged items, document summaries, admin controls.

**API Endpoints**:
- GET /dashboard — server-rendered HTML
- GET /api/pipeline/status/:runId — status data
- GET /api/orders/flagged — flagged items
- POST /api/orders/flagged/:id/resolve (admin) — resolve flagged item
- GET /api/documents/:runId/:type — document list
- POST /api/pipeline/trigger (admin) — manual trigger

**Suggested Order**: 7

**Files Affected**:
- src/web/app.js
- src/web/auth.js
- src/web/rbac.js
- src/web/routes/dashboard.js
- src/web/routes/api.js
- src/web/views/dashboard.ejs
- src/web/views/flagged.ejs
- src/web/views/documents.ejs
- src/web/views/logs.ejs
- src/web/views/layout.ejs
- src/web/public/css/
- src/web/public/js/
```

---

### Task 9: [Task] Logging, Monitoring & Notification Infrastructure

**Labels**: task

**Body**:

```
Story: #<story-number>

## Description

Implement the logging, monitoring, and notification subsystems. This includes: structured logging service with correlation IDs per pipeline run, database log storage with search/query API, stdout logging for container environments, health check endpoints (GET /health, GET /ready), error handling framework with retry logic (exponential backoff, max retries), notification delivery service (email via Nodemailer, Slack/Teams webhook support), daily processing summary email, log retention policy (90-day with archiving), and alert configuration for critical failures.

## Related Functional Requirements

- **FR-013 (Comprehensive Logging)**: Maintain detailed logs of all operations including order syncs, batch assignments, document generation, shipping label requests, API calls, and errors. Searchable with 90-day retention.
- **FR-014 (Error Handling and Notifications)**: Handle API failures, network errors, and data inconsistencies gracefully. Retry with configurable backoff. Notify staff on critical failures.

## Related Non-Functional Requirements

- **NFR-010 (Observability)**: Expose health check endpoints and metrics. Structured logs for external log management integration.

## Acceptance Criteria

### AC-013: Logging Captures All Operations
**Given** the pipeline has executed
**When** reviewing system logs
**Then** logs shall contain: timestamp, operation type, order IDs affected, result (success/failure), duration, and error details for failures. Logs shall be searchable by date range, operation type, and order ID.

**Verification**: Execute pipeline, query logs for each major operation and verify completeness

**Edge Cases**:
- Log retention exceeds 90 days — oldest logs archived or rotated
- Disk space low — system warns but continues processing
- Multiple pipelines run same day — logs distinguishable by run ID

### AC-014: Error Handling and Notifications Work
**Given** a pipeline operation encounters a failure
**When** the error handling mechanism triggers
**Then** the system shall: (a) log the error with full details, (b) retry up to 3 times with exponential backoff, (c) if all retries fail, send a notification to configured staff, and (d) continue processing remaining items where possible

**Verification**: Simulate an API failure, verify retry behavior and notification delivery

**Edge Cases**:
- Critical failure at start of pipeline — pipeline aborts with notification
- Transient failure mid-pipeline — retry succeeds, pipeline continues
- Notification delivery fails — logged as separate error event

## Architecture Context

**Components**: Logging Service (CMP-010), Notification Service (CMP-008).

**API Endpoints**:
- GET /api/logs — searchable log query (admin)
- GET /health — health check
- GET /ready — readiness check

**Suggested Order**: 8

**Files Affected**:
- src/infrastructure/logger.js
- src/infrastructure/error-handler.js
- src/infrastructure/retry.js
- src/infrastructure/notifications/email.js
- src/infrastructure/notifications/webhook.js
- src/infrastructure/notifications/templates/
- src/infrastructure/health.js
- src/infrastructure/log-query.js
- src/infrastructure/__tests__/
```

---

### Task 10: [Task] Configuration & Secrets Management

**Labels**: task

**Body**:

```
Story: #<story-number>

## Description

Implement configuration and secrets management. This includes: database-backed configuration store (key-value with JSONB), configuration API endpoints (GET/PUT for non-secrets), encrypted secrets storage using AES-256-GCM, secrets loading from environment variables, configuration validation schema, hot-reload support for non-sensitive config (schedule, thresholds, carrier defaults), audit logging for configuration changes, and seed/migration scripts for initial configuration.

## Related Functional Requirements

None directly — this is supporting infrastructure for all functional requirements.

## Related Non-Functional Requirements

- **NFR-004 (Security - API Authentication)**: All API credentials stored encrypted at rest using AES-256 or equivalent. No plain-text credentials in logs, config files, or code repositories.
- **NFR-008 (Maintainability)**: Configuration changes shall not require code deployments.

## Acceptance Criteria

N/A — supporting infrastructure. Verified through:
- Secrets encrypted and decrypted correctly
- Configuration values readable via API
- Configuration updates persisted and hot-reloaded
- Audit log entries created for configuration changes
- Seed configuration loaded on first run

## Architecture Context

**Component**: Configuration & Secrets Manager (CMP-009) — manages config and encrypted secrets, provides to all modules at startup.

**API Endpoints**:
- GET /api/config — list non-secret config
- PUT /api/config/:key — update config (admin)

**Suggested Order**: 9

**Files Affected**:
- src/infrastructure/config/store.js
- src/infrastructure/config/secrets.js
- src/infrastructure/config/validator.js
- src/infrastructure/config/api-routes.js
- src/infrastructure/config/seed.js
- src/infrastructure/config/__tests__/
```
