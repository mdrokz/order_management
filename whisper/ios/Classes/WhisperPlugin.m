#import "WhisperPlugin.h"
#if __has_include(<whisper/whisper-Swift.h>)
#import <whisper/whisper-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "whisper-Swift.h"
#endif

@implementation WhisperPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftWhisperPlugin registerWithRegistrar:registrar];
}
@end
