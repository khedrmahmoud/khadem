import 'dart:async';
import 'dart:io';

import '../config/mail_config.dart';

/// SMTP diagnostics utility for troubleshooting connection issues.
class SmtpDiagnostics {
  /// Tests SMTP connectivity without authentication.
  ///
  /// Returns a diagnostic report with connection details.
  static Future<SmtpDiagnosticReport> testConnection(SmtpConfig config) async {
    final report = SmtpDiagnosticReport(config);
    final stopwatch = Stopwatch()..start();

    try {
      // Test basic network connectivity
      report.checkingHost = true;
      final addresses = await InternetAddress.lookup(config.host);
      report.hostResolved = addresses.isNotEmpty;
      report.resolvedAddresses = addresses.map((a) => a.address).toList();

      if (!report.hostResolved) {
        report.error = 'Failed to resolve hostname ${config.host}';
        return report;
      }

      // Test port connectivity
      report.checkingPort = true;
      Socket? socket;
      SecureSocket? secureSocket;

      try {
        if (config.encryption == 'ssl') {
          // Try SSL connection
          secureSocket = await SecureSocket.connect(
            config.host,
            config.port,
            timeout: Duration(seconds: config.timeout),
          ).timeout(
            Duration(seconds: config.timeout),
            onTimeout: () => throw TimeoutException(
              'Connection timeout after ${config.timeout} seconds',
            ),
          );
          report.portOpen = true;
          report.sslSupported = true;
        } else {
          // Try plain connection
          socket = await Socket.connect(
            config.host,
            config.port,
            timeout: Duration(seconds: config.timeout),
          ).timeout(
            Duration(seconds: config.timeout),
            onTimeout: () => throw TimeoutException(
              'Connection timeout after ${config.timeout} seconds',
            ),
          );
          report.portOpen = true;

          // Check if STARTTLS is available
          if (config.encryption == 'tls') {
            report.tlsSupported = true;
          }
        }

        report.connectionTime = stopwatch.elapsedMilliseconds;
        report.success = true;
      } on SocketException catch (e) {
        report.error = 'Socket error: ${e.message}';
        report.portOpen = false;
      } on TimeoutException {
        report.error = 'Connection timeout after ${config.timeout} seconds';
        report.portOpen = false;
      } catch (e) {
        report.error = 'Connection error: $e';
        report.portOpen = false;
      } finally {
        await socket?.close();
        await secureSocket?.close();
      }
    } on SocketException catch (e) {
      report.error = 'Failed to resolve host: ${e.message}';
      report.hostResolved = false;
    } catch (e) {
      report.error = 'Diagnostic error: $e';
    } finally {
      stopwatch.stop();
      report.totalTime = stopwatch.elapsedMilliseconds;
    }

    return report;
  }

  /// Generates a detailed diagnostic message.
  static String generateDiagnosticMessage(SmtpDiagnosticReport report) {
    final buffer = StringBuffer();
    buffer.writeln('=== SMTP Diagnostic Report ===');
    buffer.writeln('Host: ${report.config.host}');
    buffer.writeln('Port: ${report.config.port}');
    buffer.writeln('Encryption: ${report.config.encryption}');
    buffer.writeln('Timeout: ${report.config.timeout}s');
    buffer.writeln();

    if (report.hostResolved) {
      buffer.writeln('✓ Host resolved: ${report.resolvedAddresses.join(', ')}');
    } else {
      buffer.writeln('✗ Host resolution failed');
    }

    if (report.portOpen) {
      buffer.writeln('✓ Port ${report.config.port} is open');
      buffer.writeln('  Connection time: ${report.connectionTime}ms');
    } else {
      buffer.writeln('✗ Port ${report.config.port} is closed or unreachable');
    }

    if (report.sslSupported) {
      buffer.writeln('✓ SSL/TLS connection successful');
    }

    if (report.error != null) {
      buffer.writeln();
      buffer.writeln('Error: ${report.error}');
    }

    buffer.writeln();
    buffer.writeln('Recommendations:');

    if (!report.hostResolved) {
      buffer.writeln('• Check that the SMTP hostname is correct');
      buffer.writeln('• Verify your DNS settings');
      buffer.writeln('• Check your internet connection');
    } else if (!report.portOpen) {
      buffer.writeln('• Verify the SMTP port is correct');
      buffer.writeln('  - Common ports: 25 (plain), 587 (TLS), 465 (SSL)');
      buffer.writeln('• Check firewall settings (allow outbound on port ${report.config.port})');
      buffer.writeln('• Verify the SMTP server is running');
      buffer.writeln('• Try increasing the timeout value');
    } else if (report.success) {
      buffer.writeln('• Connection successful! The SMTP server is reachable.');
      buffer.writeln('• If authentication still fails, check username/password');
    }

    buffer.writeln();
    buffer.writeln('Total diagnostic time: ${report.totalTime}ms');

    return buffer.toString();
  }

  /// Quick connectivity test with automatic reporting.
  static Future<void> quickTest(SmtpConfig config) async {
    print('Running SMTP diagnostics...\n');
    final report = await testConnection(config);
    print(generateDiagnosticMessage(report));
  }
}

/// SMTP diagnostic report.
class SmtpDiagnosticReport {
  final SmtpConfig config;
  bool checkingHost = false;
  bool hostResolved = false;
  List<String> resolvedAddresses = [];
  bool checkingPort = false;
  bool portOpen = false;
  bool sslSupported = false;
  bool tlsSupported = false;
  int connectionTime = 0;
  int totalTime = 0;
  bool success = false;
  String? error;

  SmtpDiagnosticReport(this.config);

  /// Returns true if the connection is likely to work.
  bool get isHealthy => hostResolved && portOpen && error == null;

  /// Returns a summary of the diagnostic.
  String get summary {
    if (success) return 'Connection successful';
    if (!hostResolved) return 'Host resolution failed';
    if (!portOpen) return 'Port unreachable';
    if (error != null) return error!;
    return 'Unknown issue';
  }
}
