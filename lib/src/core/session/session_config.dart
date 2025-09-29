/// Configuration for session management
class SessionConfig {
  final String driver;
  final int lifetime;
  final bool expireOnClose;
  final bool encrypt;
  final String path;
  final String? domain;
  final bool secure;
  final bool httpOnly;
  final String sameSite;

  const SessionConfig({
    required this.driver,
    required this.lifetime,
    required this.expireOnClose,
    required this.encrypt,
    required this.path,
    required this.secure,
    required this.httpOnly,
    required this.sameSite,
    this.domain,
  });

  factory SessionConfig.fromMap(Map<String, dynamic> map) {
    return SessionConfig(
      driver: map['driver'] as String,
      lifetime: map['lifetime'] as int,
      expireOnClose: map['expire_on_close'] as bool,
      encrypt: map['encrypt'] as bool,
      path: map['path'] as String,
      domain: map['domain'] as String?,
      secure: map['secure'] as bool,
      httpOnly: map['http_only'] as bool,
      sameSite: map['same_site'] as String,
    );
  }
}