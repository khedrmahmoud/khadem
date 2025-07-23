import 'package:recase/recase.dart';

mixin HasSlug {
  String? slug;

  /// Auto-generate slug from a specific string (e.g. title or name)
  void generateSlug(String source) {
    slug = source.trim().toLowerCase().paramCase;
  }

  bool get hasSlug => slug != null && slug!.isNotEmpty;
}
