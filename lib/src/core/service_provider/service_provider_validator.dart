import '../../contracts/provider/service_provider.dart';

/// Handles validation of service providers.
class ServiceProviderValidator {
  /// Validates a single provider.
  bool validateProvider(ServiceProvider provider) {
    // Basic validation - can be extended with more complex checks
    return true; // Provider is non-nullable, so always valid at this level
  }

  /// Validates multiple providers.
  List<String> validateProviders(List<ServiceProvider> providers) {
    final errors = <String>[];

    for (var i = 0; i < providers.length; i++) {
      final provider = providers[i];
      if (!validateProvider(provider)) {
        errors.add('Provider at index $i is invalid');
      }
    }

    // Check for duplicate providers (if needed)
    final uniqueProviders = providers.toSet();
    if (uniqueProviders.length != providers.length) {
      errors.add('Duplicate providers found in the list');
    }

    return errors;
  }

  /// Checks if all providers in a list are valid.
  bool areAllValid(List<ServiceProvider> providers) {
    return validateProviders(providers).isEmpty;
  }

  /// Validates provider dependencies (placeholder for future implementation).
  List<String> validateDependencies(List<ServiceProvider> providers) {
    // This could be extended to check for circular dependencies
    // or missing dependencies between providers
    return [];
  }
}
