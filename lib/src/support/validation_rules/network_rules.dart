import '../../contracts/validation/rule.dart';

class UrlRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'url_validation';
    }

    if (value is! String) {
      return 'url_validation';
    }

    final urlRegex = RegExp(
      r'^https?://' // protocol
      r'(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+' // domain
      r'[a-zA-Z]{2,}' // top-level domain
      r'(?::\d{1,5})?' // optional port
      r'(?:/?|[/?]\S+)$', // path
      caseSensitive: false,
    );

    if (!urlRegex.hasMatch(value)) {
      return 'url_validation';
    }

    return null;
  }
}

class ActiveUrlRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    // First check if it's a valid URL format
    final urlRule = UrlRule();
    if (urlRule.validate(field, value, arg, data: data) != null) {
      return 'active_url_validation';
    }

    // In a real implementation, this would make an HTTP request to check if the URL is active
    // For now, we'll just return null (assume it's active)
    // This would typically involve:
    // 1. Making a HEAD request to the URL
    // 2. Checking the response status code
    // 3. Handling timeouts and network errors

    return null;
  }
}

class IpRule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'ip_validation';
    }

    if (value is! String) {
      return 'ip_validation';
    }

    final ipv4Regex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
      r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );

    final ipv6Regex = RegExp(
      r'^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|'
      r'([0-9a-fA-F]{1,4}:){1,7}:|'
      r'([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|'
      r'([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|'
      r'([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|'
      r'([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|'
      r'([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|'
      r'[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|'
      r':((:[0-9a-fA-F]{1,4}){1,7}|:)|'
      r'fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|'
      r'::(ffff(:0{1,4}){0,1}:){0,1}'
      r'((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}'
      r'(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|'
      r'([0-9a-fA-F]{1,4}:){1,4}:'
      r'((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}'
      r'(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$',
    );

    if (!ipv4Regex.hasMatch(value) && !ipv6Regex.hasMatch(value)) {
      return 'ip_validation';
    }

    return null;
  }
}

class Ipv4Rule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'ipv4_validation';
    }

    if (value is! String) {
      return 'ipv4_validation';
    }

    final ipv4Regex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
      r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );

    if (!ipv4Regex.hasMatch(value)) {
      return 'ipv4_validation';
    }

    return null;
  }
}

class Ipv6Rule extends Rule {
  @override
  String? validate(
    String field,
    dynamic value,
    String? arg, {
    required Map<String, dynamic> data,
  }) {
    if (value == null) {
      return 'ipv6_validation';
    }

    if (value is! String) {
      return 'ipv6_validation';
    }

    final ipv6Regex = RegExp(
      r'^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|'
      r'([0-9a-fA-F]{1,4}:){1,7}:|'
      r'([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|'
      r'([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|'
      r'([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|'
      r'([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|'
      r'([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|'
      r'[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|'
      r':((:[0-9a-fA-F]{1,4}){1,7}|:)|'
      r'fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|'
      r'::(ffff(:0{1,4}){0,1}:){0,1}'
      r'((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}'
      r'(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|'
      r'([0-9a-fA-F]{1,4}:){1,4}:'
      r'((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}'
      r'(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$',
    );

    if (!ipv6Regex.hasMatch(value)) {
      return 'ipv6_validation';
    }

    return null;
  }
}
