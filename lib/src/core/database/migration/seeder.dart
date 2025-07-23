import 'package:khadem/src/application/khadem.dart';

import '../../../contracts/database/seeder.dart';

/// Manages and runs seeders.
class SeederManager {
  final List<Seeder> _seeders = [];

  void register(Seeder seeder) {
    _seeders.add(seeder);
  }

  void registerAll(List<Seeder> seeders) {
    _seeders.addAll(seeders);
  }

  Future<void> runAll() async {
    for (final seeder in _seeders) {
      Khadem.logger.info('Running seeder: ${seeder.name}');
      await seeder.run();
    }
  }

  Future<void> run(String name) async {
    final seeder = _seeders.firstWhere(
      (s) => s.name == name,
      orElse: () => throw Exception('Seeder "$name" not found.'),
    );
    await seeder.run();
  }
}
