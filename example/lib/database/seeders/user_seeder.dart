import 'package:khadem/contracts.dart' show Seeder;
import 'package:khadem/khadem.dart' show Khadem;

class UserSeeder extends Seeder {
  @override
  Future<void> run() async {
    // Example seeder implementation
    Khadem.logger.info('🌱 Seeding users table...');

    // Insert sample users
    await Khadem.db.table('users').insert({
      'name': 'Admin User',
      'email': 'admin@example.com',
      'password': 'hashed_password_here', // In real app, use proper hashing
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    Khadem.logger.info('✅ Users seeded successfully');
  }
}
