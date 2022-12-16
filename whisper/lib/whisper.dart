
import 'whisper_platform_interface.dart';

class Whisper {
  Future<String?> getPlatformVersion() {
    return WhisperPlatform.instance.getPlatformVersion();
  }
}
