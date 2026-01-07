import 'dart:async';
import '../../contracts/validation/rule.dart';

/// Validates that the field under validation is a [List].
class ArrayRule extends Rule {
  @override
  String get signature => 'array';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    if (context.value == null) return false;
    return context.value is List;
  }

  @override
  String message(ValidationContext context) => 'array_validation';
}

/// Validates that the field under validation is a [List].
/// Alias for [ArrayRule].
class ListRule extends ArrayRule {
  @override
  String get signature => 'list';
}

/// Validates that the field under validation is a [Map].
class MapRule extends Rule {
  @override
  String get signature => 'map';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    if (context.value == null) return false;
    return context.value is Map;
  }

  @override
  String message(ValidationContext context) => 'map_validation';
}

/// Validates that the array under validation has distinct (unique) values.
///
/// Duplicate values are considered a failure.
class DistinctRule extends Rule {
  @override
  String get signature => 'distinct';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null || value is! List) return false;

    final seen = <dynamic>{};
    for (final item in value) {
      if (seen.contains(item)) return false;
      seen.add(item);
    }
    return true;
  }

  @override
  String message(ValidationContext context) => 'distinct_validation';
}

/// Validates that the array has at least [minCount] items.
class MinItemsRule extends Rule {
  @override
  String get signature => 'min_items';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;
    if (value == null || args.isEmpty) return false;
    if (value is! List) return false;

    final minCount = int.tryParse(args[0]);
    if (minCount == null) return false;

    return value.length >= minCount;
  }

  @override
  String message(ValidationContext context) => 'min_items_validation';
}

/// Validates that the array has at most [maxCount] items.
class MaxItemsRule extends Rule {
  @override
  String get signature => 'max_items';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;
    if (value == null || args.isEmpty) return false;
    if (value is! List) return false;

    final maxCount = int.tryParse(args[0]);
    if (maxCount == null) return false;

    return value.length <= maxCount;
  }

  @override
  String message(ValidationContext context) => 'max_items_validation';
}

/// Validates that the field's value exists in another field's array.
class InArrayRule extends Rule {
  @override
  String get signature => 'in_array';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;
    final data = context.data;

    if (value == null || args.isEmpty) return false;
    if (!data.containsKey(args[0])) return false;

    final arrayField = data[args[0]];
    if (arrayField is! List) return false;

    return arrayField.contains(value);
  }

  @override
  String message(ValidationContext context) => 'in_array_validation';
}

/// Validates that the field's value does not exist in another field's array.
class NotInArrayRule extends Rule {
  @override
  String get signature => 'not_in_array';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;
    final data = context.data;

    if (value == null || args.isEmpty) return false;
    if (!data.containsKey(args[0])) return false;

    final arrayField = data[args[0]];
    if (arrayField is! List) return false;

    return !arrayField.contains(value);
  }

  @override
  String message(ValidationContext context) => 'not_in_array_validation';
}

/// Validates that all items in the array field are present in the given allowed list.
class SubsetRule extends Rule {
  @override
  String get signature => 'subset';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    final args = context.parameters;

    if (value == null || args.isEmpty) return false;
    if (value is! List) return false;

    final allowed = args.toSet();
    // Check if every item in value is in allowed
    return value.every((item) => allowed.contains(item.toString()));
  }

  @override
  String message(ValidationContext context) => 'subset_validation';
}
