import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:khadem/src/modules/mail/config/mail_config.dart';
import 'package:khadem/src/modules/mail/core/mail_address.dart';
import 'package:khadem/src/modules/mail/core/mail_attachment.dart';
import 'package:khadem/src/modules/mail/core/mail_embedded_image.dart';
import 'package:khadem/src/modules/mail/core/mail_message.dart';
import 'package:khadem/src/modules/mail/drivers/mailgun_transport.dart';
import 'package:khadem/src/modules/mail/exceptions/mail_exception.dart';

import 'mailgun_transport_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('MailgunTransport', () {
    late MailgunConfig config;
    late MockClient mockClient;
    late MailgunTransport transport;

    setUp(() {
      config = MailgunConfig(
        domain: 'mg.example.com',
        apiKey: 'key-test123',
        endpoint: 'https://api.mailgun.net',
      );
      mockClient = MockClient();
      transport = MailgunTransport(config, client: mockClient);
    });

    test('has correct name', () {
      expect(transport.name, equals('mailgun'));
    });

    test('sends simple email successfully', () async {
      // Arrange
      final message = MailMessage(
        from: MailAddress('sender@example.com'),
        to: [MailAddress('recipient@example.com')],
        subject: 'Test Subject',
        textBody: 'Test body',
      );

      when(mockClient.send(any)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value([]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      // Act
      final result = await transport.send(message);

      // Assert
      expect(result, isTrue);
      verify(mockClient.send(any)).called(1);
    });

    test('sends email with HTML body', () async {
      // Arrange
      final message = MailMessage(
        from: MailAddress('sender@example.com'),
        to: [MailAddress('recipient@example.com')],
        subject: 'Test Subject',
        htmlBody: '<p>Test body</p>',
      );

      when(mockClient.send(any)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value([]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      // Act
      final result = await transport.send(message);

      // Assert
      expect(result, isTrue);
    });

    test('sends email with both text and HTML body', () async {
      // Arrange
      final message = MailMessage(
        from: MailAddress('sender@example.com'),
        to: [MailAddress('recipient@example.com')],
        subject: 'Test Subject',
        textBody: 'Test body',
        htmlBody: '<p>Test body</p>',
      );

      when(mockClient.send(any)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value([]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      // Act
      final result = await transport.send(message);

      // Assert
      expect(result, isTrue);
    });

    test('sends email with CC and BCC', () async {
      // Arrange
      final message = MailMessage(
        from: MailAddress('sender@example.com'),
        to: [MailAddress('recipient@example.com')],
        cc: [MailAddress('cc@example.com')],
        bcc: [MailAddress('bcc@example.com')],
        subject: 'Test Subject',
        textBody: 'Test body',
      );

      when(mockClient.send(any)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value([]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      // Act
      final result = await transport.send(message);

      // Assert
      expect(result, isTrue);
    });

    test('sends email with reply-to', () async {
      // Arrange
      final message = MailMessage(
        from: MailAddress('sender@example.com'),
        to: [MailAddress('recipient@example.com')],
        replyTo: MailAddress('replyto@example.com'),
        subject: 'Test Subject',
        textBody: 'Test body',
      );

      when(mockClient.send(any)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value([]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      // Act
      final result = await transport.send(message);

      // Assert
      expect(result, isTrue);
    });

    test('sends email with custom headers', () async {
      // Arrange
      final message = MailMessage(
        from: MailAddress('sender@example.com'),
        to: [MailAddress('recipient@example.com')],
        subject: 'Test Subject',
        textBody: 'Test body',
        headers: {'X-Custom-Header': 'value'},
      );

      when(mockClient.send(any)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value([]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      // Act
      final result = await transport.send(message);

      // Assert
      expect(result, isTrue);
    });

    test('sends email with priority', () async {
      // Arrange
      final message = MailMessage(
        from: MailAddress('sender@example.com'),
        to: [MailAddress('recipient@example.com')],
        subject: 'Test Subject',
        textBody: 'Test body',
        priority: 1,
      );

      when(mockClient.send(any)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value([]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      // Act
      final result = await transport.send(message);

      // Assert
      expect(result, isTrue);
    });

    test('throws exception when API returns error', () async {
      // Arrange
      final message = MailMessage(
        from: MailAddress('sender@example.com'),
        to: [MailAddress('recipient@example.com')],
        subject: 'Test Subject',
        textBody: 'Test body',
      );

      when(mockClient.send(any)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value('{"message": "API Error"}'.codeUnits),
          400,
          headers: {'content-type': 'application/json'},
        ),
      );

      // Act & Assert
      expect(
        () => transport.send(message),
        throwsA(isA<MailTransportException>()),
      );
    });

    test('throws exception when network error occurs', () async {
      // Arrange
      final message = MailMessage(
        from: MailAddress('sender@example.com'),
        to: [MailAddress('recipient@example.com')],
        subject: 'Test Subject',
        textBody: 'Test body',
      );

      when(mockClient.send(any)).thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => transport.send(message),
        throwsA(isA<MailTransportException>()),
      );
    });

    test('test connection returns true when successful', () async {
      // Arrange
      when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
        (_) async => http.Response('{"domain": "mg.example.com"}', 200),
      );

      // Act
      final result = await transport.test();

      // Assert
      expect(result, isTrue);
    });

    test('test connection returns false when failed', () async {
      // Arrange
      when(mockClient.get(any, headers: anyNamed('headers'))).thenThrow(
        Exception('Connection failed'),
      );

      // Act
      final result = await transport.test();

      // Assert
      expect(result, isFalse);
    });

    test('validates message before sending', () async {
      // Arrange
      final message = MailMessage(
        from: MailAddress('sender@example.com'),
        to: [], // Empty recipients
        subject: 'Test Subject',
        textBody: 'Test body',
      );

      // Act & Assert
      expect(
        () => transport.send(message),
        throwsA(isA<MailValidationException>()),
      );
    });

    test('uses default from address when not provided', () async {
      // Arrange
      final message = MailMessage(
        to: [MailAddress('recipient@example.com')],
        subject: 'Test Subject',
        textBody: 'Test body',
      );

      when(mockClient.send(any)).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value([]),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      // Act
      final result = await transport.send(message);

      // Assert
      expect(result, isTrue);
    });

    test('disposes HTTP client properly', () {
      // Act
      transport.dispose();

      // Assert - should not throw
      expect(true, isTrue);
    });
  });
}
