import 'package:khadem/src/core/storage/local_disk.dart';
import 'package:khadem/src/core/storage/storage_manager.dart';

void main() async {
  // Create storage manager
  final storageManager = StorageManager();

  // Register a local disk
  final localDisk = LocalDisk(basePath: './storage/app');
  storageManager.registerDisk('local', localDisk);

  // Get the disk
  final disk = storageManager.disk('local');

  // Write a text file
  await disk.writeString('hello.txt', 'Hello, Khadem Storage!');

  // Read the file
  final content = await disk.readString('hello.txt');
  print('File content: $content');

  // Check if file exists
  final exists = await disk.exists('hello.txt');
  print('File exists: $exists');

  // Write binary data
  final bytes = [72, 101, 108, 108, 111]; // "Hello" in bytes
  await disk.put('data.bin', bytes);

  // Read binary data
  final data = await disk.get('data.bin');
  print('Binary data: $data');

  // Get file size
  final size = await disk.size('hello.txt');
  print('File size: $size bytes');

  // List files (if any exist)
  final files = await disk.listFiles('.');
  print('Files in directory: $files');

  // Get file URL
  final url = disk.url('hello.txt');
  print('File URL: $url');

  // Copy file
  await disk.copy('hello.txt', 'hello_copy.txt');

  // Move file
  await disk.move('hello_copy.txt', 'hello_moved.txt');

  // Delete files
  await disk.delete('hello.txt');
  await disk.delete('data.bin');
  await disk.delete('hello_moved.txt');

  print('Storage example completed!');
}
