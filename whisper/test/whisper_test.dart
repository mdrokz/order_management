import 'package:flutter_test/flutter_test.dart';
import 'package:whisper/whisper.dart';
import 'package:whisper/whisper_platform_interface.dart';
import 'package:whisper/whisper_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWhisperPlatform
    with MockPlatformInterfaceMixin
    implements WhisperPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final WhisperPlatform initialPlatform = WhisperPlatform.instance;

  test('$MethodChannelWhisper is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWhisper>());
  });

  test('getPlatformVersion', () async {
    Whisper whisperPlugin = Whisper();
    MockWhisperPlatform fakePlatform = MockWhisperPlatform();
    WhisperPlatform.instance = fakePlatform;

    expect(await whisperPlugin.getPlatformVersion(), '42');
  });
}
