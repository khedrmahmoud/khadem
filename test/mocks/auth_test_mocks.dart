import 'package:khadem/src/contracts/config/config_contract.dart';
import 'package:khadem/src/contracts/container/container_interface.dart';
import 'package:khadem/src/contracts/env/env_interface.dart';
import 'package:khadem/src/core/database/database.dart';
import 'package:khadem/src/modules/auth/contracts/auth_config.dart';
import 'package:mockito/mockito.dart';

// Mock classes for testing
class MockContainer extends Mock implements ContainerInterface {}

class MockEnv extends Mock implements EnvInterface {}

class MockConfig extends Mock implements ConfigInterface {}

class MockAuthConfig extends Mock implements AuthConfig {}

class MockDatabaseManager extends Mock implements DatabaseManager {}

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
          'fields': ['email', 'password'],
        },
      },
    });

    // Mock auth config methods
    when(mockAuthConfig.getProvider('users')).thenReturn({
      'table': 'users',
      'primary_key': 'id',
      'fields': ['email', 'password'],
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
