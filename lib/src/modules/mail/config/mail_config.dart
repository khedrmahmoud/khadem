/// Mail configuration class.
///
/// Defines mail settings including transports, default from address,
/// and driver-specific configurations.
class MailConfig {
  /// Default mail transport to use.
  final String defaultTransport;

  /// Default from address for all emails.
  final MailFromConfig from;

  /// SMTP configuration (if using SMTP transport).
  final SmtpConfig? smtp;

  /// Mailgun configuration (if using Mailgun transport).
  final MailgunConfig? mailgun;

  /// SES configuration (if using SES transport).
  final SesConfig? ses;

  /// Postmark configuration (if using Postmark transport).
  final PostmarkConfig? postmark;

  const MailConfig({
    required this.from, this.defaultTransport = 'log',
    this.smtp,
    this.mailgun,
    this.ses,
    this.postmark,
  });

  /// Creates configuration from a map.
  factory MailConfig.fromMap(Map<String, dynamic> map) {
    return MailConfig(
      defaultTransport: map['default'] as String? ?? 'log',
      from: MailFromConfig.fromMap(map['from'] as Map<String, dynamic>),
      smtp: map['smtp'] != null 
          ? SmtpConfig.fromMap(map['smtp'] as Map<String, dynamic>)
          : null,
      mailgun: map['mailgun'] != null
          ? MailgunConfig.fromMap(map['mailgun'] as Map<String, dynamic>)
          : null,
      ses: map['ses'] != null
          ? SesConfig.fromMap(map['ses'] as Map<String, dynamic>)
          : null,
      postmark: map['postmark'] != null
          ? PostmarkConfig.fromMap(map['postmark'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Converts to map.
  Map<String, dynamic> toMap() {
    return {
      'default': defaultTransport,
      'from': from.toMap(),
      if (smtp != null) 'smtp': smtp!.toMap(),
      if (mailgun != null) 'mailgun': mailgun!.toMap(),
      if (ses != null) 'ses': ses!.toMap(),
      if (postmark != null) 'postmark': postmark!.toMap(),
    };
  }
}

/// From address configuration.
class MailFromConfig {
  final String address;
  final String? name;

  const MailFromConfig({
    required this.address,
    this.name,
  });

  factory MailFromConfig.fromMap(Map<String, dynamic> map) {
    return MailFromConfig(
      address: map['address'] as String,
      name: map['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      if (name != null) 'name': name,
    };
  }
}

/// SMTP transport configuration.
class SmtpConfig {
  final String host;
  final int port;
  final String? username;
  final String? password;
  final String encryption; // 'tls', 'ssl', or 'none'
  final int timeout;

  const SmtpConfig({
    required this.host,
    this.port = 587,
    this.username,
    this.password,
    this.encryption = 'tls',
    this.timeout = 30,
  });

  factory SmtpConfig.fromMap(Map<String, dynamic> map) {
    return SmtpConfig(
      host: map['host'] as String,
      port: map['port'] as int? ?? 587,
      username: map['username'] as String?,
      password: map['password'] as String?,
      encryption: map['encryption'] as String? ?? 'tls',
      timeout: map['timeout'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'host': host,
      'port': port,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      'encryption': encryption,
      'timeout': timeout,
    };
  }
}

/// Mailgun API configuration.
class MailgunConfig {
  final String apiKey;
  final String domain;
  final String endpoint;

  const MailgunConfig({
    required this.apiKey,
    required this.domain,
    this.endpoint = 'https://api.mailgun.net/v3',
  });

  factory MailgunConfig.fromMap(Map<String, dynamic> map) {
    return MailgunConfig(
      apiKey: map['apiKey'] as String,
      domain: map['domain'] as String,
      endpoint: map['endpoint'] as String? ?? 'https://api.mailgun.net/v3',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'apiKey': apiKey,
      'domain': domain,
      'endpoint': endpoint,
    };
  }
}

/// Amazon SES configuration.
class SesConfig {
  final String accessKeyId;
  final String secretAccessKey;
  final String region;
  final String? configurationSet;

  const SesConfig({
    required this.accessKeyId,
    required this.secretAccessKey,
    this.region = 'us-east-1',
    this.configurationSet,
  });

  factory SesConfig.fromMap(Map<String, dynamic> map) {
    return SesConfig(
      accessKeyId: map['accessKeyId'] as String,
      secretAccessKey: map['secretAccessKey'] as String,
      region: map['region'] as String? ?? 'us-east-1',
      configurationSet: map['configurationSet'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accessKeyId': accessKeyId,
      'secretAccessKey': secretAccessKey,
      'region': region,
      if (configurationSet != null) 'configurationSet': configurationSet,
    };
  }
}

/// Postmark API configuration.
class PostmarkConfig {
  final String serverToken;
  final String? messageStream;

  const PostmarkConfig({
    required this.serverToken,
    this.messageStream = 'outbound',
  });

  factory PostmarkConfig.fromMap(Map<String, dynamic> map) {
    return PostmarkConfig(
      serverToken: map['serverToken'] as String,
      messageStream: map['messageStream'] as String? ?? 'outbound',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serverToken': serverToken,
      if (messageStream != null) 'messageStream': messageStream,
    };
  }
}
