import 'package:khadem/src/contracts/config/config_contract.dart';
import 'package:khadem/src/contracts/logging/log_handler.dart';
import 'package:khadem/src/core/logging/log_channel_manager.dart';
import 'package:mockito/mockito.dart';

// Mock classes for logging tests
class MockConfig extends Mock implements ConfigInterface {}

class MockLogHandler extends Mock implements LogHandler {}

class MockLogChannelManager extends Mock implements LogChannelManager {}
