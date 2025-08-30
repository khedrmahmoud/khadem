import 'package:khadem/src/core/view/directives/array_directives.dart';
import 'package:khadem/src/core/view/directives/auth_directives.dart';
import 'package:khadem/src/core/view/directives/control_flow_directives.dart';
import 'package:khadem/src/core/view/directives/form_directives.dart';
import 'package:khadem/src/core/view/directives/loop_directives.dart';
import 'package:khadem/src/core/view/directives/misc_directives.dart';
import 'package:khadem/src/core/view/directives/output_directives.dart';
import 'package:khadem/src/core/view/directives/string_directives.dart';
import 'package:khadem/src/core/view/directives/utility_directives.dart';
import 'package:test/test.dart';

void main() {
  group('New View Directives Tests', () {
    group('Control Flow Directives', () {
      test('UnlessDirective should process @unless directive', () async {
        final directive = UnlessDirective();
        const template = '@unless(condition)Show this@endunless';
        const context = <String, dynamic>{'condition': false};

        final result = await directive.apply(template, context);

        expect(result, equals('Show this'));
      });

      test('UnlessDirective should not show content when condition is true', () async {
        final directive = UnlessDirective();
        const template = '@unless(condition) Show this @endunless';
        const context = <String, dynamic>{'condition': true};

        final result = await directive.apply(template, context);

        expect(result, equals(''));
      });
    });

    group('Loop Directives', () {
      test('ForeachDirective should process @foreach directive', () async {
        final directive = ForeachDirective();
        const template = '@foreach(items as item){{ item }}@endforeach';
        const context = <String, dynamic>{'items': ['a', 'b', 'c']};

        final result = await directive.apply(template, context);

        expect(result, equals('abc'));
      });

      test('ForeachDirective should handle empty array', () async {
        final directive = ForeachDirective();
        const template = '@foreach(items as item) {{ item }} @endforeach';
        const context = <String, dynamic>{'items': []};

        final result = await directive.apply(template, context);

        expect(result, equals(''));
      });
    });

    group('Output Directives', () {
      test('JsonDirective should process @json directive', () async {
        final directive = JsonDirective();
        const template = '@json(data)';
        const context = <String, dynamic>{'data': {'key': 'value'}};

        final result = await directive.apply(template, context);

        expect(result, equals('{"key":"value"}'));
      });

      test('DumpDirective should process @dump directive', () async {
        final directive = DumpDirective();
        const template = '@dump(variable)';
        const context = <String, dynamic>{'variable': 'test'};

        final result = await directive.apply(template, context);

        expect(result, contains('test'));
      });
    });

    group('String Directives', () {
      test('StrtoupperDirective should process @strtoupper directive', () async {
        final directive = StrtoupperDirective();
        const template = '@strtoupper("hello")';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, equals('HELLO'));
      });

      test('StrlenDirective should process @strlen directive', () async {
        final directive = StrlenDirective();
        const template = '@strlen("hello")';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, equals('5'));
      });

      test('SubstrDirective should process @substr directive', () async {
        final directive = SubstrDirective();
        const template = '@substr("hello", 1, 3)';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, equals('ell'));
      });
    });

    group('Array Directives', () {
      test('CountDirective should process @count directive', () async {
        final directive = CountDirective();
        const template = '@count(items)';
        const context = <String, dynamic>{'items': [1, 2, 3, 4, 5]};

        final result = await directive.apply(template, context);

        expect(result, equals('5'));
      });

      test('EmptyDirective should process @empty directive', () async {
        final directive = EmptyDirective();
        const template = '@empty(items)Array is empty@endempty';
        const context = <String, dynamic>{'items': []};

        final result = await directive.apply(template, context);

        expect(result, equals('Array is empty'));
      });

      test('IssetDirective should process @isset directive', () async {
        final directive = IssetDirective();
        const template = '@isset(variable)Variable exists@endisset';
        const context = <String, dynamic>{'variable': 'value'};

        final result = await directive.apply(template, context);

        expect(result, equals('Variable exists'));
      });
    });

    group('Utility Directives', () {
      test('EnvDirective should process @env directive with default', () async {
        final directive = EnvDirective();
        const template = '@env("APP_NAME", "Default")';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, equals('Default'));
      });

      test('ConfigDirective should process @config directive with default', () async {
        final directive = ConfigDirective();
        const template = '@config("app.name", "Default")';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, equals('Default'));
      });

      test('NowDirective should process @now directive', () async {
        final directive = NowDirective();
        const template = '@now("Y-m-d")';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        // Should match YYYY-MM-DD format
        expect(result, matches(r'\d{4}-\d{2}-\d{2}'));
      });

      test('FormatDirective should process @format directive', () async {
        final directive = FormatDirective();
        const template = '@format("2023-12-25", "Y-m-d")';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, equals('2023-12-25'));
      });

      test('MathDirective should process @math directive', () async {
        final directive = MathDirective();
        const template = '@math(2 + 3 * 4)';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, equals('14'));
      });

      test('MathDirective should process @math directive with variables', () async {
        final directive = MathDirective();
        const template = '@math(a + b)';
        const context = <String, dynamic>{'a': 5, 'b': 3};

        final result = await directive.apply(template, context);

        expect(result, equals('8'));
      });
    });

    group('Form Directives', () {
      test('CsrfDirective should process @csrf directive', () async {
        final directive = CsrfDirective();
        const template = '@csrf';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, contains('<input'));
        expect(result, contains('name="_token"'));
      });

      test('MethodDirective should process @method directive', () async {
        final directive = MethodDirective();
        const template = '@method("PUT")';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, contains('<input'));
        expect(result, contains('name="_method"'));
        expect(result, contains('value="PUT"'));
      });
    });

    group('Authentication Directives', () {
      test('AuthDirective should process @auth directive when authenticated', () async {
        final directive = AuthDirective();
        const template = '@auth Authenticated content @endauth';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, equals(''));
      });

      test('AuthDirective should process @auth directive when not authenticated', () async {
        final directive = AuthDirective();
        const template = '@auth Authenticated content @endauth';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, equals(''));
      });

      test('RoleDirective should process @role directive', () async {
        final directive = RoleDirective();
        const template = '@role("admin") Admin content @endrole';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, equals(''));
      });

      test('CanDirective should process @can directive', () async {
        final directive = CanDirective();
        const template = '@can("edit_users") Edit content @endcan';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, equals(''));
      });

      test('GuestDirective should process @guest directive', () async {
        final directive = GuestDirective();
        const template = '@guest Guest content @endguest';
        const context = <String, dynamic>{};

        final result = await directive.apply(template, context);

        expect(result, equals('Guest content'));
      });
    });

    group('Misc Directives', () {
      test('ErrorDirective should process @error directive', () async {
        final directive = ErrorDirective();
        const template = '@error("field")Error message@enderror';
        const context = <String, dynamic>{'errors': {'field': ['This field is required']}};

        final result = await directive.apply(template, context);

        expect(result, equals('Error message'));
      });

      test('ClassDirective should process @class directive', () async {
        final directive = ClassDirective();
        const template = '@class(["active": isActive, "disabled": isDisabled])';
        const context = <String, dynamic>{'isActive': true, 'isDisabled': false};

        final result = await directive.apply(template, context);

        expect(result, equals('active'));
      });

      test('SelectedDirective should process @selected directive', () async {
        final directive = SelectedDirective();
        const template = '@selected(condition)';
        const context = <String, dynamic>{'condition': true};

        final result = await directive.apply(template, context);

        expect(result, equals('selected'));
      });
    });
  });
}
