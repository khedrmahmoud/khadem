part of 'service_container.dart';

/// Represents a binding inside the container.
class _Binding {
  final dynamic Function(ContainerInterface) factory;
  final bool singleton;
  final bool lazy;

  dynamic _lazyInstance;

  _Binding(this.factory, {this.singleton = false, this.lazy = false});

  /// Returns the instance (cached if singleton + lazy).
  dynamic getInstance(ContainerInterface container) {
    if (singleton && lazy) {
      return _lazyInstance ??= factory(container);
    }
    return factory(container);
  }
}
