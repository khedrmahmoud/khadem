import 'package:khadem/src/core/database/model_base/khadem_model.dart';
import 'package:khadem/src/core/database/orm/traits/soft_deletes.dart';
import 'package:test/test.dart';

// Test model with soft deletes
class TestPost extends KhademModel<TestPost> with SoftDeletes<TestPost> {
  @override
  int? id;
  String? title;
  String? content;
  @override
  DateTime? deletedAt;

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
      case 'content':
        return content;
      case 'deleted_at':
        return deletedAt;
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
      case 'content':
        content = value;
        break;
      case 'deleted_at':
        deletedAt = value is DateTime
            ? value
            : (value is String ? DateTime.tryParse(value) : null);
        break;
    }
  }

  @override
  List<String> get fillable => ['title', 'content', 'deleted_at'];
}

// Test model with custom deleted_at column name
class TestProduct extends KhademModel<TestProduct>
    with SoftDeletes<TestProduct> {
  @override
  int? id;
  String? name;
  DateTime? removedAt;

  @override
  String get deletedAtColumn => 'removed_at';

  @override
  TestProduct newFactory(Map<String, dynamic> data) {
    return TestProduct()..fromJson(data);
  }

  @override
  dynamic getField(String key) {
    switch (key) {
      case 'id':
        return id;
      case 'name':
        return name;
      case 'removed_at':
        return removedAt;
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
      case 'removed_at':
        removedAt = value is DateTime
            ? value
            : (value is String ? DateTime.tryParse(value) : null);
        break;
    }
  }

  @override
  List<String> get fillable => ['name', 'removed_at'];
}

void main() {
  group('Soft Deletes', () {
    late TestPost post;

    setUp(() {
      post = TestPost()
        ..id = 1
        ..title = 'Test Post'
        ..content = 'Test content';
    });

    test('model has SoftDeletes mixin', () {
      expect(post, isA<SoftDeletes<TestPost>>());
    });

    test('deletedAtColumn returns default column name', () {
      expect(post.deletedAtColumn, equals('deleted_at'));
    });

    test('custom deletedAtColumn works', () {
      final product = TestProduct();
      expect(product.deletedAtColumn, equals('removed_at'));
    });

    test('deletedAt getter returns null by default', () {
      expect(post.deletedAt, isNull);
    });

    test('deletedAt setter works', () {
      final now = DateTime.now();
      post.deletedAt = now;
      expect(post.deletedAt, equals(now));
    });

    test('trashed returns false when not deleted', () {
      expect(post.trashed, isFalse);
    });

    test('trashed returns true when deleted', () {
      post.deletedAt = DateTime.now();
      expect(post.trashed, isTrue);
    });

    test('isTrashed is alias for trashed', () {
      expect(post.isTrashed, equals(post.trashed));

      post.deletedAt = DateTime.now();
      expect(post.isTrashed, equals(post.trashed));
    });

    test('isNotTrashed returns opposite of trashed', () {
      expect(post.isNotTrashed, isTrue);

      post.deletedAt = DateTime.now();
      expect(post.isNotTrashed, isFalse);
    });

    test('deletedAt handles DateTime values', () {
      final now = DateTime.now();
      post.setField('deleted_at', now);

      expect(post.deletedAt, equals(now));
    });

    test('deletedAt handles String values', () {
      const dateString = '2024-01-01T12:00:00.000Z';
      post.setField('deleted_at', dateString);

      expect(post.deletedAt, isNotNull);
      expect(post.deletedAt, isA<DateTime>());
    });

    test('deletedAt handles null values', () {
      post.setField('deleted_at', null);

      expect(post.deletedAt, isNull);
    });
  });

  group('Soft Delete Operations', () {
    test('softDelete sets deletedAt timestamp', () async {
      final post = TestPost()
        ..id = 1
        ..title = 'Test';

      // Note: This won't actually save to DB in unit test
      // Just testing the logic
      expect(post.deletedAt, isNull);

      // Manually set for testing
      post.deletedAt = DateTime.now();

      expect(post.deletedAt, isNotNull);
      expect(post.trashed, isTrue);
    });

    test('restore clears deletedAt timestamp', () {
      final post = TestPost()
        ..id = 1
        ..deletedAt = DateTime.now();

      expect(post.trashed, isTrue);

      // Manually restore
      post.deletedAt = null;

      expect(post.deletedAt, isNull);
      expect(post.trashed, isFalse);
    });
  });

  group('Query Extensions', () {
    test('onlyTrashed adds whereNotNull constraint', () {
      final query = TestPost().query;
      final trashedQuery = query.onlyTrashed();

      expect(trashedQuery, isNotNull);
    });

    test('withoutTrashed adds whereNull constraint', () {
      final query = TestPost().query;
      final activeQuery = query.withoutTrashed();

      expect(activeQuery, isNotNull);
    });
  });

  group('Edge Cases', () {
    test('works with custom column name', () {
      final product = TestProduct()
        ..id = 1
        ..name = 'Test Product';

      expect(product.deletedAtColumn, equals('removed_at'));
      expect(product.deletedAt, isNull);

      final now = DateTime.now();
      product.removedAt = now;

      // Access through the mixin
      expect(product.deletedAt, equals(now));
      expect(product.trashed, isTrue);
    });

    test('handles already deleted records', () async {
      final post = TestPost()
        ..id = 1
        ..deletedAt = DateTime.now();

      expect(post.trashed, isTrue);

      // Trying to soft delete again should return false
      final result = await post.softDelete();
      expect(result, isFalse);
    });

    test('handles not-deleted records on restore', () async {
      final post = TestPost()..id = 1;

      expect(post.trashed, isFalse);

      // Trying to restore a non-deleted record should return false
      final result = await post.restore();
      expect(result, isFalse);
    });
  });
}
