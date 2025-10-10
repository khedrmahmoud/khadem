import 'package:test/test.dart';
import 'package:khadem/src/core/database/orm/observers/model_observer.dart';
import 'package:khadem/src/core/database/orm/observers/observer_registry.dart';
import 'package:khadem/src/core/database/model_base/khadem_model.dart';

// Test models
class TestUser extends KhademModel<TestUser> {
  String? name;
  String? email;
  String? status;
  bool isAdmin = false;
  int postsCount = 0;

  @override
  TestUser newFactory(Map<String, dynamic> data) {
    return TestUser().fromJson(data);
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'status': status,
        'is_admin': isAdmin,
      };

  @override
  TestUser fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    status = json['status'];
    isAdmin = json['is_admin'] ?? false;
    postsCount = json['posts_count'] ?? 0;
    return this;
  }
}

class TestPost extends KhademModel<TestPost> {
  String? title;
  String? status;
  int commentsCount = 0;

  @override
  TestPost newFactory(Map<String, dynamic> data) {
    return TestPost().fromJson(data);
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
      };

  @override
  TestPost fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    status = json['status'];
    commentsCount = json['comments_count'] ?? 0;
    return this;
  }
}

// Test observers
class TestUserObserver extends ModelObserver<TestUser> {
  final List<String> events = [];

  @override
  void creating(TestUser user) {
    events.add('creating');
    user.status = 'pending';
  }

  @override
  void created(TestUser user) {
    events.add('created');
  }

  @override
  void updating(TestUser user) {
    events.add('updating');
  }

  @override
  void updated(TestUser user) {
    events.add('updated');
  }

  @override
  void saving(TestUser user) {
    events.add('saving');
  }

  @override
  void saved(TestUser user) {
    events.add('saved');
  }

  @override
  bool deleting(TestUser user) {
    events.add('deleting');
    // Prevent deletion if user has posts
    if (user.postsCount > 0) {
      return false;
    }
    // Prevent deletion of admin users
    if (user.isAdmin) {
      return false;
    }
    return true;
  }

  @override
  void deleted(TestUser user) {
    events.add('deleted');
  }

  @override
  void retrieving(TestUser user) {
    events.add('retrieving');
  }

  @override
  void retrieved(TestUser user) {
    events.add('retrieved');
  }

  @override
  bool restoring(TestUser user) {
    events.add('restoring');
    // Allow restoration
    return true;
  }

  @override
  void restored(TestUser user) {
    events.add('restored');
  }

  @override
  bool forceDeleting(TestUser user) {
    events.add('forceDeleting');
    // Prevent force deletion of admins
    if (user.isAdmin) {
      return false;
    }
    return true;
  }

  @override
  void forceDeleted(TestUser user) {
    events.add('forceDeleted');
  }
}

class SecondUserObserver extends ModelObserver<TestUser> {
  final List<String> events = [];

  @override
  void created(TestUser user) {
    events.add('second_created');
  }

  @override
  void updated(TestUser user) {
    events.add('second_updated');
  }
}

class TestPostObserver extends ModelObserver<TestPost> {
  final List<String> events = [];

  @override
  bool deleting(TestPost post) {
    events.add('deleting');
    // Prevent deletion if post has comments
    if (post.commentsCount > 0) {
      return false;
    }
    return true;
  }

  @override
  void deleted(TestPost post) {
    events.add('deleted');
  }
}

void main() {
  late ObserverRegistry registry;

  setUp(() {
    registry = ObserverRegistry.instance;
    registry.clearAll();
  });

  tearDown(() {
    registry.clearAll();
  });

  group('ObserverRegistry', () {
    test('singleton instance is the same', () {
      final instance1 = ObserverRegistry.instance;
      final instance2 = ObserverRegistry.instance;

      expect(instance1, same(instance2));
    });

    test('registers observer for model type', () {
      final observer = TestUserObserver();

      registry.register(observer);

      expect(registry.hasObservers<TestUser>(), isTrue);
      expect(registry.getObservers<TestUser>(), contains(observer));
    });

    test('registers multiple observers for same model type', () {
      final observer1 = TestUserObserver();
      final observer2 = SecondUserObserver();

      registry.register(observer1);
      registry.register(observer2);

      final observers = registry.getObservers<TestUser>();
      expect(observers.length, equals(2));
      expect(observers, contains(observer1));
      expect(observers, contains(observer2));
    });

    test('registers observers for different model types', () {
      final userObserver = TestUserObserver();
      final postObserver = TestPostObserver();

      registry.register(userObserver);
      registry.register(postObserver);

      expect(registry.hasObservers<TestUser>(), isTrue);
      expect(registry.hasObservers<TestPost>(), isTrue);
      expect(registry.getObservers<TestUser>(), contains(userObserver));
      expect(registry.getObservers<TestPost>(), contains(postObserver));
    });

    test('returns empty list for unregistered model type', () {
      expect(registry.getObservers<TestUser>(), isEmpty);
      expect(registry.hasObservers<TestUser>(), isFalse);
    });

    test('gets observers by runtime type', () {
      final observer = TestUserObserver();
      registry.register(observer);

      final observers = registry.getObserversByType(TestUser);
      expect(observers, contains(observer));
    });

    test('clears observers for specific model type', () {
      final userObserver = TestUserObserver();
      final postObserver = TestPostObserver();

      registry.register(userObserver);
      registry.register(postObserver);

      registry.clear<TestUser>();

      expect(registry.hasObservers<TestUser>(), isFalse);
      expect(registry.hasObservers<TestPost>(), isTrue);
    });

    test('clears all observers', () {
      final userObserver = TestUserObserver();
      final postObserver = TestPostObserver();

      registry.register(userObserver);
      registry.register(postObserver);

      registry.clearAll();

      expect(registry.hasObservers<TestUser>(), isFalse);
      expect(registry.hasObservers<TestPost>(), isFalse);
    });
  });

  group('ModelObserver - Creating Events', () {
    test('calls creating hook', () {
      final observer = TestUserObserver();
      final user = TestUser()
        ..name = 'John Doe'
        ..email = 'john@example.com';

      observer.creating(user);

      expect(observer.events, contains('creating'));
      expect(user.status, equals('pending')); // Set by observer
    });

    test('calls created hook', () {
      final observer = TestUserObserver();
      final user = TestUser()
        ..id = 1
        ..name = 'John Doe';

      observer.created(user);

      expect(observer.events, contains('created'));
    });
  });

  group('ModelObserver - Updating Events', () {
    test('calls updating hook', () {
      final observer = TestUserObserver();
      final user = TestUser()
        ..id = 1
        ..name = 'John Doe';

      observer.updating(user);

      expect(observer.events, contains('updating'));
    });

    test('calls updated hook', () {
      final observer = TestUserObserver();
      final user = TestUser()
        ..id = 1
        ..name = 'John Doe';

      observer.updated(user);

      expect(observer.events, contains('updated'));
    });
  });

  group('ModelObserver - Saving Events', () {
    test('calls saving hook', () {
      final observer = TestUserObserver();
      final user = TestUser()..name = 'John Doe';

      observer.saving(user);

      expect(observer.events, contains('saving'));
    });

    test('calls saved hook', () {
      final observer = TestUserObserver();
      final user = TestUser()..name = 'John Doe';

      observer.saved(user);

      expect(observer.events, contains('saved'));
    });
  });

  group('ModelObserver - Deletion Events', () {
    test('calls deleting hook and allows deletion', () {
      final observer = TestUserObserver();
      final user = TestUser()
        ..id = 1
        ..name = 'John Doe';

      final result = observer.deleting(user);

      expect(observer.events, contains('deleting'));
      expect(result, isTrue);
    });

    test('calls deleting hook and prevents deletion if user has posts', () {
      final observer = TestUserObserver();
      final user = TestUser()
        ..id = 1
        ..name = 'John Doe'
        ..postsCount = 5;

      final result = observer.deleting(user);

      expect(observer.events, contains('deleting'));
      expect(result, isFalse); // Deletion prevented
    });

    test('calls deleting hook and prevents deletion of admin users', () {
      final observer = TestUserObserver();
      final user = TestUser()
        ..id = 1
        ..name = 'Admin User'
        ..isAdmin = true;

      final result = observer.deleting(user);

      expect(observer.events, contains('deleting'));
      expect(result, isFalse); // Deletion prevented
    });

    test('calls deleted hook', () {
      final observer = TestUserObserver();
      final user = TestUser()..id = 1;

      observer.deleted(user);

      expect(observer.events, contains('deleted'));
    });
  });

  group('ModelObserver - Retrieval Events', () {
    test('calls retrieving hook', () {
      final observer = TestUserObserver();
      final user = TestUser()..id = 1;

      observer.retrieving(user);

      expect(observer.events, contains('retrieving'));
    });

    test('calls retrieved hook', () {
      final observer = TestUserObserver();
      final user = TestUser()..id = 1;

      observer.retrieved(user);

      expect(observer.events, contains('retrieved'));
    });
  });

  group('ModelObserver - Soft Delete Events', () {
    test('calls restoring hook and allows restoration', () {
      final observer = TestUserObserver();
      final user = TestUser()..id = 1;

      final result = observer.restoring(user);

      expect(observer.events, contains('restoring'));
      expect(result, isTrue);
    });

    test('calls restored hook', () {
      final observer = TestUserObserver();
      final user = TestUser()..id = 1;

      observer.restored(user);

      expect(observer.events, contains('restored'));
    });

    test('calls forceDeleting hook and allows force deletion', () {
      final observer = TestUserObserver();
      final user = TestUser()..id = 1;

      final result = observer.forceDeleting(user);

      expect(observer.events, contains('forceDeleting'));
      expect(result, isTrue);
    });

    test('calls forceDeleting hook and prevents force deletion of admins', () {
      final observer = TestUserObserver();
      final user = TestUser()
        ..id = 1
        ..isAdmin = true;

      final result = observer.forceDeleting(user);

      expect(observer.events, contains('forceDeleting'));
      expect(result, isFalse); // Force deletion prevented
    });

    test('calls forceDeleted hook', () {
      final observer = TestUserObserver();
      final user = TestUser()..id = 1;

      observer.forceDeleted(user);

      expect(observer.events, contains('forceDeleted'));
    });
  });

  group('Multiple Observers', () {
    test('calls multiple observers in order', () {
      final observer1 = TestUserObserver();
      final observer2 = SecondUserObserver();
      final user = TestUser()
        ..id = 1
        ..name = 'John Doe';

      registry.register(observer1);
      registry.register(observer2);

      // Simulate calling both observers
      observer1.created(user);
      observer2.created(user);

      expect(observer1.events, contains('created'));
      expect(observer2.events, contains('second_created'));
    });

    test('each observer maintains independent state', () {
      final observer1 = TestUserObserver();
      final observer2 = SecondUserObserver();
      final user = TestUser()
        ..id = 1
        ..name = 'John Doe';

      observer1.created(user);
      observer2.updated(user);

      expect(observer1.events, contains('created'));
      expect(observer1.events, isNot(contains('updated')));
      expect(observer2.events, contains('second_updated'));
      expect(observer2.events, isNot(contains('created')));
    });
  });

  group('Observer Cancellation', () {
    test('deleting can be cancelled by observer', () {
      final observer = TestPostObserver();
      final post = TestPost()
        ..id = 1
        ..title = 'Test Post'
        ..commentsCount = 10;

      final result = observer.deleting(post);

      expect(result, isFalse);
      expect(observer.events, contains('deleting'));
      expect(observer.events, isNot(contains('deleted')));
    });

    test('deleting proceeds when allowed', () {
      final observer = TestPostObserver();
      final post = TestPost()
        ..id = 1
        ..title = 'Test Post'
        ..commentsCount = 0; // No comments

      final result = observer.deleting(post);

      expect(result, isTrue);
      expect(observer.events, contains('deleting'));
    });
  });

  group('Observer Event Order', () {
    test('creating fires before created', () {
      final observer = TestUserObserver();
      final user = TestUser()..name = 'John Doe';

      observer.creating(user);
      observer.created(user);

      expect(observer.events.indexOf('creating'),
          lessThan(observer.events.indexOf('created')),);
    });

    test('updating fires before updated', () {
      final observer = TestUserObserver();
      final user = TestUser()
        ..id = 1
        ..name = 'John Doe';

      observer.updating(user);
      observer.updated(user);

      expect(observer.events.indexOf('updating'),
          lessThan(observer.events.indexOf('updated')),);
    });

    test('saving fires for both creates and updates', () {
      final observer = TestUserObserver();
      final user = TestUser()..name = 'John Doe';

      // Simulate save on create
      observer.saving(user);
      observer.creating(user);
      observer.created(user);
      observer.saved(user);

      expect(observer.events, contains('saving'));
      expect(observer.events, contains('saved'));

      observer.events.clear();

      // Simulate save on update
      user.id = 1;
      observer.saving(user);
      observer.updating(user);
      observer.updated(user);
      observer.saved(user);

      expect(observer.events, contains('saving'));
      expect(observer.events, contains('saved'));
    });

    test('deleting fires before deleted', () {
      final observer = TestUserObserver();
      final user = TestUser()..id = 1;

      observer.deleting(user);
      observer.deleted(user);

      expect(observer.events.indexOf('deleting'),
          lessThan(observer.events.indexOf('deleted')),);
    });
  });

  group('Observer Data Modification', () {
    test('observer can modify model in creating hook', () {
      final observer = TestUserObserver();
      final user = TestUser()
        ..name = 'John Doe'
        ..email = 'john@example.com';

      expect(user.status, isNull);

      observer.creating(user);

      expect(user.status, equals('pending')); // Modified by observer
    });

    test('multiple observers can modify model', () {
      final observer1 = TestUserObserver();
      final observer2 = SecondUserObserver();
      final user = TestUser()..name = 'John Doe';

      observer1.creating(user);
      expect(user.status, equals('pending'));

      // observer2 doesn't modify status, but could modify other fields
      observer2.created(user);

      expect(user.status, equals('pending')); // Still set by observer1
    });
  });
}
