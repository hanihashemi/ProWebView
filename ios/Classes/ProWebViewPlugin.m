#import "ProWebViewPlugin.h"
#import "FlutterWebView.h"

@implementation FLTProWebViewPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FLTWebViewFactory* webviewFactory =
      [[FLTWebViewFactory alloc] initWithMessenger:registrar.messenger];
  [registrar registerViewFactory:webviewFactory withId:@"com.hanihashemi.prowebview/webview"];
}

@end
