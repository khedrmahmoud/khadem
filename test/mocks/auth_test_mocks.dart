import 'package:khadem/src/contracts/config/config_contract.dart';
import 'package:khadem/src/contracts/container/container_interface.dart';
import 'package:khadem/src/contracts/env/env_interface.dart';
import 'package:khadem/src/core/database/database.dart';
import 'package:khadem/src/modules/auth/contracts/auth_config.dart';
import 'package:khadem/src/modules/auth/contracts/authenticatable.dart';
import 'package:khadem/src/modules/auth/contracts/auth_repository.dart';
import 'package:khadem/src/modules/auth/contracts/password_verifier.dart';
import 'package:khadem/src/modules/auth/drivers/auth_driver.dart';
import 'package:khadem/src/modules/auth/guards/base_guard.dart';
import 'package:khadem/src/modules/auth/services/auth_manager.dart';
import 'package:khadem/src/contracts/session/session_interfaces.dart';
import 'package:khadem/src/core/http/request/request.dart';
import 'package:khadem/src/core/http/response/response.dart';
import 'package:mockito/mockito.dart';

// Mock classes for testing
class MockContainer extends Mock implements ContainerInterface {}

class MockEnv extends Mock implements EnvInterface {}

class MockConfig extends Mock implements ConfigInterface {}

class MockAuthConfig extends Mock implements AuthConfig {}

class MockDatabaseManager extends Mock implements DatabaseManager {}

class MockAuthDriver extends Mock implements AuthDriver {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockPasswordVerifier extends Mock implements PasswordVerifier {}

class MockAuthenticatable extends Mock implements Authenticatable {}

class MockSessionManager extends Mock implements ISessionManager {}

class MockAuthManager extends Mock implements AuthManager {}

class MockRequest extends Mock implements Request {}

class MockResponse extends Mock implements Response {}

class MockSession extends Mock {
  dynamic get(String key) => null;
  void set(String key, dynamic value) {}
  void remove(String key) {}
  void destroy() {}
  void flash(String key, dynamic value) {}
  bool has(String key) => false;
}

class MockGuard extends Mock implements Guard {}

// Test setup utilities
class TestSetup {
  static final MockContainer mockContainer = MockContainer();
  static final MockEnv mockEnv = MockEnv();
  static final MockConfig mockConfig = MockConfig();
  static final MockAuthConfig mockAuthConfig = MockAuthConfig();
  static final MockDatabaseManager mockDb = MockDatabaseManager();

  static void setupContainer() {
    // Mock the container resolve methods
    when(mockContainer.resolve<EnvInterface>()).thenReturn(mockEnv);
    when(mockContainer.resolve<ConfigInterface>()).thenReturn(mockConfig);
    when(mockContainer.resolve<DatabaseManager>()).thenReturn(mockDb);

    // Mock environment values
    when(mockEnv.get('JWT_SECRET'))
        .thenReturn('test_jwt_secret_key_for_testing');
    when(mockEnv.get('JWT_ALGORITHM')).thenReturn('HS256');
    when(mockEnv.get('DB_CONNECTION')).thenReturn('test');

    // Mock config values
    when(mockConfig.section('auth')).thenReturn({
      'default': 'api',
      'guards': {
        'api': {
          'driver': 'token',
          'provider': 'users',
        },
      },
      'providers': {
        'users': {
          'table': 'users',
          'primary_key': 'id',
          'fields': ['email'], // Only identifier fields, NOT password
        },
      },
    });

    // Mock auth config methods
    when(mockAuthConfig.getProvider('users')).thenReturn({
      'table': 'users',
      'primary_key': 'id',
      'fields': ['email'], // Only identifier fields, NOT password
    });

    when(mockAuthConfig.getGuard('api')).thenReturn({
      'driver': 'token',
      'provider': 'users',
    });

    when(mockAuthConfig.getDefaultGuard()).thenReturn('api');
  }

  static void resetContainer() {
    reset(mockContainer);
    reset(mockEnv);
    reset(mockConfig);
    reset(mockAuthConfig);
    reset(mockDb);
  }
}
