#import "MediaPickerBuilderPlugin.h"
#import <media_picker_builder/media_picker_builder-Swift.h>

@implementation MediaPickerBuilderPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMediaPickerBuilderPlugin registerWithRegistrar:registrar];
}
@end
