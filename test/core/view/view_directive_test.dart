import 'package:khadem/src/core/lang/file_lang_provider.dart';
import 'package:khadem/src/core/lang/lang.dart';
import 'package:khadem/src/core/view/directives/lang_directive.dart';
import 'package:test/test.dart';

void main() {
  group('LangDirective Tests', () {
    late LangDirective directive;
    late FileLangProvider provider;

    setUp(() {
      directive = LangDirective();
      provider = FileLangProvider();
      Lang.use(provider);

      // Set up some test translations
      provider.loadNamespace('', 'en', {
        'greeting': 'Hello :name!',
        'welcome': 'Welcome to :app',
        'items': 'item|items',
        'messages.count': 'You have :count messages',
      });
      provider.loadNamespace('fields', 'en', {
        'name': 'Full Name',
        'email': 'Email Address',
      });
      provider.loadNamespace('messages', 'en', {
        'count': 'You have :count messages',
      });
      provider.setLocale('en');
    });

    tearDown(() {
      Lang.clearCache();
    });

    test('should process basic @lang directive', () async {
      const template = 'Message: @lang("greeting")';
      const context = <String, dynamic>{};

      final result = await directive.apply(template, context);

      expect(result, equals('Message: Hello :name!'));
    });

    test('should process @lang directive with parameters', () async {
      const template = '@lang("greeting", parameters: {"name": "Alice"})';
      const context = <String, dynamic>{};

      final result = await directive.apply(template, context);

      expect(result, equals('Hello Alice!'));
    });

    test('should process @lang directive with context variables', () async {
      const template = '@lang("greeting", parameters: {"name": userName})';
      const context = <String, dynamic>{'userName': 'Bob'};

      final result = await directive.apply(template, context);

      expect(result, equals('Hello Bob!'));
    });

    test('should process @choice directive', () async {
      const template = '@choice("items", 1)';
      const context = <String, dynamic>{};

      final result = await directive.apply(template, context);

      expect(result, equals('item'));
    });

    test('should process @choice directive with plural', () async {
      const template = '@choice("items", 3)';
      const context = <String, dynamic>{};

      final result = await directive.apply(template, context);

      expect(result, equals('items'));
    });

    test('should process @choice directive with parameters', () async {
      const template = '@choice("messages.count", messageCount)';
      const context = <String, dynamic>{'messageCount': 5};

      final result = await directive.apply(template, context);

      expect(result, equals('You have 5 messages'));
    });

    test('should process @field directive', () async {
      const template = 'Name: @field("name")';
      const context = <String, dynamic>{};

      final result = await directive.apply(template, context);

      expect(result, equals('Name: Full Name'));
    });

    test('should handle multiple directives in template', () async {
      const template = '''
        @lang("welcome", parameters: {"app": appName})
        You have @choice("items", itemCount) in your cart.
        Full name: @field("name")
      ''';
      const context = <String, dynamic>{
        'appName': 'MyApp',
        'itemCount': 2,
      };

      final result = await directive.apply(template, context);

      expect(result, contains('Welcome to MyApp'));
      expect(result, contains('items'));
      expect(result, contains('Full Name'));
    });

    test('should handle quoted strings in parameters', () async {
      const template = '@lang("greeting", parameters: {"name": "John"})';
      const context = <String, dynamic>{};

      final result = await directive.apply(template, context);

      expect(result, equals('Hello John!'));
    });

    test('should handle single quotes', () async {
      const template = "@lang('greeting', parameters: {'name': 'Jane'})";
      const context = <String, dynamic>{};

      final result = await directive.apply(template, context);

      expect(result, equals('Hello Jane!'));
    });

    test('should handle missing translation gracefully', () async {
      const template = '@lang("nonexistent")';
      const context = <String, dynamic>{};

      final result = await directive.apply(template, context);

      expect(result, equals('nonexistent'));
    });

    test('should handle complex parameter maps', () async {
      const template =
          '@lang("welcome", parameters: {"app": "TestApp", "version": 2})';
      const context = <String, dynamic>{};

      final result = await directive.apply(template, context);

      expect(result, equals('Welcome to TestApp'));
    });
  });
}
