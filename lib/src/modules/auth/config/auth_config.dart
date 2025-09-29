/// Configuration class for authentication settings
class AuthConfig {
  final String defaultGuard;
  final String defaultPasswords;
  final Map<String, GuardConfig> guards;
  final Map<String, ProviderConfig> providers;
  final Map<String, PasswordResetConfig> passwords;
  final PasswordPolicyConfig passwordPolicy;
  final SessionConfig session;

  const AuthConfig({
    required this.defaultGuard,
    required this.defaultPasswords,
    required this.guards,
    required this.providers,
    required this.passwords,
    required this.passwordPolicy,
    required this.session,
  });

  /// Create AuthConfig from configuration map
  factory AuthConfig.fromConfig(Map<String, dynamic> config) {
    return AuthConfig(
      defaultGuard: config['defaults']['guard'] as String,
      defaultPasswords: config['defaults']['passwords'] as String,
      guards: (config['guards'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, GuardConfig.fromMap(value)),
      ),
      providers: (config['providers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, ProviderConfig.fromMap(value)),
      ),
      passwords: (config['passwords'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, PasswordResetConfig.fromMap(value)),
      ),
      passwordPolicy: PasswordPolicyConfig.fromMap(config['password_policy']),
      session: SessionConfig.fromMap(config['session']),
    );
  }

  /// Get guard configuration by name
  GuardConfig getGuard(String name) {
    return guards[name] ?? guards[defaultGuard]!;
  }

  /// Get provider configuration by name
  ProviderConfig getProvider(String name) {
    return providers[name]!;
  }

  /// Get password reset configuration by name
  PasswordResetConfig getPasswordReset(String name) {
    return passwords[name] ?? passwords[defaultPasswords]!;
  }
}

/// Configuration for authentication guards
class GuardConfig {
  final String driver;
  final String provider;
  final bool? hash;

  const GuardConfig({
    required this.driver,
    required this.provider,
    this.hash,
  });

  factory GuardConfig.fromMap(Map<String, dynamic> map) {
    return GuardConfig(
      driver: map['driver'] as String,
      provider: map['provider'] as String,
      hash: map['hash'] as bool?,
    );
  }
}

/// Configuration for user providers
class ProviderConfig {
  final String driver;
  final String model;
  final String table;
  final String primaryKey;
  final List<String> fields;

  const ProviderConfig({
    required this.driver,
    required this.model,
    required this.table,
    required this.primaryKey,
    required this.fields,
  });

  factory ProviderConfig.fromMap(Map<String, dynamic> map) {
    return ProviderConfig(
      driver: map['driver'] as String,
      model: map['model'] as String,
      table: map['table'] as String,
      primaryKey: map['primary_key'] as String,
      fields: List<String>.from(map['fields'] as List),
    );
  }
}

/// Configuration for password reset functionality
class PasswordResetConfig {
  final String provider;
  final String table;
  final int expire;
  final int throttle;

  const PasswordResetConfig({
    required this.provider,
    required this.table,
    required this.expire,
    required this.throttle,
  });

  factory PasswordResetConfig.fromMap(Map<String, dynamic> map) {
    return PasswordResetConfig(
      provider: map['provider'] as String,
      table: map['table'] as String,
      expire: map['expire'] as int,
      throttle: map['throttle'] as int,
    );
  }
}

/// Configuration for password policies
class PasswordPolicyConfig {
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSymbols;

  const PasswordPolicyConfig({
    required this.minLength,
    required this.requireUppercase,
    required this.requireLowercase,
    required this.requireNumbers,
    required this.requireSymbols,
  });

  factory PasswordPolicyConfig.fromMap(Map<String, dynamic> map) {
    return PasswordPolicyConfig(
      minLength: map['min_length'] as int,
      requireUppercase: map['require_uppercase'] as bool,
      requireLowercase: map['require_lowercase'] as bool,
      requireNumbers: map['require_numbers'] as bool,
      requireSymbols: map['require_symbols'] as bool,
    );
  }
}

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