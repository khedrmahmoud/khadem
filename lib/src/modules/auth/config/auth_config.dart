/// Configuration class for authentication settings
class AuthConfig {
  final String defaultGuard;
  final String defaultPasswords;
  final Map<String, GuardConfig> guards;
  final Map<String, ProviderConfig> providers;
  final Map<String, PasswordResetConfig> passwords;
  final PasswordPolicyConfig passwordPolicy;
  final SessionConfig session;
  final TokenConfig token;
  final WebConfig web;
  final RoutesConfig routes;

  const AuthConfig({
    required this.defaultGuard,
    required this.defaultPasswords,
    required this.guards,
    required this.providers,
    required this.passwords,
    required this.passwordPolicy,
    required this.session,
    required this.token,
    required this.web,
    required this.routes,
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
      token: TokenConfig.fromMap(config['token'] ?? {}),
      web: WebConfig.fromMap(config['web'] ?? {}),
      routes: RoutesConfig.fromMap(config['routes'] ?? {}),
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

/// Configuration for JWT/API token management
class TokenConfig {
  final String driver;
  final String secret;
  final int ttl;
  final String algorithm;
  final bool refreshEnabled;
  final int refreshTtl;
  final String? issuer;
  final String? audience;

  const TokenConfig({
    required this.driver,
    required this.secret,
    required this.ttl,
    required this.algorithm,
    required this.refreshEnabled,
    required this.refreshTtl,
    this.issuer,
    this.audience,
  });

  factory TokenConfig.fromMap(Map<String, dynamic> map) {
    return TokenConfig(
      driver: map['driver'] ?? 'jwt',
      secret: map['secret'] ?? 'your-secret-key',
      ttl: map['ttl'] ?? 3600, // 1 hour
      algorithm: map['algorithm'] ?? 'HS256',
      refreshEnabled: map['refresh_enabled'] ?? true,
      refreshTtl: map['refresh_ttl'] ?? 604800, // 7 days
      issuer: map['issuer'] as String?,
      audience: map['audience'] as String?,
    );
  }
}

/// Configuration for web authentication settings
class WebConfig {
  final bool enableLogin;
  final bool enableRegistration;
  final bool enablePasswordReset;
  final bool enableEmailVerification;
  final int loginAttempts;
  final int lockoutDuration;
  final bool rememberMeEnabled;
  final int rememberMeDuration;
  final String? loginRedirect;
  final String? logoutRedirect;
  final List<String> allowedDomains;

  const WebConfig({
    required this.allowedDomains,
    required this.enableLogin,
    required this.enableRegistration,
    required this.enablePasswordReset,
    required this.enableEmailVerification,
    required this.loginAttempts,
    required this.lockoutDuration,
    required this.rememberMeEnabled,
    required this.rememberMeDuration,
    this.loginRedirect,
    this.logoutRedirect,
  });

  factory WebConfig.fromMap(Map<String, dynamic> map) {
    return WebConfig(
      enableLogin: map['enable_login'] ?? true,
      enableRegistration: map['enable_registration'] ?? true,
      enablePasswordReset: map['enable_password_reset'] ?? true,
      enableEmailVerification: map['enable_email_verification'] ?? false,
      loginAttempts: map['login_attempts'] ?? 5,
      lockoutDuration: map['lockout_duration'] ?? 900, // 15 minutes
      rememberMeEnabled: map['remember_me_enabled'] ?? true,
      rememberMeDuration: map['remember_me_duration'] ?? 604800, // 7 days
      loginRedirect: map['login_redirect'] as String?,
      logoutRedirect: map['logout_redirect'] as String?,
      allowedDomains: List<String>.from(map['allowed_domains'] ?? []),
    );
  }
}

/// Configuration for authentication routes
class RoutesConfig {
  final String login;
  final String logout;
  final String register;
  final String passwordReset;
  final String passwordResetRequest;
  final String emailVerification;
  final String home;
  final String apiPrefix;

  const RoutesConfig({
    required this.login,
    required this.logout,
    required this.register,
    required this.passwordReset,
    required this.passwordResetRequest,
    required this.emailVerification,
    required this.home,
    required this.apiPrefix,
  });

  factory RoutesConfig.fromMap(Map<String, dynamic> map) {
    return RoutesConfig(
      login: map['login'] ?? '/login',
      logout: map['logout'] ?? '/logout',
      register: map['register'] ?? '/register',
      passwordReset: map['password_reset'] ?? '/password/reset',
      passwordResetRequest: map['password_reset_request'] ?? '/password/email',
      emailVerification: map['email_verification'] ?? '/email/verify',
      home: map['home'] ?? '/',
      apiPrefix: map['api_prefix'] ?? '/api',
    );
  }
}