#import "FlutterWcsPlugin.h"
#if __has_include(<flutter_wcs/flutter_wcs-Swift.h>)
#import <flutter_wcs/flutter_wcs-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_wcs-Swift.h"
#endif

@implementation FlutterWcsPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterWcsPlugin registerWithRegistrar:registrar];
}
@end
