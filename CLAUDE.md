# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CCMS (Cloud Customer Management Solution) is an open-source **AL language extension** for Microsoft Dynamics 365 Business Central. It enables partners to manage customer environments, tenants, extensions, backups, and telemetry without direct access to production environments. It is a **PTE (Per-Tenant Extension)**, cloud-only.

## Build & CI/CD

- **Build system**: AL-Go for GitHub (custom fork: `Freddy-D4P/AL-Go@main`)
- **CI/CD**: GitHub Actions workflows in `.github/workflows/` — CICD, PR handler, release creation, and compatibility testing against Current/NextMinor/NextMajor BC versions
- **Code analyzers**: CodeCop, UICop, and PerTenantExtensionCop are all enabled
- **Ruleset**: `CCMS/.vscode/app.ruleset.json` — AA0139, AA0217, AA0218 are demoted to Info (temporary, to be fixed)
- **No test projects exist yet** — `testFolders` in `.AL-Go/settings.json` is empty

### Local Compilation & AL Guidelines

For AL compiler usage (locating `alc.exe`, compiling with analyzers, diagnostic workflow), see `C:\AL\dotfiles\al-compilation.md`.

For AL coding standards (code style, naming, performance, error handling, events, testing), see `C:\AL\dotfiles\alguidelines\content\docs\agentic-coding\vibe-coding-rules\al-guidelines-rules.md`.

## Object ID Range

All objects must use IDs in the range **62000–62049** (50 slots). Check `CCMS/app.json` for the current allocation.

## Project-Specific Conventions

- **Object name prefix**: `D4P` (enforced via CRS AL extension)
- **Namespace pattern**: `D4P.CCMS.<Module>` (e.g., `D4P.CCMS.Environment`, `D4P.CCMS.Telemetry`)
- **File naming**: `<ObjectNameShort>.<ObjectType>.al` for standard objects, `<BaseNameShort>.<ObjectTypeShort><BaseId>-Ext.al` for extensions
- **Examples**: `D4PBCEnvironment.table.al`, `D4PBCEnvironmentCard.page.al`, `D4PBCAPIHelper.codeunit.al`

## Architecture

### Source Layout (`CCMS/src/`)

Each subdirectory is a self-contained module with its own namespace:

| Module | Namespace | Purpose |
|--------|-----------|---------|
| Auth | D4P.CCMS.Auth | Azure AD app registrations and OAuth token management |
| Backup | D4P.CCMS.Backup | Environment backup/export operations |
| Capacity | D4P.CCMS.Capacity | Storage capacity tracking (header/line pattern) |
| Customer | D4P.CCMS.Customer | Customer records (with No. Series integration) |
| Environment | D4P.CCMS.Environment | Core domain — BC environment CRUD, copy, rename, update |
| Extension | D4P.CCMS.Extension | Installed apps/extensions management and PTE object ranges |
| Features | D4P.CCMS.Features | Environment feature flags |
| General | D4P.CCMS.General | Role center, cues, API helper codeunit, admin profile |
| Operation | D4P.CCMS.Operation | Async operation tracking for long-running API calls |
| Permissions | D4P.CCMS.Permissions | Permission sets (D4P BC Admin, D4P BC Admin Read, etc.) |
| Session | D4P.CCMS.Session | Active user sessions per environment |
| Setup | D4P.CCMS.Setup | Centralized config table (`D4P BC Setup`) and debug helper |
| Telemetry | D4P.CCMS.Telemetry | App Insights connections, KQL query store, telemetry data tables |
| Tenant | D4P.CCMS.Tenant | Azure AD tenant records |

### Key Patterns

- **API Helper** (`D4PBCAPIHelper.codeunit.al`): Central codeunit for all HTTP calls. Two methods: `SendAdminAPIRequest` (Admin API v2.28) and `SendAutomationAPIRequest` (Automation API v2.0). All API calls go through this.
- **Setup table** (`D4PBCSetup`): Singleton config record storing API base URLs, debug mode flag, and No. Series references. Auto-initializes with defaults on first access via `GetSetup()`.
- **Helper codeunit per module**: Each domain area has a helper codeunit (e.g., `D4P BC Environment Helper`, `D4P BC Backup Helper`) that encapsulates business logic and API orchestration.
- **Tenant as parent entity**: `D4P BC Tenant` is the top-level entity. Environments, customers, and operations are scoped under tenants.
- **Data classification**: All table fields use `DataClassification = CustomerContent`.

### External APIs

- **Admin API**: `https://api.businesscentral.dynamics.com/admin/v2.28` — environment management, operations, backups, capacity
- **Automation API**: `https://api.businesscentral.dynamics.com/v2.0` — extension management, sessions

## Runtime Requirements

- **BC Application**: 27.0.0.0+
- **Runtime**: 16.0
- **No external package dependencies** — uses only standard Microsoft namespaces

## Translations

Seven translation files in `CCMS/Translations/`: da-DK, de-DE, es-ES, fi-FI, fr-FR, it-IT, nb-NO.
