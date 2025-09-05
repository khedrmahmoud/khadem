import 'package:khadem/khadem_dart.dart';

void main() async {
  // Initialize Khadem core services
  await Khadem.registerCoreServices();
  await Khadem.boot();

  // Get the storage manager
  final storageManager = Khadem.storage;

  print('Default disk: ${storageManager.defaultDisk}');
  print('Available disks: ${storageManager.diskNames}');

  // Test accessing the public disk
  try {
    final publicDisk = storageManager.disk('public');
    print('✅ Public disk is accessible');

    // Test writing a file
    await publicDisk.writeString('test.txt', 'Hello from public disk!');
    print('✅ File written successfully');

    // Test reading the file
    final content = await publicDisk.readString('test.txt');
    print('✅ File content: $content');

    // Clean up
    await publicDisk.delete('test.txt');
    print('✅ Test file cleaned up');

  } catch (e) {
    print('❌ Error accessing public disk: $e');
  }
}
