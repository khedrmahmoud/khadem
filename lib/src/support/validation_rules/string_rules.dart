import '../../contracts/validation/rule.dart';

class StringRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'string_validation';
    }

    if (value is! String) {
      return 'string_validation';
    }

    return null;
  }
}

class AlphaRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'alpha_validation';
    }

    if (value is! String) {
      return 'alpha_validation';
    }

    final alphaRegex = RegExp(r'^[a-zA-Z]+$');
    if (!alphaRegex.hasMatch(value)) {
      return 'alpha_validation';
    }

    return null;
  }
}

class AlphaNumRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'alpha_num_validation';
    }

    if (value is! String) {
      return 'alpha_num_validation';
    }

    final alphaNumRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!alphaNumRegex.hasMatch(value)) {
      return 'alpha_num_validation';
    }

    return null;
  }
}

class AlphaDashRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'alpha_dash_validation';
    }

    if (value is! String) {
      return 'alpha_dash_validation';
    }

    final alphaDashRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!alphaDashRegex.hasMatch(value)) {
      return 'alpha_dash_validation';
    }

    return null;
  }
}

class StartsWithRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null || arg == null) {
      return 'starts_with_validation';
    }

    if (value is! String) {
      return 'starts_with_validation';
    }

    final prefixes = arg.split(',').map((e) => e.trim()).toList();
    final startsWithAny = prefixes.any((prefix) => value.startsWith(prefix));

    if (!startsWithAny) {
      return 'starts_with_validation';
    }

    return null;
  }
}

class EndsWithRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null || arg == null) {
      return 'ends_with_validation';
    }

    if (value is! String) {
      return 'ends_with_validation';
    }

    final suffixes = arg.split(',').map((e) => e.trim()).toList();
    final endsWithAny = suffixes.any((suffix) => value.endsWith(suffix));

    if (!endsWithAny) {
      return 'ends_with_validation';
    }

    return null;
  }
}
