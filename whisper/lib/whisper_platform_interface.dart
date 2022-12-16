import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'whisper_method_channel.dart';

abstract class WhisperPlatform extends PlatformInterface {
  /// Constructs a WhisperPlatform.
  WhisperPlatform() : super(token: _token);

  static final Object _token = Object();

  static WhisperPlatform _instance = MethodChannelWhisper();

  /// The default instance of [WhisperPlatform] to use.
  ///
  /// Defaults to [MethodChannelWhisper].
  static WhisperPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WhisperPlatform] when
  /// they register themselves.
  static set instance(WhisperPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
