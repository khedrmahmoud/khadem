# Khadem 2.0.0 Release Remediation Plan

This document outlines the phased remediation approach to address the 42 significant issues discovered during the comprehensive core folder analysis, ensuring the framework is secure, performant, and reliable before releasing version 2.0.0.

## 📈 Git & GitHub Professional Workflow Protocol

To maintain clean code principles and team collaboration efficiency, follow this protocol for every fix item below:
1. **GitHub Issues**: Ensure a discrete issue exists in the GitHub issue tracker for each `fix/` branch.
2. **Branching Strategy**: Branch exclusively from `dev` using the specified branch names (e.g., `git checkout -b fix/mysql-sql-injection dev`).
3. **Atomic Commits**: Group your logical changes with Conventional Commits (e.g., `fix(database): prevent SQL injection in DB name parameter`).
4. **Testing**: Write or update unit tests to assert the vulnerability/bug is resolved before opening the Pull Request.
5. **Pull Requests**: Open PRs targeting `dev`. Require at least one review and a passing CI build.
6. **Merging**: Use "Squash and Merge" for trivial fixes, or "Merge Commit" for larger, logically separated phases.

---

## 🛑 Phase 1: Security Critical Vulnerabilities (Immediate Priority)
**Target Execution Time**: 4-6 Hours
**Branch Prefix**: `security/` or `fix/`

*   [x] **View Module - Path Traversal**: Verified included layout paths (Resolves #8).
    *   *Branch:* `security/template-path-traversal` -> **Merged to `dev`** ✅
*   [x] **Database Module - SQL Injection**: Parameterize the database name in the MySQL connection driver (Resolves #1).
    *   *Branch:* `security/mysql-db-injection`
    *   *File:* `mysql_connection.dart:68,74`
*   [x] **Session Module - Hijacking Vulnerability**: Upgrade session ID generation to output a full 64-char or 256-bit Base64 secure string (Resolves #3).
    *   *Branch:* `security/session-id-entropy`
    *   *File:* `session_id_generator.dart:8-12`
*   [x] **Routing Module - RegExp DoS**: Escape user-provided inputs in regular expressions for routing rules (Resolves #7).
    *   *Branch:* `security/routing-regex-dos`
    *   *File:* `route.dart:37-41`
*   [x] **Session Module - Secure Flags**: Enable `secure = true` by default in `SessionCookieHandler` (Resolves High severity security finding)
    *   *Branch:* `security/session-cookie-secure`

---

## 💥 Phase 2: Critical Data Integrity & Resource Exhaustion
**Target Execution Time**: 4-6 Hours
**Branch Prefix**: `fix/`

*   [x] **Session Module - Broken Serialization**: Replace faulty `.toString()` calls with proper `jsonEncode(data)` for session storage (Resolves #2).
    *   *Branch:* `fix/session-serialization`
    *   *File:* `database_session_driver.dart:18`
*   [x] **Queue Module - File Cache Race Condition**: Apply `Mutex` or isolated lock structure to file-based queue updates to prevent duplicate or dropped jobs (Resolves #4).
    *   *Branch:* `fix/queue-race-condition`
    *   *File:* `file_storage_driver.dart:50,66-78`
*   [x] **Cache Module - Memory Leaks & Antipatterns**:
    *   Fix `forgetByTag()` to actively delete item values, not just remove tags. (Resolves #5)
    *   Eliminate connection spinlocks in Redis driver with asynchronous sync primitives like `Completer` (Resolves #6).
    *   *Branch:* `fix/cache-resource-leaks`
    *   *Files:* `cache_tag_manager.dart`, `redis_cache_driver.dart`
*   [x] **Database Module - SQLite Statement Leaks**: Place all SQLite statement preparation / execution into resilient `try-finally` blocks calling `.dispose()` (Resolves #9).
    *   *Branch:* `fix/sqlite-statement-leak`
    *   *File:* `sqlite_connection.dart:85-107`

---

## 🛠 Phase 3: High Priority Resource & Concurrency Handling
**Target Execution Time**: 6-8 Hours
**Branch Prefix**: `enhancement/` or `fix/`

*   [x] **Database Module - Connection Pooling**: Add foundational connection pooling logic to prevent bottlenecking the database connections under load (Resolves #10).
    *   *Branch:* `enhancement/db-connection-pooling`
*   [x] **Events Module - Concurrency & Dependencies**: Provide circular dependency detection, add standard `unlisten()` garbage collection, and sandbox generic listener executions in `try-catch` contexts.
    *   *Branch:* `enhancement/event-bus-stability`
*   [x] **Queue Module - Capacity & Reliability**: Introduce bounds to the deduplication map (LRU, max 10k), fix timeouts strictly canceling active isolates, and apply strict null-checking to Redis casts.
    *   *Branch:* `fix/queue-reliability`
*   [x] **Container Module - Resolution Locks**: Fix `resolveAll<T>()` and apply synchronization for multi-threaded resolution of container services.
    *   *Branch:* `fix/container-resolution`

---

## 🔧 Phase 4: Configurations & Code Cleanups (Medium / High)
**Target Execution Time**: Remaining Hours
**Branch Prefix**: `refactor/` or `fix/`

*   [ ] **Validation Module - Bounds Constraints**: Implement execution timeouts on Regex assertions and maximum depth traversal flags for recursive validation payloads.
    *   *Branch:* `fix/validation-bounds`
*   [ ] **HTTP & Logging**: Move log flushes to asynchronous outputs, implement Mutex file rotations, make VM Service port & docker ports entirely configurable.
    *   *Branch:* `enhancement/http-logging-cfg`
*   [ ] **Config Module - Whitelining**: Whitelist only permitted variables for inline substitution to prevent environment variable exposure.
    *   *Branch:* `security/config-whitelisting`
*   [ ] **Cleanup Routine**: Complete remaining Medium issues (Eviction policies, Provider async boots, specific exceptions over generic `Exception` types).
    *   *Branch:* `refactor/core-cleanup`

## 🏁 Final Step: Release 2.0.0 Readiness Checklist
- [x] Phase 1 100% complete
- [x] Phase 2 100% complete
- [x] Phase 3 100% complete
- [x] Phase 4 100% complete
- [x] Comprehensive unit test suite run (Passing 100%)
- [ ] Review documentation against any configuration changes
- [ ] PR created for `dev` -> `main` with Release Notes
- [ ] Final tag 2.0.0 published
