# Database Query Builder Enhancement: Advanced Features, Performance & Security

**Labels:** `enhancement`, `database`, `query-builder`, `performance`, `security`  
**Milestone:** v1.2.0  
**Priority:** High

---

## 🐛 Current Limitations

The current `MySQLQueryBuilder` implementation is functional but lacks many advanced features found in modern ORMs like Laravel's Eloquent, TypeORM, and Prisma. This limits developer productivity and forces workarounds for common database operations.

### Missing Features

#### 1. **Advanced WHERE Clauses**
```dart
// ❌ NOT SUPPORTED - Need workarounds
query.whereIn('status', ['active', 'pending', 'approved']);
query.whereNotIn('role', ['guest', 'banned']);
query.whereNull('deleted_at');
query.whereNotNull('email_verified_at');
query.whereBetween('age', 18, 65);
query.whereNotBetween('price', 100, 500);
query.whereLike('name', '%John%');
query.whereDate('created_at', '2024-01-01');
query.whereTime('created_at', '14:30:00');
query.whereYear('created_at', 2024);
query.whereMonth('created_at', 12);
query.whereDay('created_at', 25);
query.whereColumn('first_name', '=', 'last_name');
```

#### 2. **JSON Column Operations**
```dart
// ❌ NOT SUPPORTED - MySQL 5.7+ JSON support
query.whereJsonContains('preferences->languages', 'en');
query.whereJsonDoesntContain('options->features', 'premium');
query.whereJsonLength('tags', '>', 3);
query.whereJsonContainsKey('metadata->settings');
```

#### 3. **Advanced Query Operations**
```dart
// ❌ NOT SUPPORTED
query.whereAny(['name', 'email', 'phone'], 'LIKE', '%search%');
query.whereAll(['status' => 'active', 'verified' => true]);
query.whereNone(['banned' => true, 'deleted' => true]);
query.distinct();
query.latest('created_at');  // orderBy('created_at', 'DESC')
query.oldest('created_at');  // orderBy('created_at', 'ASC')
query.inRandomOrder();
query.addSelect('age');  // Add column to existing select
```

#### 4. **Joins**
```dart
// ❌ NOT SUPPORTED
query.join('posts', 'users.id', '=', 'posts.user_id');
query.leftJoin('profiles', 'users.id', '=', 'profiles.user_id');
query.rightJoin('settings', 'users.id', '=', 'settings.user_id');
query.crossJoin('roles');

// Advanced join with multiple conditions
query.join('posts', (join) {
  join.on('users.id', '=', 'posts.user_id')
      .where('posts.published', '=', true);
});
```

#### 5. **Subqueries**
```dart
// ❌ NOT SUPPORTED
query.whereIn('user_id', (subquery) {
  subquery.select(['id']).from('active_users');
});

query.orderBy((subquery) {
  subquery.select(['COUNT(*)']).from('posts')
      .whereColumn('posts.user_id', '=', 'users.id');
}, 'DESC');
```

#### 6. **Bulk Operations**
```dart
// ❌ NOT SUPPORTED
query.insertMany([
  {'name': 'John', 'email': 'john@example.com'},
  {'name': 'Jane', 'email': 'jane@example.com'},
]);

query.upsert(
  [{'email': 'john@example.com', 'name': 'John'}],
  uniqueBy: ['email'],
  update: ['name', 'updated_at'],
);

query.increment('view_count', 1);
query.decrement('stock', 5);
query.incrementEach({'view_count': 1, 'share_count': 1});
```

#### 7. **Chunking & Lazy Loading**
```dart
// ❌ NOT SUPPORTED
await query.chunk(100, (users) async {
  // Process 100 users at a time
  for (final user in users) {
    await processUser(user);
  }
});

await query.chunkById(100, (users) async {
  // Chunk by ID for better performance
});

query.lazy(100).listen((user) {
  // Stream results one by one
  processUser(user);
});
```

#### 8. **Advanced Pagination**
```dart
// ✅ PARTIAL - Only basic paginate() exists
query.simplePaginate(perPage: 15);  // ❌ Missing
query.cursorPaginate(perPage: 15);  // ❌ Missing
```

#### 9. **Locking**
```dart
// ❌ NOT SUPPORTED
query.sharedLock();  // FOR SHARE
query.lockForUpdate();  // FOR UPDATE
```

#### 10. **Union Operations**
```dart
// ❌ NOT SUPPORTED
final query1 = User.query().where('role', '=', 'admin');
final query2 = User.query().where('verified', '=', true);
query1.union(query2);
query1.unionAll(query2);
```

#### 11. **Full-Text Search**
```dart
// ❌ NOT SUPPORTED
query.whereFullText(['title', 'content'], 'search terms');
query.whereFullText(['description'], 'keyword', mode: 'boolean');
```

#### 12. **Security Issues**
```dart
// ⚠️ CURRENT ISSUES
// 1. No SQL injection protection for table names in some cases
// 2. No prepared statement pooling
// 3. No query result caching
// 4. No query timeout configuration
// 5. Missing input sanitization for raw queries
```

---

## ✅ Proposed Enhancements

### Phase 1: Advanced WHERE Clauses (Priority: High)

#### 1.1 **Basic WHERE Extensions**

```dart
abstract class QueryBuilderInterface<T> {
  // ... existing methods ...
  
  /// WHERE column IN (values)
  QueryBuilderInterface<T> whereIn(String column, List<dynamic> values);
  
  /// WHERE column NOT IN (values)
  QueryBuilderInterface<T> whereNotIn(String column, List<dynamic> values);
  
  /// WHERE column IS NULL
  QueryBuilderInterface<T> whereNull(String column);
  
  /// WHERE column IS NOT NULL
  QueryBuilderInterface<T> whereNotNull(String column);
  
  /// WHERE column BETWEEN start AND end
  QueryBuilderInterface<T> whereBetween(String column, dynamic start, dynamic end);
  
  /// WHERE column NOT BETWEEN start AND end
  QueryBuilderInterface<T> whereNotBetween(String column, dynamic start, dynamic end);
  
  /// WHERE column LIKE pattern
  QueryBuilderInterface<T> whereLike(String column, String pattern);
  
  /// WHERE column NOT LIKE pattern
  QueryBuilderInterface<T> whereNotLike(String column, String pattern);
  
  /// WHERE DATE(column) = date
  QueryBuilderInterface<T> whereDate(String column, String date);
  
  /// WHERE TIME(column) = time
  QueryBuilderInterface<T> whereTime(String column, String time);
  
  /// WHERE YEAR(column) = year
  QueryBuilderInterface<T> whereYear(String column, int year);
  
  /// WHERE MONTH(column) = month
  QueryBuilderInterface<T> whereMonth(String column, int month);
  
  /// WHERE DAY(column) = day
  QueryBuilderInterface<T> whereDay(String column, int day);
  
  /// WHERE column1 operator column2 (compare two columns)
  QueryBuilderInterface<T> whereColumn(
    String column1,
    String operator,
    String column2,
  );
}
```

**Implementation Example:**

```dart
class MySQLQueryBuilder<T> implements QueryBuilderInterface<T> {
  @override
  QueryBuilderInterface<T> whereIn(String column, List<dynamic> values) {
    if (values.isEmpty) return this;
    
    final placeholders = List.filled(values.length, '?').join(', ');
    _where.add('`$column` IN ($placeholders)');
    _bindings.addAll(values);
    return this;
  }
  
  @override
  QueryBuilderInterface<T> whereNull(String column) {
    _where.add('`$column` IS NULL');
    return this;
  }
  
  @override
  QueryBuilderInterface<T> whereBetween(
    String column,
    dynamic start,
    dynamic end,
  ) {
    _where.add('`$column` BETWEEN ? AND ?');
    _bindings.addAll([start, end]);
    return this;
  }
  
  @override
  QueryBuilderInterface<T> whereDate(String column, String date) {
    _where.add('DATE(`$column`) = ?');
    _bindings.add(date);
    return this;
  }
}
```

#### 1.2 **JSON Column Support** (MySQL 5.7+)

```dart
abstract class QueryBuilderInterface<T> {
  /// WHERE JSON_CONTAINS(column, value, path)
  QueryBuilderInterface<T> whereJsonContains(
    String column,
    dynamic value, [
    String? path,
  ]);
  
  /// WHERE NOT JSON_CONTAINS(column, value, path)
  QueryBuilderInterface<T> whereJsonDoesntContain(
    String column,
    dynamic value, [
    String? path,
  ]);
  
  /// WHERE JSON_LENGTH(column, path) operator value
  QueryBuilderInterface<T> whereJsonLength(
    String column,
    String operator,
    int length, [
    String? path,
  ]);
  
  /// WHERE JSON_CONTAINS_PATH(column, 'one', path)
  QueryBuilderInterface<T> whereJsonContainsKey(String column, String path);
}
```

**Implementation:**

```dart
@override
QueryBuilderInterface<T> whereJsonContains(
  String column,
  dynamic value, [
  String? path,
]) {
  final jsonValue = value is String ? '"$value"' : jsonEncode(value);
  if (path != null) {
    _where.add('JSON_CONTAINS(`$column`, ?, ?)');
    _bindings.addAll([jsonValue, '\$.$path']);
  } else {
    _where.add('JSON_CONTAINS(`$column`, ?)');
    _bindings.add(jsonValue);
  }
  return this;
}
```

#### 1.3 **Advanced Query Helpers**

```dart
abstract class QueryBuilderInterface<T> {
  /// Matches ANY of the columns with the given operator and value
  QueryBuilderInterface<T> whereAny(
    List<String> columns,
    String operator,
    dynamic value,
  );
  
  /// Matches ALL of the conditions
  QueryBuilderInterface<T> whereAll(Map<String, dynamic> conditions);
  
  /// Matches NONE of the conditions
  QueryBuilderInterface<T> whereNone(Map<String, dynamic> conditions);
  
  /// Shorthand for orderBy(column, 'DESC')
  QueryBuilderInterface<T> latest([String column = 'created_at']);
  
  /// Shorthand for orderBy(column, 'ASC')
  QueryBuilderInterface<T> oldest([String column = 'created_at']);
  
  /// ORDER BY RAND()
  QueryBuilderInterface<T> inRandomOrder();
  
  /// SELECT DISTINCT
  QueryBuilderInterface<T> distinct();
  
  /// Add more columns to select
  QueryBuilderInterface<T> addSelect(List<String> columns);
}
```

---

### Phase 2: JOIN Operations (Priority: High)

```dart
abstract class QueryBuilderInterface<T> {
  /// Basic INNER JOIN
  QueryBuilderInterface<T> join(
    String table,
    String firstColumn,
    String operator,
    String secondColumn, {
    String type = 'INNER',
  });
  
  /// Advanced JOIN with callback
  QueryBuilderInterface<T> joinAdvanced(
    String table,
    void Function(JoinClause join) callback, {
    String type = 'INNER',
  });
  
  /// LEFT JOIN
  QueryBuilderInterface<T> leftJoin(
    String table,
    String firstColumn,
    String operator,
    String secondColumn,
  );
  
  /// RIGHT JOIN
  QueryBuilderInterface<T> rightJoin(
    String table,
    String firstColumn,
    String operator,
    String secondColumn,
  );
  
  /// CROSS JOIN
  QueryBuilderInterface<T> crossJoin(String table);
}

/// Join clause builder for complex joins
class JoinClause {
  final String table;
  final String type;
  final List<String> _conditions = [];
  final List<dynamic> _bindings = [];
  
  JoinClause(this.table, this.type);
  
  /// Add ON condition
  JoinClause on(String first, String operator, String second) {
    _conditions.add('`$first` $operator `$second`');
    return this;
  }
  
  /// Add WHERE condition to JOIN
  JoinClause where(String column, String operator, dynamic value) {
    _conditions.add('`$column` $operator ?');
    _bindings.add(value);
    return this;
  }
  
  /// Add OR ON condition
  JoinClause orOn(String first, String operator, String second) {
    if (_conditions.isEmpty) return on(first, operator, second);
    _conditions.add('OR `$first` $operator `$second`');
    return this;
  }
  
  String toSql() {
    return '$type JOIN `$table` ON ${_conditions.join(' AND ')}';
  }
}
```

**Usage Example:**

```dart
// Simple join
final users = await User.query()
  .join('posts', 'users.id', '=', 'posts.user_id')
  .select(['users.*', 'posts.title'])
  .get();

// Advanced join
final users = await User.query()
  .joinAdvanced('posts', (join) {
    join.on('users.id', '=', 'posts.user_id')
        .where('posts.published', '=', true)
        .where('posts.views', '>', 100);
  })
  .get();
```

---

### Phase 3: Bulk Operations & Utilities (Priority: High)

```dart
abstract class QueryBuilderInterface<T> {
  /// Insert multiple rows at once
  Future<List<int>> insertMany(List<Map<String, dynamic>> rows);
  
  /// Insert or update (UPSERT)
  Future<int> upsert(
    List<Map<String, dynamic>> rows, {
    required List<String> uniqueBy,
    List<String>? update,
  });
  
  /// Increment a column
  Future<void> increment(String column, [int amount = 1]);
  
  /// Decrement a column
  Future<void> decrement(String column, [int amount = 1]);
  
  /// Increment multiple columns
  Future<void> incrementEach(Map<String, int> columns);
  
  /// Process results in chunks
  Future<void> chunk(
    int size,
    Future<void> Function(List<T> items) callback,
  );
  
  /// Process results in chunks by ID
  Future<void> chunkById(
    int size,
    Future<void> Function(List<T> items) callback, {
    String column = 'id',
  });
  
  /// Lazy load results as stream
  Stream<T> lazy([int chunkSize = 100]);
}
```

**Implementation Example:**

```dart
@override
Future<List<int>> insertMany(List<Map<String, dynamic>> rows) async {
  if (rows.isEmpty) return [];
  
  final columns = rows.first.keys.map((k) => '`$k`').join(', ');
  final placeholders = rows.map((row) {
    return '(${List.filled(row.length, '?').join(', ')})';
  }).join(', ');
  
  final values = rows.expand((row) => row.values).toList();
  
  final sql = 'INSERT INTO `$_table` ($columns) VALUES $placeholders';
  final result = await _connection.execute(sql, values);
  
  // Return list of inserted IDs
  final firstId = result.insertId ?? 0;
  return List.generate(rows.length, (i) => firstId + i);
}

@override
Future<void> increment(String column, [int amount = 1]) async {
  if (_where.isEmpty) {
    throw DatabaseException('Increment without WHERE clause is not allowed.');
  }
  
  final sql = 'UPDATE `$_table` SET `$column` = `$column` + ? WHERE ${_where.join(' AND ')}';
  await _connection.execute(sql, [amount, ..._bindings]);
}

@override
Future<void> chunk(
  int size,
  Future<void> Function(List<T> items) callback,
) async {
  int page = 1;
  List<T> items;
  
  do {
    final query = clone();
    items = await query.offset((page - 1) * size).limit(size).get();
    
    if (items.isNotEmpty) {
      await callback(items);
    }
    
    page++;
  } while (items.length == size);
}
```

---

### Phase 4: Advanced Pagination & Locking (Priority: Medium)

```dart
abstract class QueryBuilderInterface<T> {
  /// Simple pagination without total count
  Future<SimplePaginatedResult<T>> simplePaginate({
    int perPage = 15,
    int page = 1,
  });
  
  /// Cursor-based pagination
  Future<CursorPaginatedResult<T>> cursorPaginate({
    int perPage = 15,
    String? cursor,
    String column = 'id',
  });
  
  /// Add shared lock (FOR SHARE)
  QueryBuilderInterface<T> sharedLock();
  
  /// Add exclusive lock (FOR UPDATE)
  QueryBuilderInterface<T> lockForUpdate();
}

class SimplePaginatedResult<T> {
  final List<T> data;
  final int perPage;
  final int currentPage;
  final bool hasMorePages;
  
  SimplePaginatedResult({
    required this.data,
    required this.perPage,
    required this.currentPage,
    required this.hasMorePages,
  });
}

class CursorPaginatedResult<T> {
  final List<T> data;
  final String? nextCursor;
  final String? previousCursor;
  final bool hasMore;
  
  CursorPaginatedResult({
    required this.data,
    this.nextCursor,
    this.previousCursor,
    required this.hasMore,
  });
}
```

---

### Phase 5: Union & Subqueries (Priority: Medium)

```dart
abstract class QueryBuilderInterface<T> {
  /// UNION
  QueryBuilderInterface<T> union(QueryBuilderInterface<T> query);
  
  /// UNION ALL
  QueryBuilderInterface<T> unionAll(QueryBuilderInterface<T> query);
  
  /// Subquery in WHERE IN
  QueryBuilderInterface<T> whereInSubquery(
    String column,
    QueryBuilderInterface<dynamic> Function(QueryBuilderInterface<dynamic>) callback,
  );
  
  /// Subquery in WHERE EXISTS
  QueryBuilderInterface<T> whereExists(
    QueryBuilderInterface<dynamic> Function(QueryBuilderInterface<dynamic>) callback,
  );
  
  /// Subquery in WHERE NOT EXISTS
  QueryBuilderInterface<T> whereNotExists(
    QueryBuilderInterface<dynamic> Function(QueryBuilderInterface<dynamic>) callback,
  );
}
```

---

### Phase 6: Full-Text Search (Priority: Low)

```dart
abstract class QueryBuilderInterface<T> {
  /// Full-text search
  QueryBuilderInterface<T> whereFullText(
    List<String> columns,
    String searchTerm, {
    String mode = 'natural', // natural, boolean, query_expansion
  });
}
```

**Implementation:**

```dart
@override
QueryBuilderInterface<T> whereFullText(
  List<String> columns,
  String searchTerm, {
  String mode = 'natural',
}) {
  final columnList = columns.map((c) => '`$c`').join(', ');
  
  String matchMode;
  switch (mode) {
    case 'boolean':
      matchMode = 'IN BOOLEAN MODE';
      break;
    case 'query_expansion':
      matchMode = 'WITH QUERY EXPANSION';
      break;
    default:
      matchMode = 'IN NATURAL LANGUAGE MODE';
  }
  
  _where.add('MATCH ($columnList) AGAINST (? $matchMode)');
  _bindings.add(searchTerm);
  return this;
}
```

---

### Phase 7: Security Enhancements (Priority: Critical)

```dart
class QueryBuilderConfig {
  /// Maximum query execution time in seconds
  final int queryTimeout;
  
  /// Enable query result caching
  final bool enableCache;
  
  /// Cache TTL in seconds
  final int cacheTtl;
  
  /// Enable SQL injection detection
  final bool enableSqlInjectionDetection;
  
  /// Maximum number of WHERE conditions
  final int maxWhereConditions;
  
  /// Maximum number of JOINs
  final int maxJoins;
  
  const QueryBuilderConfig({
    this.queryTimeout = 30,
    this.enableCache = false,
    this.cacheTtl = 300,
    this.enableSqlInjectionDetection = true,
    this.maxWhereConditions = 50,
    this.maxJoins = 10,
  });
}
```

**Security Improvements:**

1. **SQL Injection Prevention**
   - Validate table names against allowed list
   - Sanitize column names
   - Detect dangerous SQL patterns in raw queries

2. **Query Complexity Limits**
   - Limit number of WHERE conditions
   - Limit number of JOINs
   - Prevent deeply nested subqueries

3. **Query Timeout**
   - Set maximum execution time
   - Prevent long-running queries from blocking

4. **Prepared Statement Pooling**
   - Reuse prepared statements
   - Reduce compilation overhead

5. **Input Validation**
   - Validate data types
   - Sanitize user input
   - Prevent mass assignment vulnerabilities

---

## ✅ Acceptance Criteria

### Phase 1: Advanced WHERE Clauses ✅
- [ ] `whereIn`, `whereNotIn` implemented and tested
- [ ] `whereNull`, `whereNotNull` implemented and tested
- [ ] `whereBetween`, `whereNotBetween` implemented and tested
- [ ] `whereLike`, `whereNotLike` implemented and tested
- [ ] `whereDate`, `whereTime`, `whereYear`, `whereMonth`, `whereDay` implemented
- [ ] `whereColumn` implemented and tested
- [ ] JSON operations: `whereJsonContains`, `whereJsonDoesntContain`, etc.
- [ ] Helper methods: `whereAny`, `whereAll`, `whereNone`
- [ ] `latest`, `oldest`, `inRandomOrder`, `distinct`, `addSelect`

### Phase 2: JOIN Operations ✅
- [ ] `join`, `leftJoin`, `rightJoin`, `crossJoin` implemented
- [ ] Advanced JOIN with `JoinClause` callback
- [ ] Multiple JOIN conditions supported
- [ ] WHERE conditions in JOINs supported

### Phase 3: Bulk Operations ✅
- [ ] `insertMany` with batch insert
- [ ] `upsert` for insert or update
- [ ] `increment`, `decrement`, `incrementEach`
- [ ] `chunk`, `chunkById` for processing large datasets
- [ ] `lazy` for streaming results

### Phase 4: Advanced Pagination & Locking ✅
- [ ] `simplePaginate` without total count
- [ ] `cursorPaginate` for efficient pagination
- [ ] `sharedLock` (FOR SHARE)
- [ ] `lockForUpdate` (FOR UPDATE)

### Phase 5: Union & Subqueries ✅
- [ ] `union`, `unionAll`
- [ ] `whereInSubquery`
- [ ] `whereExists`, `whereNotExists`

### Phase 6: Full-Text Search ✅
- [ ] `whereFullText` with natural, boolean, and query expansion modes

### Phase 7: Security Enhancements ✅
- [ ] SQL injection detection and prevention
- [ ] Query complexity limits
- [ ] Query timeout configuration
- [ ] Input validation and sanitization
- [ ] Prepared statement pooling

### Testing ✅
- [ ] Comprehensive unit tests for all new methods
- [ ] Integration tests with real MySQL database
- [ ] Performance benchmarks for bulk operations
- [ ] Security tests for SQL injection prevention
- [ ] Edge case tests (empty arrays, null values, etc.)

### Documentation ✅
- [ ] API documentation for all new methods
- [ ] Usage examples and best practices
- [ ] Migration guide from current implementation
- [ ] Performance optimization tips

---

## 📊 Impact Assessment

| Aspect | Impact | Notes |
|--------|--------|-------|
| **Breaking Changes** | ⚠️ Minimal | New methods only, existing API unchanged |
| **Performance** | ✅ High Improvement | Bulk operations, chunking, lazy loading |
| **Developer Experience** | ✅ Massive Improvement | Feature parity with Laravel, TypeORM |
| **Security** | ✅ Critical Improvement | SQL injection prevention, query limits |
| **Code Complexity** | ⚠️ Moderate Increase | More methods, more tests needed |
| **Database Compatibility** | ⚠️ MySQL-specific | JSON ops require MySQL 5.7+ |

---

## 🧪 Test Cases

```dart
group('Advanced WHERE Clauses', () {
  test('whereIn with multiple values', () async {
    final users = await User.query()
      .whereIn('status', ['active', 'pending'])
      .get();
    
    expect(users, isNotEmpty);
    expect(users.every((u) => ['active', 'pending'].contains(u.status)), isTrue);
  });
  
  test('whereNull finds records with null values', () async {
    final users = await User.query()
      .whereNull('deleted_at')
      .get();
    
    expect(users.every((u) => u.deletedAt == null), isTrue);
  });
  
  test('whereBetween filters numeric ranges', () async {
    final users = await User.query()
      .whereBetween('age', 18, 65)
      .get();
    
    expect(users.every((u) => u.age >= 18 && u.age <= 65), isTrue);
  });
  
  test('whereJsonContains filters JSON columns', () async {
    final users = await User.query()
      .whereJsonContains('preferences->languages', 'en')
      .get();
    
    expect(users, isNotEmpty);
  });
});

group('JOIN Operations', () {
  test('simple join combines tables', () async {
    final results = await User.query()
      .join('posts', 'users.id', '=', 'posts.user_id')
      .select(['users.name', 'posts.title'])
      .get();
    
    expect(results, isNotEmpty);
  });
  
  test('advanced join with multiple conditions', () async {
    final results = await User.query()
      .joinAdvanced('posts', (join) {
        join.on('users.id', '=', 'posts.user_id')
            .where('posts.published', '=', true);
      })
      .get();
    
    expect(results, isNotEmpty);
  });
});

group('Bulk Operations', () {
  test('insertMany inserts multiple rows', () async {
    final ids = await User.query().insertMany([
      {'name': 'John', 'email': 'john@test.com'},
      {'name': 'Jane', 'email': 'jane@test.com'},
    ]);
    
    expect(ids.length, equals(2));
  });
  
  test('increment increases column value', () async {
    await Post.query()
      .where('id', '=', 1)
      .increment('view_count', 5);
    
    final post = await Post.query().where('id', '=', 1).first();
    expect(post?.viewCount, greaterThan(0));
  });
  
  test('chunk processes results in batches', () async {
    int totalProcessed = 0;
    
    await User.query().chunk(100, (users) async {
      totalProcessed += users.length;
    });
    
    expect(totalProcessed, greaterThan(0));
  });
});

group('Security', () {
  test('prevents SQL injection in whereRaw', () {
    expect(
      () => User.query().whereRaw("id = 1; DROP TABLE users; --"),
      throwsA(isA<SecurityException>()),
    );
  });
  
  test('limits query complexity', () {
    final query = User.query();
    
    // Try to add too many WHERE conditions
    expect(
      () {
        for (int i = 0; i < 100; i++) {
          query.where('col$i', '=', i);
        }
      },
      throwsA(isA<QueryComplexityException>()),
    );
  });
});
```

---

## 📝 Files to Create/Modify

| File | Changes | Priority |
|------|---------|----------|
| `lib/src/contracts/database/query_builder_interface.dart` | Add new method signatures | High |
| `lib/src/core/database/database_drivers/mysql/mysql_query_builder.dart` | Implement all new methods | High |
| `lib/src/core/database/query/join_clause.dart` | Create JOIN clause builder | High |
| `lib/src/core/database/query/query_config.dart` | Create config class | High |
| `lib/src/core/database/query/security_validator.dart` | Create security validator | Critical |
| `lib/src/core/database/orm/simple_paginated_result.dart` | Create simple pagination result | Medium |
| `lib/src/core/database/orm/cursor_paginated_result.dart` | Create cursor pagination result | Medium |
| `test/core/database/query_builder_advanced_test.dart` | Comprehensive tests | High |
| `test/core/database/query_builder_security_test.dart` | Security tests | Critical |
| `test/core/database/query_builder_performance_test.dart` | Performance benchmarks | Medium |

---

## 🔗 Related Issues

- None yet (this is the first major database enhancement)

---

## 📚 Reference Implementations

**Laravel Eloquent (PHP):**
```php
User::whereIn('status', ['active', 'pending'])
    ->whereJsonContains('preferences->languages', 'en')
    ->join('posts', 'users.id', '=', 'posts.user_id')
    ->chunk(100, function ($users) {
        // Process users
    });
```

**TypeORM (TypeScript):**
```typescript
await userRepository
  .createQueryBuilder("user")
  .where("user.status IN (:...statuses)", { statuses: ['active', 'pending'] })
  .innerJoin("user.posts", "post")
  .getMany();
```

**Prisma (TypeScript):**
```typescript
await prisma.user.findMany({
  where: {
    status: { in: ['active', 'pending'] },
    preferences: {
      path: ['languages'],
      array_contains: 'en'
    }
  }
});
```

---

## 🎯 Implementation Phases

### ✅ Phase 1: Advanced WHERE Clauses (Priority: High)
**Estimated Time:** 1-2 weeks
- [ ] Implement basic WHERE extensions
- [ ] Implement JSON operations
- [ ] Implement helper methods
- [ ] Add comprehensive tests

### ✅ Phase 2: JOIN Operations (Priority: High)
**Estimated Time:** 1 week
- [ ] Implement basic joins
- [ ] Create JoinClause class
- [ ] Add tests for all join types

### ✅ Phase 3: Bulk Operations (Priority: High)
**Estimated Time:** 1 week
- [ ] Implement insertMany, upsert
- [ ] Implement increment/decrement
- [ ] Implement chunk, lazy
- [ ] Add performance tests

### ✅ Phase 4: Pagination & Locking (Priority: Medium)
**Estimated Time:** 3-5 days
- [ ] Implement simplePaginate
- [ ] Implement cursorPaginate
- [ ] Implement locking methods

### ✅ Phase 5: Union & Subqueries (Priority: Medium)
**Estimated Time:** 1 week
- [ ] Implement union operations
- [ ] Implement subquery support
- [ ] Add complex query tests

### ✅ Phase 6: Full-Text Search (Priority: Low)
**Estimated Time:** 2-3 days
- [ ] Implement whereFullText
- [ ] Add search tests

### ✅ Phase 7: Security Enhancements (Priority: Critical)
**Estimated Time:** 1 week
- [ ] Implement SQL injection detection
- [ ] Implement query complexity limits
- [ ] Add timeout configuration
- [ ] Security audit and tests

### ✅ Phase 8: Documentation & Polish (Priority: High)
**Estimated Time:** 3-5 days
- [ ] Write API documentation
- [ ] Create usage examples
- [ ] Write migration guide
- [ ] Performance optimization guide

---

## 🎯 Priority

**High** - Modern applications require advanced database query capabilities. This enhancement brings Khadem's ORM to feature parity with industry-leading frameworks.

---

## 💬 Additional Notes

### Why This Matters

1. **Developer Productivity**: Reduces boilerplate code by 70%+
2. **Performance**: Bulk operations and chunking handle large datasets efficiently
3. **Security**: Built-in protection against common vulnerabilities
4. **Modern Features**: JSON operations, full-text search, cursor pagination
5. **Competitive**: Feature parity with Laravel, TypeORM, Prisma

### Technical Considerations

1. **MySQL Version**: JSON operations require MySQL 5.7+
2. **Backward Compatibility**: All changes are additive
3. **Testing**: Comprehensive test suite required
4. **Documentation**: Critical for adoption
5. **Performance**: Benchmarks needed to validate improvements

---

## 📈 Success Metrics

- [ ] 50+ new query methods implemented
- [ ] 90%+ test coverage
- [ ] Zero SQL injection vulnerabilities
- [ ] 10x+ performance improvement for bulk operations
- [ ] Positive developer feedback
- [ ] Complete API documentation
- [ ] Migration guide published
