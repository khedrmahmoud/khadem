import '../../contracts/validation/rule.dart';

class ArrayRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'array_validation';
    }

    if (value is! List) {
      return 'array_validation';
    }

    return null;
  }
}

class DistinctRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'distinct_validation';
    }

    if (value is! List) {
      return 'distinct_validation';
    }

    final seen = <dynamic>{};
    for (final item in value) {
      if (seen.contains(item)) {
        return 'distinct_validation';
      }
      seen.add(item);
    }

    return null;
  }
}

class MinItemsRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null || arg == null) {
      return 'min_items_validation';
    }

    if (value is! List) {
      return 'min_items_validation';
    }

    final minCount = int.tryParse(arg);
    if (minCount == null) {
      return 'min_items_validation';
    }

    if (value.length < minCount) {
      return 'min_items_validation';
    }

    return null;
  }
}

class MaxItemsRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null || arg == null) {
      return 'max_items_validation';
    }

    if (value is! List) {
      return 'max_items_validation';
    }

    final maxCount = int.tryParse(arg);
    if (maxCount == null) {
      return 'max_items_validation';
    }

    if (value.length > maxCount) {
      return 'max_items_validation';
    }

    return null;
  }
}

class InArrayRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null || arg == null) {
      return 'in_array_validation';
    }

    if (!data.containsKey(arg)) {
      return 'in_array_validation';
    }

    final arrayField = data[arg];
    if (arrayField is! List) {
      return 'in_array_validation';
    }

    if (!arrayField.contains(value)) {
      return 'in_array_validation';
    }

    return null;
  }
}

class NotInArrayRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null || arg == null) {
      return 'not_in_array_validation';
    }

    if (!data.containsKey(arg)) {
      return 'not_in_array_validation';
    }

    final arrayField = data[arg];
    if (arrayField is! List) {
      return 'not_in_array_validation';
    }

    if (arrayField.contains(value)) {
      return 'not_in_array_validation';
    }

    return null;
  }
}
