import 'package:khadem/src/core/http/context/request_context.dart';
import 'package:khadem/src/core/http/request/request.dart';
import 'package:khadem/src/core/lang/file_lang_provider.dart';
import 'package:khadem/src/core/lang/lang.dart';
import 'package:test/test.dart';

import '../../mocks/http_mocks.dart';

void main() {
  group('Lang System Tests', () {
    late FileLangProvider provider;

    setUp(() {
      provider = FileLangProvider();
      Lang.use(provider);
    });

    tearDown(() {
      Lang.clearCache();
    });

    group('Basic Translation', () {
      test('should translate simple key', () {
        provider.loadNamespace('', 'en', {'greeting': 'Hello World'});
        provider.setLocale('en');

        expect(Lang.t('greeting'), equals('Hello World'));
      });

      test('should return key if translation not found', () {
        provider.setLocale('en');

        expect(Lang.t('nonexistent'), equals('nonexistent'));
      });

      test('should fallback to fallback locale', () {
        provider.loadNamespace('', 'en', {'greeting': 'Hello'});
        provider.loadNamespace('', 'fr', {'greeting': 'Bonjour'});
        provider.setLocale('fr');
        provider.setFallbackLocale('en');

        // Remove fr translation to test fallback
        provider.loadNamespace('', 'fr', {});

        expect(Lang.t('greeting'), equals('Hello'));
      });
    });

    group('Parameter Replacement', () {
      test('should replace single parameter', () {
        provider.loadNamespace('', 'en', {'welcome': 'Hello :name'});
        provider.setLocale('en');

        expect(Lang.t('welcome', parameters: {'name': 'Alice'}),
            equals('Hello Alice'),);
      });

      test('should replace multiple parameters', () {
        provider.loadNamespace(
            '', 'en', {'message': ':greeting :name, welcome to :app'},);
        provider.setLocale('en');

        final result = Lang.t(
          'message',
          parameters: {
            'greeting': 'Hi',
            'name': 'Bob',
            'app': 'MyApp',
          },
        );

        expect(result, equals('Hi Bob, welcome to MyApp'));
      });

      test('should handle missing parameters', () {
        provider.loadNamespace('', 'en', {'message': 'Hello :name'});
        provider.setLocale('en');

        expect(Lang.t('message'), equals('Hello :name'));
      });

      test('should handle non-string parameter values', () {
        provider.loadNamespace('', 'en', {'count': 'You have :number items'});
        provider.setLocale('en');

        expect(Lang.t('count', parameters: {'number': 5}),
            equals('You have 5 items'),);
      });
    });

    group('Pluralization', () {
      test('should handle singular form', () {
        provider.loadNamespace('', 'en', {'apple': 'apple|apples'});
        provider.setLocale('en');

        expect(Lang.choice('apple', 1), equals('apple'));
      });

      test('should handle plural form', () {
        provider.loadNamespace('', 'en', {'apple': 'apple|apples'});
        provider.setLocale('en');

        expect(Lang.choice('apple', 2), equals('apples'));
        expect(Lang.choice('apple', 0), equals('apples'));
      });

      test('should handle pluralization with parameters', () {
        provider.loadNamespace('', 'en', {'item': ':count item|:count items'});
        provider.setLocale('en');

        expect(Lang.choice('item', 1), equals('1 item'));
        expect(Lang.choice('item', 3), equals('3 items'));
      });

      test('should handle complex pluralization', () {
        provider.loadNamespace(
            '', 'en', {'file': 'There is one file|There are :count files'},);
        provider.setLocale('en');

        expect(Lang.choice('file', 1), equals('There is one file'));
        expect(Lang.choice('file', 5), equals('There are 5 files'));
      });
    });

    group('Namespaces', () {
      test('should load and use namespaced translations', () {
        provider.loadNamespace('auth', 'en', {'login': 'Sign In'});
        provider.setLocale('en');

        expect(Lang.t('login', namespace: 'auth'), equals('Sign In'));
      });

      test('should fallback to global namespace', () {
        provider.loadNamespace('', 'en', {'greeting': 'Hello'});
        provider.loadNamespace('auth', 'en', {'login': 'Sign In'});
        provider.setLocale('en');

        expect(Lang.t('greeting', namespace: 'auth'), equals('Hello'));
      });

      test('should prioritize namespaced translation', () {
        provider.loadNamespace('', 'en', {'login': 'Global Login'});
        provider.loadNamespace('auth', 'en', {'login': 'Auth Login'});
        provider.setLocale('en');

        expect(Lang.t('login', namespace: 'auth'), equals('Auth Login'));
        expect(Lang.t('login'), equals('Global Login'));
      });
    });

    group('Field Translation', () {
      test('should translate field labels', () {
        provider.loadNamespace('', 'en',
            {'fields.name': 'Full Name', 'fields.email': 'Email Address'},);
        provider.setLocale('en');

        expect(Lang.getField('name'), equals('Full Name'));
        expect(Lang.getField('email'), equals('Email Address'));
      });

      test('should handle missing field translations', () {
        provider.setLocale('en');

        expect(Lang.getField('nonexistent'), equals('fields.nonexistent'));
      });
    });

    group('Locale Management', () {
      test('should set and get global locale', () {
        Lang.setGlobalLocale('fr');

        expect(Lang.getGlobalLocale(), equals('fr'));
      });

      test('should set and get fallback locale', () {
        Lang.setFallbackLocale('en');

        expect(Lang.getFallbackLocale(), equals('en'));
      });

      test('should handle request-specific locale', () {
        final mockRequest = Request(FakeHttpRequest());
        provider.loadNamespace('', 'en', {'greeting': 'Hello'});
        provider.loadNamespace('', 'fr', {'greeting': 'Bonjour'});

        final result = RequestContext.run(mockRequest, () {
          Lang.setRequestLocale('fr');
          return Lang.t('greeting');
        });

        expect(result, equals('Bonjour'));
      });
    });

    group('Existence Checks', () {
      test('should check if translation exists', () {
        provider.loadNamespace('', 'en', {'existing': 'Exists'});
        provider.setLocale('en');

        expect(Lang.has('existing'), isTrue);
        expect(Lang.has('nonexistent'), isFalse);
      });

      test('should check with specific locale', () {
        provider.loadNamespace('', 'en', {'greeting': 'Hello'});
        provider.loadNamespace('', 'fr', {'greeting': 'Bonjour'});
        provider.setLocale('en');

        expect(Lang.has('greeting', locale: 'fr'), isTrue);
        expect(Lang.has('missing', locale: 'fr'), isFalse);
      });

      test('should check with namespace', () {
        provider.loadNamespace('auth', 'en', {'login': 'Sign In'});
        provider.setLocale('en');

        expect(Lang.has('login', namespace: 'auth'), isTrue);
        expect(Lang.has('login'), isFalse);
      });
    });

    group('Raw Translation Access', () {
      test('should get raw translation value', () {
        provider.loadNamespace('', 'en', {'message': 'Hello :name'});
        provider.setLocale('en');

        expect(Lang.get('message'), equals('Hello :name'));
        expect(Lang.get('nonexistent'), isNull);
      });
    });

    group('Cache Management', () {
      test('should clear cache', () {
        provider.loadNamespace('', 'en', {'test': 'value'});
        provider.setLocale('en');

        expect(Lang.has('test'), isTrue);

        Lang.clearCache();
        // Cache clearing removes loaded translations
        expect(Lang.has('test'), isFalse);
      });
    });

    group('Available Locales', () {
      test('should get available locales', () {
        provider.loadNamespace('', 'en', {'test': 'value'});
        provider.loadNamespace('', 'fr', {'test': 'valeur'});

        final locales = Lang.getAvailableLocales();
        expect(locales, contains('en'));
        expect(locales, contains('fr'));
      });
    });

    group('Custom Parameter Replacers', () {
      test('should add and use custom replacer', () {
        provider.loadNamespace('', 'en', {'price': 'Price: :amount'});
        provider.setLocale('en');

        Lang.addParameterReplacer((key, value, params) {
          if (key == 'amount' && value is num) {
            return '\$${value.toStringAsFixed(2)}';
          }
          return ':$key';
        });

        expect(Lang.t('price', parameters: {'amount': 19.9901}),
            equals('Price: \$19.99'),);
      });

      test('should handle multiple custom replacers', () {
        provider.loadNamespace('', 'en', {'date': 'Date: :date, Time: :time'});
        provider.setLocale('en');

        Lang.addParameterReplacer((key, value, params) {
          if (key == 'date' && value is DateTime) {
            return '${value.year}-${value.month}-${value.day}';
          }
          return ':$key';
        });

        Lang.addParameterReplacer((key, value, params) {
          if (key == 'time' && value is DateTime) {
            return '${value.hour}:${value.minute}';
          }
          return ':$key';
        });

        final now = DateTime(2025, 8, 30, 14, 30);
        final result = Lang.t('date', parameters: {'date': now, 'time': now});

        expect(result, equals('Date: 2025-8-30, Time: 14:30'));
      });
    });

    group('Concurrency - Request Locale', () {
      setUp(() {
        provider = FileLangProvider();
        Lang.use(provider);
        Lang.clearCache();
      });

      test('should handle concurrent requests with different locales',
          () async {
        provider.loadNamespace('', 'en', {'greeting': 'Hello'});
        provider.loadNamespace('', 'fr', {'greeting': 'Bonjour'});
        provider.loadNamespace('', 'es', {'greeting': 'Hola'});

        final request1 = Request(FakeHttpRequest());
        final request2 = Request(FakeHttpRequest());
        final request3 = Request(FakeHttpRequest());

        // Simulate concurrent requests
        final results = await Future.wait([
          RequestContext.run(request1, () async {
            Lang.setRequestLocale('en');
            return Lang.t('greeting');
          }),
          RequestContext.run(request2, () async {
            Lang.setRequestLocale('fr');
            return Lang.t('greeting');
          }),
          RequestContext.run(request3, () async {
            Lang.setRequestLocale('es');
            return Lang.t('greeting');
          }),
        ]);

        expect(results, contains('Hello'));
        expect(results, contains('Bonjour'));
        expect(results, contains('Hola'));
      });

      test('should maintain request isolation', () {
        provider.loadNamespace('', 'en', {'message': 'English'});
        provider.loadNamespace('', 'fr', {'message': 'French'});

        final request1 = Request(FakeHttpRequest());
        final request2 = Request(FakeHttpRequest());

        final result1 = RequestContext.run(request1, () {
          Lang.setRequestLocale('en');
          return Lang.t('message');
        });

        final result2 = RequestContext.run(request2, () {
          Lang.setRequestLocale('fr');
          return Lang.t('message');
        });

        expect(result1, equals('English'));
        expect(result2, equals('French'));
      });

      test('should handle nested request contexts', () {
        provider.loadNamespace('', 'en', {'level': 'English'});
        provider.loadNamespace('', 'fr', {'level': 'French'});

        final request = Request(FakeHttpRequest());

        final result = RequestContext.run(request, () {
          Lang.setRequestLocale('en');

          // Simulate nested operation with different locale
          final nestedResult =
              RequestContext.run(Request(FakeHttpRequest()), () {
            Lang.setRequestLocale('fr');
            return Lang.t('level');
          });

          final outerResult = Lang.t('level');

          return {'outer': outerResult, 'inner': nestedResult};
        });

        expect(result['outer'], equals('English'));
        expect(result['inner'], equals('French'));
      });

      test('should handle rapid locale switching in concurrent requests',
          () async {
        provider.loadNamespace('', 'en', {'text': 'English'});
        provider.loadNamespace('', 'de', {'text': 'German'});

        // Test with just 2 requests to ensure isolation
        final request1 = Request(FakeHttpRequest());
        final request2 = Request(FakeHttpRequest());

        final results = await Future.wait([
          RequestContext.run(request1, () async {
            Lang.setRequestLocale('en');
            return Lang.t('text');
          }),
          RequestContext.run(request2, () async {
            Lang.setRequestLocale('de');
            return Lang.t('text');
          }),
        ]);

        expect(results, contains('English'));
        expect(results, contains('German'));
      });
    });

    group('Integration Tests', () {
      test('should work end-to-end with Khadem facade', () {
        provider.loadNamespace('', 'en', {
          'welcome': 'Welcome :name to :app',
          'items': 'item|items',
          'fields.email': 'Email Address',
        });
        provider.setLocale('en');

        // Test translation
        expect(
          Lang.t('welcome', parameters: {'name': 'Alice', 'app': 'Khadem'}),
          equals('Welcome Alice to Khadem'),
        );

        // Test pluralization
        expect(Lang.choice('items', 1), equals('item'));
        expect(Lang.choice('items', 2), equals('items'));

        // Test field translation
        expect(Lang.getField('email'), equals('Email Address'));

        // Test existence
        expect(Lang.has('welcome'), isTrue);
        expect(Lang.has('nonexistent'), isFalse);
      });

      test('should handle complex scenarios', () {
        provider.loadNamespace('', 'en', {
          'cart': 'Your cart has :count :item',
          'item': 'item|items',
        });
        provider.loadNamespace('checkout', 'en', {
          'total': 'Total: :amount',
          'currency': '\$',
        });
        provider.setLocale('en');

        // Complex parameter replacement with pluralization
        Lang.addParameterReplacer((key, value, params) {
          if (key == 'item') {
            final count = params['count'] as int;
            return Lang.choice('item', count);
          }
          return ':$key';
        });

        final result = Lang.t('cart', parameters: {'count': 3, 'item': 'item'});
        expect(result, equals('Your cart has 3 items'));

        // Namespaced translation
        final total = Lang.t('total',
            namespace: 'checkout', parameters: {'amount': '29.99'},);
        expect(total, equals('Total: 29.99'));
      });
    });
  });
}
