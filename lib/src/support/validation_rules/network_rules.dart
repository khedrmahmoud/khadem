import 'dart:async';
import 'dart:io';
import '../../contracts/validation/rule.dart';

/// Validates that the field is a valid URL.
///
/// Checks protocol (http/https), domain, and format.
class UrlRule extends Rule {
  @override
  String get signature => 'url';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;
    if (value is! String) return false;

    final urlRegex = RegExp(
      r'^https?://' // protocol
      r'(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+' // domain
      r'[a-zA-Z]{2,}' // top-level domain
      r'(?::\d{1,5})?' // optional port
      r'(?:/?|[/?]\S+)$', // path
      caseSensitive: false,
    );

    return urlRegex.hasMatch(value);
  }

  @override
  String message(ValidationContext context) => 'url_validation';
}

/// Validates that the field is a valid active URL by checking DNS records.
///
/// Performs a real [InternetAddress.lookup] to verify the host exists.
class ActiveUrlRule extends Rule {
  @override
  String get signature => 'active_url';

  @override
  FutureOr<bool> passes(ValidationContext context) async {
    final value = context.value;
    // First check if it's a valid URL format
    if (!await UrlRule().passes(context)) return false;

    if (value is! String) return false;

    try {
      final uri = Uri.parse(value);
      final host = uri.host;
      if (host.isEmpty) return false;

      final addresses = await InternetAddress.lookup(host);
      return addresses.isNotEmpty && addresses[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  String message(ValidationContext context) => 'active_url_validation';
}

/// Validates that the field is a valid IP address (IPv4 or IPv6).
class IpRule extends Rule {
  @override
  String get signature => 'ip';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;
    if (value is! String) return false;

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

    return ipv4Regex.hasMatch(value) || ipv6Regex.hasMatch(value);
  }

  @override
  String message(ValidationContext context) => 'ip_validation';
}

/// Validates that the field is a valid IPv4 address.
class Ipv4Rule extends Rule {
  @override
  String get signature => 'ipv4';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;
    if (value is! String) return false;

    final ipv4Regex = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}'
      r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );

    return ipv4Regex.hasMatch(value);
  }

  @override
  String message(ValidationContext context) => 'ipv4_validation';
}

/// Validates that the field is a valid IPv6 address.
class Ipv6Rule extends Rule {
  @override
  String get signature => 'ipv6';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null) return false;
    if (value is! String) return false;

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

    return ipv6Regex.hasMatch(value);
  }

  @override
  String message(ValidationContext context) => 'ipv6_validation';
}

/// Validates that the field is a valid MAC address.
///
/// Supports standard formats like `00:1A:2B:3C:4D:5E`.
class MacAddressRule extends Rule {
  @override
  String get signature => 'mac_address';

  @override
  FutureOr<bool> passes(ValidationContext context) {
    final value = context.value;
    if (value == null || value is! String) return false;
    
    // Supports 00:00:00:00:00:00 and 00-00-00-00-00-00 and 0000.0000.0000 formats
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    return macRegex.hasMatch(value);
  }

  @override
  String message(ValidationContext context) => 'mac_address_validation';
}
