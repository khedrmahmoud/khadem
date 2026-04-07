# 🚨 Khadem Framework v2.0.1 Security Remediation Plan

This document outlines the structured remediation plan for the 12 newly discovered CRITICAL vulnerabilities. All fixes should be developed on dedicated branches stemming from `dev` and merged back using pull requests.

## 🔴 Phase 1: Critical Injections & Traversals (High Priority)
*Targeting the most severe vulnerabilities that allow unauthorized reads, writes, or code injections.*
* **Branch Prefix:** `security/`

- [ ] **SQL Injection (Database Selection)**: MySQL database identifier handling is now validated and safely quoted. PostgreSQL selection hardening remains pending (driver implementation is currently empty in this repo).
- [x] **Path Traversal (Storage LocalDisk)**: Sanitize relative paths securely to ensure `LocalDisk` operations cannot escape the intended storage root constraint.
- [x] **Path Traversal (Cache File Driver)**: Hash or aggressively sanitize cache keys to prevent directory traversal via crafted keys (e.g., `../../`).
- [x] **Path Traversal (HTTP Static Files)**: Restrict file serving middleware to securely resolve against the designated public directory, dropping any requests exceeding the root.

## 🟠 Phase 2: Input Handling & XSS
*Targeting view boundaries and payload executions.*
* **Branch Prefix:** `security/`

- [x] **XSS Vulnerability (View Templates)**: `{{{ }}}` is now escaped by default and explicit raw output requires `{!! !!}`.
- [x] **ReDoS (Email Regex)**: Replaced regex-heavy validation with linear-time structural email validation.
- [x] **Queue Job Deserialization**: Added job type format validation, optional allow-list enforcement, and payload guards for file/Redis queue drivers.

## 🟡 Phase 3: Auth, Sessions, & Logs
*Targeting data leaks and session persistence.*
* **Branch Prefix:** `fix/`

- [x] **Session Fixation**: Introduced session ID regeneration on web guard privilege changes (login/logout).
- [x] **Sensitive Data in Logs**: Added URI query redaction for sensitive keys (authorization/password/token/secret/api_key) in logging middleware.

## 🟢 Phase 4: Core Stability & Container Logic
*Targeting broken state engines and asynchronous startup.*
* **Branch Prefix:** `fix/`

- [ ] **Fire-and-Forget Async Boot**: Refactor DI container initializations and service provider boots to ensure the main server block awaits full readiness instead of orphaned async executions.
- [ ] **`resolveAll<T>()` Broken**: Fix the service container logic bug where `resolveAll` fails to fetch multiple tagged implementations correctly.
- [ ] **Statistics Corruption (Redis)**: Fix the cache driver decrement logic to cleanly atomicise operations and stop stats from drifting.

---
**Status:** In Progress
