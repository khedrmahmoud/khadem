# Model Observers Guide

**Date:** October 9, 2025  
**Phase:** 3 - Advanced Features  
**Status:** Complete

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Creating Observers](#creating-observers)
3. [Registering Observers](#registering-observers)
4. [Available Event Hooks](#available-event-hooks)
5. [Cancelling Operations](#cancelling-operations)
6. [Real-World Examples](#real-world-examples)
7. [Best Practices](#best-practices)

---

## Overview

Model Observers provide a clean, organized way to handle model lifecycle events outside of the model class itself. They allow you to separate concerns and keep your models focused on data structure while moving business logic to dedicated observer classes.

### Key Features

- ✅ **Separation of Concerns** - Keep event logic out of models
- ✅ **Reusable Logic** - Share observers across models
- ✅ **Cancellable Operations** - Prevent deletes, restores, etc.
- ✅ **Clean Code** - More maintainable than event listeners
- ✅ **Type-Safe** - Strongly typed with generics
- ✅ **Multiple Observers** - Register multiple observers per model

---

## Creating Observers

Create an observer by extending `ModelObserver<T>`:

```dart
import 'package:khadem/khadem.dart';

class UserObserver extends ModelObserver<User> {
  @override
  void creating(User user) {
    // Called before a new user is inserted
    print('Creating user: ${user.email}');
    
    // Set default values
    user.uuid = Uuid().v4();
    user.status = 'pending';
  }

  @override
  void created(User user) {
    // Called after user is inserted
    print('User created with ID: ${user.id}');
    
    // Send welcome email
    sendWelcomeEmail(user);
  }

  @override
  void updating(User user) {
    // Called before user is updated
    print('Updating user: ${user.id}');
    
    // Track changes
    logUserChanges(user);
  }

  @override
  void updated(User user) {
    // Called after user is updated
    print('User updated: ${user.id}');
    
    // Clear cache
    clearUserCache(user.id);
  }

  @override
  bool deleting(User user) {
    // Called before user is deleted
    print('Deleting user: ${user.id}');
    
    // Prevent deletion if user has posts
    if (user.postsCount > 0) {
      print('Cannot delete user with posts');
      return false; // Cancel deletion
    }
    
    return true; // Allow deletion
  }

  @override
  void deleted(User user) {
    // Called after user is deleted
    print('User deleted: ${user.id}');
    
    // Clean up related data
    cleanupUserData(user.id);
  }
}
```

---

## Registering Observers

Register observers in your application bootstrap code:

```dart
void main() async {
  // Initialize Khadem
  await Khadem.init();

  // Register observers
  User.observe(UserObserver());
  Post.observe(PostObserver());
  Order.observe(OrderObserver());
  
  // Start application
  await Khadem.start();
}
```

### Multiple Observers

You can register multiple observers for the same model:

```dart
void main() async {
  await Khadem.init();

  // Register multiple observers for User model
  User.observe(UserAuditObserver());
  User.observe(UserNotificationObserver());
  User.observe(UserCacheObserver());
  
  await Khadem.start();
}
```

**Execution Order:** Observers are called in the order they were registered.

---

## Available Event Hooks

### Creation Events

#### `creating(T model)`
Called before a new record is inserted into the database.

**Use Cases:**
- Set UUIDs or default values
- Validate data before insertion
- Generate slugs or unique identifiers

```dart
@override
void creating(User user) {
  user.uuid = Uuid().v4();
  user.slug = generateSlug(user.name);
  user.createdBy = getCurrentUserId();
}
```

#### `created(T model)`
Called after a new record has been inserted.

**Use Cases:**
- Send welcome emails
- Create related records
- Log creation events
- Update caches

```dart
@override
void created(User user) {
  sendWelcomeEmail(user);
  createUserProfile(user);
  logEvent('user_created', user.id);
}
```

---

### Update Events

#### `updating(T model)`
Called before a record is updated.

**Use Cases:**
- Log changes
- Validate updates
- Track who modified the record

```dart
@override
void updating(User user) {
  user.updatedBy = getCurrentUserId();
  user.version++;
  logChanges(user);
}
```

#### `updated(T model)`
Called after a record has been updated.

**Use Cases:**
- Clear caches
- Send notifications
- Update search indexes
- Sync with external systems

```dart
@override
void updated(User user) {
  clearCache('user:${user.id}');
  updateSearchIndex(user);
  syncToExternalSystem(user);
}
```

---

### Save Events

#### `saving(T model)`
Called before both creates and updates.

**Use Cases:**
- Common logic for both creates and updates
- Data normalization
- Input sanitization

```dart
@override
void saving(User user) {
  // Normalize email
  user.email = user.email.toLowerCase().trim();
  
  // Sanitize inputs
  user.name = sanitize(user.name);
}
```

#### `saved(T model)`
Called after both creates and updates.

**Use Cases:**
- Common post-save logic
- Cache invalidation
- Event broadcasting

```dart
@override
void saved(User user) {
  clearAllUserCaches(user.id);
  broadcastUserUpdated(user);
}
```

---

### Deletion Events

#### `bool deleting(T model)`
Called before a record is deleted. **Can cancel the deletion.**

**Use Cases:**
- Prevent deletion based on conditions
- Confirm user intentions
- Check for related data

```dart
@override
bool deleting(User user) {
  // Prevent deletion if user has orders
  if (user.ordersCount > 0) {
    throw Exception('Cannot delete user with orders');
    return false;
  }
  
  // Prevent deletion of admin users
  if (user.isAdmin) {
    return false;
  }
  
  return true; // Allow deletion
}
```

#### `deleted(T model)`
Called after a record has been deleted.

**Use Cases:**
- Clean up related data
- Remove from caches
- Archive user data
- Send notifications

```dart
@override
void deleted(User user) {
  deleteUserFiles(user.id);
  removeFromCache(user.id);
  archiveUserData(user);
  notifyAdmins('User ${user.email} was deleted');
}
```

---

### Soft Delete Events (SoftDeletes Mixin)

#### `bool restoring(T model)`
Called before a soft-deleted record is restored. **Can cancel the restoration.**

```dart
@override
bool restoring(User user) {
  // Check if user can be restored
  if (!canRestoreUser(user.id)) {
    return false;
  }
  
  return true;
}
```

#### `restored(T model)`
Called after a soft-deleted record has been restored.

```dart
@override
void restored(User user) {
  sendAccountRestoredEmail(user);
  logEvent('user_restored', user.id);
}
```

#### `bool forceDeleting(T model)`
Called before a record is permanently deleted (with soft deletes). **Can cancel the force deletion.**

```dart
@override
bool forceDeleting(User user) {
  // Require admin approval for force deletion
  if (!isAdmin()) {
    return false;
  }
  
  return true;
}
```

#### `forceDeleted(T model)`
Called after a record has been permanently deleted.

```dart
@override
void forceDeleted(User user) {
  permanentlyDeleteUserFiles(user.id);
  removeAllTraces(user.id);
}
```

---

### Retrieval Events

#### `retrieved(T model)`
Called after a record has been retrieved from the database.

**Use Cases:**
- Decrypt sensitive data
- Load additional data
- Track access

```dart
@override
void retrieved(User user) {
  // Decrypt sensitive fields
  if (user.ssn != null) {
    user.ssn = decrypt(user.ssn);
  }
  
  // Track last accessed
  trackUserAccess(user.id);
}
```

---

## Cancelling Operations

Some observer methods can cancel operations by returning `false`:

| Method | Can Cancel | Return Type |
|--------|------------|-------------|
| `deleting()` | ✅ Yes | `bool` |
| `restoring()` | ✅ Yes | `bool` |
| `forceDeleting()` | ✅ Yes | `bool` |
| All others | ❌ No | `void` |

### Example: Prevent Deletion

```dart
class PostObserver extends ModelObserver<Post> {
  @override
  bool deleting(Post post) {
    // Prevent deletion if post is published
    if (post.isPublished) {
      print('Cannot delete published post');
      return false; // Cancel deletion
    }
    
    // Prevent deletion if post has comments
    if (post.commentsCount > 0) {
      print('Cannot delete post with comments');
      return false; // Cancel deletion
    }
    
    return true; // Allow deletion
  }
}

// Usage
final post = await Post.query().findById(1);
await post.delete(); // Will not delete if post is published or has comments
```

---

## Real-World Examples

### Example 1: User Management System

```dart
class UserObserver extends ModelObserver<User> {
  @override
  void creating(User user) {
    // Generate UUID
    user.uuid = Uuid().v4();
    
    // Set default role
    user.role = 'user';
    
    // Set created by
    user.createdBy = getCurrentUserId();
    
    // Generate API key
    user.apiKey = generateApiKey();
  }

  @override
  void created(User user) {
    // Send welcome email
    EmailService.send(
      to: user.email,
      template: 'welcome',
      data: {'name': user.name},
    );
    
    // Create user profile
    UserProfile.create({
      'user_id': user.id,
      'bio': '',
      'avatar': 'default.png',
    });
    
    // Log creation
    AuditLog.create({
      'action': 'user.created',
      'user_id': user.id,
      'performed_by': getCurrentUserId(),
    });
  }

  @override
  void updating(User user) {
    // Track who updated
    user.updatedBy = getCurrentUserId();
    
    // Log changes for audit
    AuditLog.create({
      'action': 'user.updated',
      'user_id': user.id,
      'changes': user.getChanges(),
      'performed_by': getCurrentUserId(),
    });
  }

  @override
  void updated(User user) {
    // Clear user cache
    Cache.forget('user:${user.id}');
    Cache.forget('user:email:${user.email}');
    
    // Update search index
    SearchService.updateIndex('users', user.toSearchDocument());
    
    // Notify about profile change
    if (user.wasChanged('email')) {
      EmailService.send(
        to: user.email,
        template: 'email_changed',
        data: {'name': user.name},
      );
    }
  }

  @override
  bool deleting(User user) {
    // Prevent deletion of admin users
    if (user.isAdmin) {
      throw UnauthorizedException('Cannot delete admin users');
    }
    
    // Prevent deletion if user has active orders
    if (user.activeOrdersCount > 0) {
      throw ValidationException('User has active orders');
    }
    
    return true;
  }

  @override
  void deleted(User user) {
    // Delete user files
    StorageService.deleteDirectory('users/${user.id}');
    
    // Remove from all caches
    Cache.forget('user:${user.id}');
    Cache.forget('user:email:${user.email}');
    
    // Remove from search index
    SearchService.removeFromIndex('users', user.id);
    
    // Archive user data for GDPR compliance
    ArchiveService.archiveUser(user);
    
    // Notify admins
    NotificationService.notifyAdmins(
      'User deleted: ${user.email}',
    );
  }
}
```

---

### Example 2: E-Commerce Order System

```dart
class OrderObserver extends ModelObserver<Order> {
  @override
  void creating(Order order) {
    // Generate order number
    order.orderNumber = generateOrderNumber();
    
    // Set initial status
    order.status = 'pending';
    
    // Calculate totals
    order.calculateTotals();
  }

  @override
  void created(Order order) {
    // Send order confirmation email
    EmailService.send(
      to: order.customer.email,
      template: 'order_confirmation',
      data: {'order': order},
    );
    
    // Create invoice
    Invoice.create({
      'order_id': order.id,
      'amount': order.total,
      'due_date': DateTime.now().add(Duration(days: 30)),
    });
    
    // Notify warehouse
    WarehouseService.notifyNewOrder(order);
    
    // Update inventory
    InventoryService.reserveItems(order.items);
  }

  @override
  void updating(Order order) {
    // Log status changes
    if (order.wasChanged('status')) {
      OrderStatusHistory.create({
        'order_id': order.id,
        'old_status': order.getOriginal('status'),
        'new_status': order.status,
        'changed_by': getCurrentUserId(),
      });
    }
  }

  @override
  void updated(Order order) {
    // Send status update email
    if (order.wasChanged('status')) {
      EmailService.send(
        to: order.customer.email,
        template: 'order_status_update',
        data: {
          'order': order,
          'status': order.status,
        },
      );
    }
    
    // Update analytics
    AnalyticsService.trackOrderUpdate(order);
  }

  @override
  bool deleting(Order order) {
    // Prevent deletion of completed orders
    if (order.status == 'completed') {
      throw ValidationException('Cannot delete completed orders');
    }
    
    // Prevent deletion of paid orders
    if (order.isPaid) {
      throw ValidationException('Cannot delete paid orders');
    }
    
    return true;
  }

  @override
  void deleted(Order order) {
    // Release inventory
    InventoryService.releaseItems(order.items);
    
    // Cancel invoice
    order.invoice?.cancel();
    
    // Refund if necessary
    if (order.isPaid) {
      PaymentService.refund(order);
    }
    
    // Notify customer
    EmailService.send(
      to: order.customer.email,
      template: 'order_cancelled',
      data: {'order': order},
    );
  }
}
```

---

### Example 3: Blog Post System

```dart
class PostObserver extends ModelObserver<Post> {
  @override
  void creating(Post post) {
    // Generate slug
    post.slug = generateSlug(post.title);
    
    // Set author
    post.authorId = getCurrentUserId();
    
    // Set default status
    post.status = 'draft';
  }

  @override
  void created(Post post) {
    // Create initial revision
    PostRevision.create({
      'post_id': post.id,
      'content': post.content,
      'version': 1,
    });
    
    // Log creation
    logActivity('post.created', post.id);
  }

  @override
  void updating(Post post) {
    // Create revision on update
    if (post.wasChanged('content')) {
      PostRevision.create({
        'post_id': post.id,
        'content': post.content,
        'version': post.version + 1,
      });
      
      post.version++;
    }
  }

  @override
  void updated(Post post) {
    // Publish notifications
    if (post.wasChanged('status') && post.status == 'published') {
      // Notify subscribers
      notifySubscribers(post);
      
      // Update sitemap
      SitemapService.update();
      
      // Submit to search engines
      SearchEngineService.ping(post.url);
    }
    
    // Clear cache
    Cache.forget('post:${post.slug}');
  }

  @override
  bool deleting(Post post) {
    // Prevent deletion of published posts
    if (post.status == 'published') {
      return false;
    }
    
    return true;
  }

  @override
  void deleted(Post post) {
    // Delete associated media
    post.media.each((media) => media.delete());
    
    // Delete comments
    post.comments.each((comment) => comment.delete());
    
    // Remove from cache
    Cache.forget('post:${post.slug}');
  }
}
```

---

## Best Practices

### 1. Keep Observers Focused

**❌ Bad:** One observer doing everything
```dart
class UserObserver extends ModelObserver<User> {
  @override
  void created(User user) {
    sendEmail(user);
    clearCache(user);
    updateAnalytics(user);
    syncToExternal(user);
    createProfile(user);
    logEvent(user);
    // Too many responsibilities!
  }
}
```

**✅ Good:** Multiple focused observers
```dart
class UserEmailObserver extends ModelObserver<User> {
  @override
  void created(User user) => sendWelcomeEmail(user);
}

class UserCacheObserver extends ModelObserver<User> {
  @override
  void updated(User user) => clearUserCache(user);
}

class UserAnalyticsObserver extends ModelObserver<User> {
  @override
  void created(User user) => trackUserCreated(user);
}
```

---

### 2. Handle Errors Gracefully

```dart
class UserObserver extends ModelObserver<User> {
  @override
  void created(User user) {
    try {
      sendWelcomeEmail(user);
    } catch (e) {
      // Log error but don't break the application
      logger.error('Failed to send welcome email', e);
      // Optionally queue for retry
      EmailQueue.add(user.email, 'welcome');
    }
  }
}
```

---

### 3. Use Dependency Injection

```dart
class UserObserver extends ModelObserver<User> {
  final EmailService emailService;
  final CacheService cacheService;
  
  UserObserver({
    required this.emailService,
    required this.cacheService,
  });

  @override
  void created(User user) {
    emailService.send(user.email, 'welcome');
    cacheService.put('user:${user.id}', user);
  }
}

// Register with dependencies
User.observe(UserObserver(
  emailService: EmailService(),
  cacheService: CacheService(),
));
```

---

### 4. Testing Observers

```dart
void main() {
  group('UserObserver', () {
    late UserObserver observer;
    late MockEmailService emailService;

    setUp(() {
      emailService = MockEmailService();
      observer = UserObserver(emailService: emailService);
    });

    test('sends welcome email on user creation', () {
      final user = User()
        ..id = 1
        ..email = 'test@example.com'
        ..name = 'Test User';

      observer.created(user);

      verify(emailService.send('test@example.com', 'welcome')).called(1);
    });

    test('prevents deletion of admin users', () {
      final admin = User()..isAdmin = true;

      expect(observer.deleting(admin), isFalse);
    });
  });
}
```

---

### 5. Document Observer Behavior

```dart
/// Observer for User model lifecycle events
///
/// Handles:
/// - UUID generation on creation
/// - Welcome email sending
/// - Cache invalidation on updates
/// - Preventing deletion of admin users
/// - Archiving user data on deletion
class UserObserver extends ModelObserver<User> {
  // Implementation...
}
```

---

## Summary

✅ **Clean separation** of event logic from models  
✅ **Type-safe** with generics (`ModelObserver<T>`)  
✅ **12 lifecycle hooks** (creating, created, updating, updated, saving, saved, deleting, deleted, restoring, restored, forceDeleting, forceDeleted)  
✅ **Cancellable operations** (deleting, restoring, forceDeleting)  
✅ **Multiple observers** per model  
✅ **Fully tested** and production-ready  

**Phase 3 Complete!** 🎉

Next: Write tests for Phase 3 features
