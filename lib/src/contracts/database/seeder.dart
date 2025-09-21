/// Represents a single data seeder class.
abstract class Seeder {
  /// Run the seeding logic.
  Future<void> run();

  String get name => runtimeType.toString();
}