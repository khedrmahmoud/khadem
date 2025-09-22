import 'dart:io';

import 'package:khadem/src/core/config/env_system.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late EnvSystem env;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('env_test_');
    env = EnvSystem(useProcessEnv: false); // Don't load process env for testing
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('EnvSystem', () {
    group('Basic functionality', () {
      test('should create instance without process environment', () {
        final env = EnvSystem(useProcessEnv: false);
        expect(env, isNotNull);
        expect(env.loadedFiles, isEmpty);
      });

      test('should create instance with process environment', () {
        final env = EnvSystem();
        expect(env, isNotNull);
        expect(env.all().isNotEmpty, isTrue); // Should have process env vars
      });

      test('should set and get string values', () {
        env.set('TEST_KEY', 'test_value');
        expect(env.get('TEST_KEY'), equals('test_value'));
        expect(env.has('TEST_KEY'), isTrue);
      });

      test('should return null for non-existent keys', () {
        expect(env.get('NON_EXISTENT'), isNull);
        expect(env.has('NON_EXISTENT'), isFalse);
      });

      test('should get value with default', () {
        expect(env.getOrDefault('NON_EXISTENT', 'default'), equals('default'));
        env.set('EXISTING', 'actual_value');
        expect(env.getOrDefault('EXISTING', 'default'), equals('actual_value'));
      });

      test('should return all environment variables', () {
        env.set('KEY1', 'value1');
        env.set('KEY2', 'value2');

        final all = env.all();
        expect(all['KEY1'], equals('value1'));
        expect(all['KEY2'], equals('value2'));
        expect(all.length, equals(2));
      });

      test('should clear all variables', () {
        env.set('KEY1', 'value1');
        env.set('KEY2', 'value2');
        expect(env.all().isNotEmpty, isTrue);

        env.clear();
        expect(env.all().isEmpty, isTrue);
        expect(env.loadedFiles.isEmpty, isTrue);
      });
    });

    group('Type casting', () {
      test('should get boolean values', () {
        env.set('BOOL_TRUE', 'true');
        env.set('BOOL_FALSE', 'false');
        env.set('BOOL_ONE', '1');
        env.set('BOOL_ZERO', '0');
        env.set('BOOL_YES', 'yes');
        env.set('BOOL_NO', 'no');
        env.set('BOOL_INVALID', 'invalid');

        expect(env.getBool('BOOL_TRUE'), isTrue);
        expect(env.getBool('BOOL_FALSE'), isFalse);
        expect(env.getBool('BOOL_ONE'), isTrue);
        expect(env.getBool('BOOL_ZERO'), isFalse);
        expect(env.getBool('BOOL_YES'), isTrue);
        expect(env.getBool('BOOL_NO'), isFalse);
        expect(env.getBool('BOOL_INVALID'), isFalse); // Default false
        expect(env.getBool('NON_EXISTENT', defaultValue: true), isTrue);
      });

      test('should get integer values', () {
        env.set('INT_VALID', '42');
        env.set('INT_INVALID', 'not_a_number');

        expect(env.getInt('INT_VALID'), equals(42));
        expect(env.getInt('INT_INVALID'), equals(0)); // Default value
        expect(env.getInt('NON_EXISTENT', defaultValue: 100), equals(100));
      });

      test('should get double values', () {
        env.set('DOUBLE_VALID', '3.14');
        env.set('DOUBLE_INT', '42');
        env.set('DOUBLE_INVALID', 'not_a_number');

        expect(env.getDouble('DOUBLE_VALID'), equals(3.14));
        expect(env.getDouble('DOUBLE_INT'), equals(42.0));
        expect(env.getDouble('DOUBLE_INVALID'), equals(0.0)); // Default value
        expect(env.getDouble('NON_EXISTENT', defaultValue: 1.5), equals(1.5));
      });

      test('should get list values', () {
        env.set('LIST_COMMA', 'a,b,c');
        env.set('LIST_SEMICOLON', 'x;y;z');
        env.set('LIST_EMPTY', '');
        env.set('LIST_SPACES', ' a , b , c ');

        expect(env.getList('LIST_COMMA'), equals(['a', 'b', 'c']));
        expect(
          env.getList('LIST_SEMICOLON', separator: ';'),
          equals(['x', 'y', 'z']),
        );
        expect(env.getList('LIST_EMPTY'), equals([]));
        expect(env.getList('LIST_SPACES'), equals(['a', 'b', 'c']));
        expect(
          env.getList('NON_EXISTENT', defaultValue: ['default']),
          equals(['default']),
        );
      });
    });

    group('File loading', () {
      test('should load .env file', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('''
# Comment
APP_NAME=TestApp
APP_VERSION=1.0.0
DEBUG=true
PORT=3000

# Quoted values
DATABASE_URL="postgresql://user:pass@localhost:5432/db"
API_KEY='secret-key'

# Export statements
export REDIS_URL=redis://localhost:6379
        ''');

        final env = EnvSystem(useProcessEnv: false);
        env.loadFromFile(envFile.path);

        expect(env.get('APP_NAME'), equals('TestApp'));
        expect(env.get('APP_VERSION'), equals('1.0.0'));
        expect(env.getBool('DEBUG'), isTrue);
        expect(env.getInt('PORT'), equals(3000));
        expect(
          env.get('DATABASE_URL'),
          equals('postgresql://user:pass@localhost:5432/db'),
        );
        expect(env.get('API_KEY'), equals('secret-key'));
        expect(env.get('REDIS_URL'), equals('redis://localhost:6379'));
        expect(env.loadedFiles, contains(envFile.path));
      });

      test('should handle non-existent file gracefully', () {
        final env = EnvSystem(useProcessEnv: false);
        env.loadFromFile('${tempDir.path}/non_existent.env');
        expect(env.loadedFiles, isEmpty);
      });

      test('should handle empty .env file', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('');

        final env = EnvSystem(useProcessEnv: false);
        env.loadFromFile(envFile.path);

        expect(env.all().isEmpty, isTrue);
        expect(env.loadedFiles, contains(envFile.path));
      });

      test('should handle .env file with only comments', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('''
# This is a comment
# Another comment
# APP_NAME=TestApp
        ''');

        final env = EnvSystem(useProcessEnv: false);
        env.loadFromFile(envFile.path);

        expect(env.all().isEmpty, isTrue);
      });

      test('should handle malformed lines', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('''
VALID_KEY=valid_value
INVALID_LINE_NO_EQUALS
ANOTHER_INVALID_LINE
EMPTY_VALUE=
        ''');

        final env = EnvSystem(useProcessEnv: false);
        env.loadFromFile(envFile.path);

        expect(env.get('VALID_KEY'), equals('valid_value'));
        expect(env.get('EMPTY_VALUE'), equals(''));
        expect(env.has('INVALID_LINE_NO_EQUALS'), isFalse);
        expect(env.has('ANOTHER_INVALID_LINE'), isFalse);
      });

      test('should handle escaped characters', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('''
ESCAPED_EQUALS=VALUE\\=WITH_EQUALS
ESCAPED_QUOTE=VALUE\\"WITH_QUOTE
NORMAL_EQUALS=VALUE=WITH_EQUALS
        ''');

        final env = EnvSystem(useProcessEnv: false);
        env.loadFromFile(envFile.path);

        expect(env.get('ESCAPED_EQUALS'), equals('VALUE=WITH_EQUALS'));
        expect(env.get('ESCAPED_QUOTE'), equals('VALUE"WITH_QUOTE'));
        expect(env.get('NORMAL_EQUALS'), equals('VALUE=WITH_EQUALS'));
      });
    });

    group('Variable substitution', () {
      test('should substitute simple variables', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('''
APP_NAME=MyApp
VERSION=1.0
WELCOME_MESSAGE=Welcome to \$APP_NAME v\$VERSION
FULL_NAME=\${APP_NAME} Application
        ''');

        final testEnv = EnvSystem(useProcessEnv: false);
        testEnv.loadFromFile(envFile.path);

        expect(testEnv.get('WELCOME_MESSAGE'), equals('Welcome to MyApp v1.0'));
        expect(testEnv.get('FULL_NAME'), equals('MyApp Application'));
      });

      test('should handle missing variables in substitution', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('''
MESSAGE=Hello \$MISSING_VAR world
        ''');

        final testEnv = EnvSystem(useProcessEnv: false);
        testEnv.loadFromFile(envFile.path);

        expect(testEnv.get('MESSAGE'), equals('Hello  world'));
      });

      test('should handle complex variable substitution', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('''
BASE_URL=http://localhost
PORT=3000
PATH=/api/v1
API_URL=\${BASE_URL}:\${PORT}\${PATH}
        ''');

        final testEnv = EnvSystem(useProcessEnv: false);
        testEnv.loadFromFile(envFile.path);

        expect(testEnv.get('API_URL'), equals('http://localhost:3000/api/v1'));
      });

      test('should handle nested variable substitution', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('''
BASE_PATH=/app
CONFIG_PATH=\${BASE_PATH}/config
LOG_PATH=\${CONFIG_PATH}/logs
        ''');

        final testEnv = EnvSystem(useProcessEnv: false);
        testEnv.loadFromFile(envFile.path);

        expect(testEnv.get('BASE_PATH'), equals('/app'));
        expect(testEnv.get('CONFIG_PATH'), equals('/app/config'));
        expect(testEnv.get('LOG_PATH'), equals('/app/config/logs'));
      });
    });

    group('Validation', () {
      test('should validate required variables - all present', () {
        env.set('VAR1', 'value1');
        env.set('VAR2', 'value2');
        env.set('VAR3', 'value3');

        final missing = env.validateRequired(['VAR1', 'VAR2', 'VAR3']);
        expect(missing, isEmpty);
      });

      test('should validate required variables - some missing', () {
        env.set('VAR1', 'value1');
        env.set('VAR3', 'value3');

        final missing = env.validateRequired(['VAR1', 'VAR2', 'VAR3']);
        expect(missing, equals(['VAR2']));
      });

      test('should validate required variables - empty values', () {
        env.set('VAR1', 'value1');
        env.set('VAR2', ''); // Empty value
        env.set('VAR3', 'value3');

        final missing = env.validateRequired(['VAR1', 'VAR2', 'VAR3']);
        expect(missing, equals(['VAR2']));
      });

      test('should validate required variables - all missing', () {
        final missing = env.validateRequired(['VAR1', 'VAR2', 'VAR3']);
        expect(missing, equals(['VAR1', 'VAR2', 'VAR3']));
      });

      test('should validate required variables - empty list', () {
        final missing = env.validateRequired([]);
        expect(missing, isEmpty);
      });
    });

    group('Integration scenarios', () {
      test('should handle real-world .env file', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('''
# Application Configuration
APP_NAME=Khadem
APP_ENV=testing
APP_DEBUG=true
APP_URL=http://localhost

# Database Configuration
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=khadem_test
DB_USERNAME=root
DB_PASSWORD=

# Cache Configuration
CACHE_DRIVER=file
CACHE_PREFIX=khadem_cache

# Session Configuration
SESSION_DRIVER=file
SESSION_LIFETIME=120

# Queue Configuration
QUEUE_CONNECTION=sync

# Mail Configuration
MAIL_MAILER=log
MAIL_HOST=127.0.0.1
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="\${APP_NAME}"

# Broadcasting
BROADCAST_CONNECTION=log

# Filesystem
FILESYSTEM_DISK=local

# Custom Variables
API_RATE_LIMIT=1000
MAX_FILE_SIZE=10240
ALLOWED_EXTENSIONS=jpg,png,pdf,doc
        ''');

        final env = EnvSystem(useProcessEnv: false);
        env.loadFromFile(envFile.path);

        // Test various types of values
        expect(env.get('APP_NAME'), equals('Khadem'));
        expect(env.getBool('APP_DEBUG'), isTrue);
        expect(env.getInt('DB_PORT'), equals(3306));
        expect(env.getInt('SESSION_LIFETIME'), equals(120));
        expect(env.get('MAIL_FROM_ADDRESS'), equals('hello@example.com'));
        expect(
          env.get('MAIL_FROM_NAME'),
          equals('Khadem'),
        ); // Variable substitution
        expect(env.getInt('API_RATE_LIMIT'), equals(1000));
        expect(env.getInt('MAX_FILE_SIZE'), equals(10240));
        expect(
          env.getList('ALLOWED_EXTENSIONS'),
          equals(['jpg', 'png', 'pdf', 'doc']),
        );
      });

      test('should handle multiple .env files', () {
        final baseEnv = File('${tempDir.path}/.env');
        baseEnv.writeAsStringSync('''
APP_NAME=Khadem
APP_ENV=production
DEBUG=false
        ''');

        final localEnv = File('${tempDir.path}/.env.local');
        localEnv.writeAsStringSync('''
APP_ENV=development
DEBUG=true
LOCAL_VAR=local_value
        ''');

        final env = EnvSystem(useProcessEnv: false);
        env.loadFromFile(baseEnv.path);
        env.loadFromFile(localEnv.path);

        expect(env.get('APP_NAME'), equals('Khadem')); // From base
        expect(
          env.get('APP_ENV'),
          equals('development'),
        ); // Overridden by local
        expect(env.getBool('DEBUG'), isTrue); // Overridden by local
        expect(env.get('LOCAL_VAR'), equals('local_value')); // From local
        expect(env.loadedFiles, containsAll([baseEnv.path, localEnv.path]));
      });
    });
  });
}
