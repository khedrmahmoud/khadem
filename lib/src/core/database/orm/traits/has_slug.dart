import 'package:recase/recase.dart';

/// Mixin that adds slug generation support to models
/// 
/// Automatically generates URL-friendly slugs from text.
/// Common use case: generating slugs from titles for blog posts, products, etc.
/// 
/// Example:
/// ```dart
/// class Post extends KhademModel<Post> with HasSlug {
///   String? title;
///   
///   @override
///   String get slugSource => title ?? '';
/// }
/// 
/// // With observer for auto-generation:
/// class PostObserver extends ModelObserver<Post> {
///   @override
///   void creating(Post post) {
///     post.ensureSlugGenerated();
///   }
/// }
/// 
/// // Manual generation:
/// final post = Post()..title = 'Hello World!';
/// post.generateSlug();
/// print(post.slug); // "hello-world"
/// 
/// // Custom source:
/// post.generateSlugFrom('Custom Title 123');
/// print(post.slug); // "custom-title-123"
/// ```
mixin HasSlug {
  /// The generated slug value
  String? slug;

  /// Override this to specify the source field for slug generation
  /// 
  /// Example:
  /// ```dart
  /// @override
  /// String get slugSource => title ?? name ?? '';
  /// ```
  String get slugSource => '';

  /// Auto-generate slug from the slugSource
  /// 
  /// Generates a URL-friendly slug using param-case (kebab-case).
  /// Only generates if slug is not already set.
  void generateSlug() {
    if (slugSource.isNotEmpty) {
      slug = _slugify(slugSource);
    }
  }

  /// Generate slug from a specific string
  /// 
  /// Useful when you want to generate from a different source
  /// than the default slugSource.
  void generateSlugFrom(String source) {
    slug = _slugify(source);
  }

  /// Ensure slug is generated (doesn't overwrite existing)
  /// 
  /// Useful in observers to auto-generate slugs on creation.
  void ensureSlugGenerated() {
    if (!hasSlug && slugSource.isNotEmpty) {
      generateSlug();
    }
  }

  /// Force regenerate slug from current source
  /// 
  /// Overwrites existing slug with a new one from slugSource.
  void regenerateSlug() {
    slug = null;
    generateSlug();
  }

  /// Check if slug has been generated
  bool get hasSlug => slug != null && slug!.isNotEmpty;

  /// Internal method to convert string to slug format
  String _slugify(String source) {
    return source
        .trim()
        .toLowerCase()
        .paramCase // Converts to kebab-case
        .replaceAll(RegExp(r'[^\w\-]'), '') // Remove special chars
        .replaceAll(RegExp(r'\-+'), '-') // Replace multiple dashes
        .replaceAll(RegExp(r'^\-|\-$'), ''); // Remove leading/trailing dashes
  }

  /// Get slug with optional suffix for uniqueness
  /// 
  /// Example:
  /// ```dart
  /// final slug = post.getSlugWithSuffix(2);
  /// print(slug); // "my-post-2"
  /// ```
  String getSlugWithSuffix(int suffix) {
    ensureSlugGenerated();
    return '$slug-$suffix';
  }
}
