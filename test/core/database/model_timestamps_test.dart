import 'package:khadem/src/core/database/model_base/khadem_model.dart';
import 'package:khadem/src/core/database/orm/traits/timestamps.dart';
import 'package:test/test.dart';

// Test model with timestamps
class TestUser extends KhademModel<TestUser> with Timestamps<TestUser> {
  @override
  int? id;
  String? name;
  String? email;
  @override
  DateTime? createdAt;
  @override
  DateTime? updatedAt;

  @override
  TestUser newFactory(Map<String, dynamic> data) {
    return TestUser()..fromJson(data);
  }

  @override
  dynamic getField(String key) {
    switch (key) {
      case 'id':
        return id;
      case 'name':
        return name;
      case 'email':
        return email;
      case 'created_at':
        return createdAt;
      case 'updated_at':
        return updatedAt;
      default:
        return null;
    }
  }

  @override
  void setField(String key, dynamic value) {
    switch (key) {
      case 'id':
        id = value;
        break;
      case 'name':
        name = value;
        break;
      case 'email':
        email = value;
        break;
      case 'created_at':
        createdAt = value is DateTime
            ? value
            : (value is String ? DateTime.tryParse(value) : null);
        break;
      case 'updated_at':
        updatedAt = value is DateTime
            ? value
            : (value is String ? DateTime.tryParse(value) : null);
        break;
    }
  }

  @override
  List<String> get fillable => ['name', 'email', 'created_at', 'updated_at'];
}

// Test model with disabled timestamps
class TestSession extends KhademModel<TestSession>
    with Timestamps<TestSession> {
  @override
  int? id;
  String? token;

  @override
  bool get timestamps => false;

  @override
  TestSession newFactory(Map<String, dynamic> data) {
    return TestSession()..fromJson(data);
  }

  @override
  dynamic getField(String key) {
    switch (key) {
      case 'id':
        return id;
      case 'token':
        return token;
      default:
        return null;
    }
  }

  @override
  void setField(String key, dynamic value) {
    switch (key) {
      case 'id':
        id = value;
        break;
      case 'token':
        token = value;
        break;
    }
  }

  @override
  List<String> get fillable => ['token'];
}

// Test model with custom timestamp columns
class TestPost extends KhademModel<TestPost> with Timestamps<TestPost> {
  @override
  int? id;
  String? title;
  DateTime? publishedAt;
  DateTime? modifiedAt;

  @override
  String get createdAtColumn => 'published_at';

  @override
  String get updatedAtColumn => 'modified_at';

  @override
  TestPost newFactory(Map<String, dynamic> data) {
    return TestPost()..fromJson(data);
  }

  @override
  dynamic getField(String key) {
    switch (key) {
      case 'id':
        return id;
      case 'title':
        return title;
      case 'published_at':
        return publishedAt;
      case 'modified_at':
        return modifiedAt;
      default:
        return null;
    }
  }

  @override
  void setField(String key, dynamic value) {
    switch (key) {
      case 'id':
        id = value;
        break;
      case 'title':
        title = value;
        break;
      case 'published_at':
        publishedAt = value is DateTime
            ? value
            : (value is String ? DateTime.tryParse(value) : null);
        break;
      case 'modified_at':
        modifiedAt = value is DateTime
            ? value
            : (value is String ? DateTime.tryParse(value) : null);
        break;
    }
  }

  @override
  List<String> get fillable => ['title', 'published_at', 'modified_at'];
}

void main() {
  group('Timestamps', () {
    late TestUser user;

    setUp(() {
      user = TestUser()
        ..id = 1
        ..name = 'John'
        ..email = 'john@example.com';
    });

    test('model has Timestamps mixin', () {
      expect(user, isA<Timestamps<TestUser>>());
    });

    test('timestamps enabled by default', () {
      expect(user.timestamps, isTrue);
    });

    test('timestamps can be disabled', () {
      final session = TestSession();
      expect(session.timestamps, isFalse);
    });

    test('default column names', () {
      expect(user.createdAtColumn, equals('created_at'));
      expect(user.updatedAtColumn, equals('updated_at'));
    });

    test('custom column names work', () {
      final post = TestPost();
      expect(post.createdAtColumn, equals('published_at'));
      expect(post.updatedAtColumn, equals('modified_at'));
    });

    test('createdAt getter returns null by default', () {
      expect(user.createdAt, isNull);
    });

    test('updatedAt getter returns null by default', () {
      expect(user.updatedAt, isNull);
    });

    test('createdAt setter works', () {
      final now = DateTime.now();
      user.createdAt = now;
      expect(user.createdAt, equals(now));
    });

    test('updatedAt setter works', () {
      final now = DateTime.now();
      user.updatedAt = now;
      expect(user.updatedAt, equals(now));
    });

    test('timestamps handle DateTime values', () {
      final created = DateTime(2024);
      final updated = DateTime(2024, 1, 2);

      user.setField('created_at', created);
      user.setField('updated_at', updated);

      expect(user.createdAt, equals(created));
      expect(user.updatedAt, equals(updated));
    });

    test('timestamps handle String values', () {
      user.setField('created_at', '2024-01-01T12:00:00.000Z');
      user.setField('updated_at', '2024-01-02T12:00:00.000Z');

      expect(user.createdAt, isNotNull);
      expect(user.updatedAt, isNotNull);
      expect(user.createdAt, isA<DateTime>());
      expect(user.updatedAt, isA<DateTime>());
    });

    test('setTimestamps manually sets timestamps', () {
      final created = DateTime(2024);
      final updated = DateTime(2024, 1, 2);

      user.setTimestamps(createdAt: created, updatedAt: updated);

      expect(user.createdAt, equals(created));
      expect(user.updatedAt, equals(updated));
    });

    test('setTimestamps respects timestamps flag', () {
      final session = TestSession();
      final now = DateTime.now();

      session.setTimestamps(createdAt: now, updatedAt: now);

      // Should not set timestamps when disabled
      expect(session.createdAt, isNull);
      expect(session.updatedAt, isNull);
    });
  });

  group('Timestamp Helpers', () {
    test('age returns duration since creation', () {
      final user = TestUser()
        ..createdAt = DateTime.now().subtract(const Duration(days: 5));

      final age = user.age;

      expect(age, isNotNull);
      expect(age!.inDays, equals(5));
    });

    test('age returns null when createdAt is null', () {
      final user = TestUser();

      expect(user.age, isNull);
    });

    test('timeSinceUpdate returns duration since last update', () {
      final user = TestUser()
        ..updatedAt = DateTime.now().subtract(const Duration(hours: 2));

      final timeSinceUpdate = user.timeSinceUpdate;

      expect(timeSinceUpdate, isNotNull);
      expect(timeSinceUpdate!.inHours, equals(2));
    });

    test('timeSinceUpdate returns null when updatedAt is null', () {
      final user = TestUser();

      expect(user.timeSinceUpdate, isNull);
    });

    test('wasRecentlyCreated returns true for recent records', () {
      final user = TestUser()
        ..createdAt = DateTime.now().subtract(const Duration(minutes: 30));

      expect(user.wasRecentlyCreated(), isTrue);
    });

    test('wasRecentlyCreated returns false for old records', () {
      final user = TestUser()
        ..createdAt = DateTime.now().subtract(const Duration(hours: 2));

      expect(user.wasRecentlyCreated(), isFalse);
    });

    test('wasRecentlyCreated returns false when createdAt is null', () {
      final user = TestUser();

      expect(user.wasRecentlyCreated(), isFalse);
    });

    test('wasRecentlyUpdated returns true for recent updates', () {
      final user = TestUser()
        ..updatedAt = DateTime.now().subtract(const Duration(minutes: 15));

      expect(user.wasRecentlyUpdated(), isTrue);
    });

    test('wasRecentlyUpdated returns false for old updates', () {
      final user = TestUser()
        ..updatedAt = DateTime.now().subtract(const Duration(hours: 1));

      expect(user.wasRecentlyUpdated(), isFalse);
    });

    test('wasRecentlyUpdated returns false when updatedAt is null', () {
      final user = TestUser();

      expect(user.wasRecentlyUpdated(), isFalse);
    });
  });

  group('Custom Columns', () {
    test('works with custom column names', () {
      final post = TestPost()
        ..id = 1
        ..title = 'Test Post';

      final published = DateTime(2024);
      final modified = DateTime(2024, 1, 2);

      post.publishedAt = published;
      post.modifiedAt = modified;

      // Access through the mixin
      expect(post.createdAt, equals(published));
      expect(post.updatedAt, equals(modified));
    });

    test('setTimestamps works with custom columns', () {
      final post = TestPost();

      final published = DateTime(2024);
      final modified = DateTime(2024, 1, 2);

      post.setTimestamps(createdAt: published, updatedAt: modified);

      expect(post.publishedAt, equals(published));
      expect(post.modifiedAt, equals(modified));
    });
  });

  group('TimestampsExtension', () {
    test('timestampColumns returns column names when timestamps enabled', () {
      final user = TestUser();

      expect(user.timestampColumns, equals(['created_at', 'updated_at']));
    });

    test('timestampColumns returns empty list when timestamps disabled', () {
      final session = TestSession();

      expect(session.timestampColumns, isEmpty);
    });

    test('timestampColumns respects custom column names', () {
      final post = TestPost();

      expect(post.timestampColumns, equals(['published_at', 'modified_at']));
    });
  });
}
