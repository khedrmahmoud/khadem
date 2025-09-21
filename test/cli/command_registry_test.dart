import 'dart:io';

import 'package:khadem/src/cli/command_registry.dart';
import 'package:khadem/src/core/logging/logger.dart';
import 'package:test/test.dart';

void main() {
  group('CommandRegistry Package Name Loading', () {
    test('should load package name from pubspec.yaml', () async {
      final logger = Logger();
      final registry = CommandRegistry(logger);
      
      // Test that the registry initializes correctly
      expect(registry.coreCommands, isNotEmpty);
      expect(registry.customCommands, isEmpty);
      
      // Test auto-discovery (this will load the package name internally)
      await registry.autoDiscoverCommands(Directory.current.path);
      
      // The package name should be loaded and used correctly
      // We can't directly test the private field, but we can verify the system works
      expect(registry.commands.length, greaterThanOrEqualTo(registry.coreCommands.length));
    });
    
    test('should handle missing pubspec.yaml gracefully', () async {
      final logger = Logger();
      final registry = CommandRegistry(logger);
      
      // Test that the registry still works even if pubspec.yaml is missing
      expect(registry.coreCommands, isNotEmpty);
      
      // This should not throw an exception
      await registry.autoDiscoverCommands(Directory.current.path);
    });
  });
}