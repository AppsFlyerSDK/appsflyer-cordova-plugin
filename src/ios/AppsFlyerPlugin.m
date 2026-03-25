#import "AppsFlyerPlugin.h"
#import "AppsFlyerAttribution.h"
#import "AppDelegate.h"

@implementation AppsFlyerPlugin

// Conversion attribution is delivered via AppsFlyerSwiftPlugin (RPC). Required delegate stubs:
-(void)onConversionDataSuccess:(NSDictionary*) installData {
    (void)installData;
}

-(void)onConversionDataFail:(NSError *) errorMessage {
    (void)errorMessage;
}

// App-open attribution & UDL are delivered to JS via AppsFlyerSwiftPlugin (AFRPC bridge events).
- (void)onAppOpenAttribution:(NSDictionary*) attributionData {
    (void)attributionData;
}

- (void)onAppOpenAttributionFailure:(NSError *)_errorMessage {
    (void)_errorMessage;
}

- (void)didResolveDeepLink:(AppsFlyerDeepLinkResult* _Nonnull) result {
    (void)result;
}

/**
*  Log Deep linking
*/
- (void) handleOpenUrl:(CDVInvokedUrlCommand*)command {
    NSURL *url = [NSURL URLWithString:
        [[command.arguments objectAtIndex:0]
            stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[AppsFlyerLib shared] handleOpenUrl:url options:nil];
}

/**
 * AppsFlyer SDK dynamically loads the Apple iAd.framework. This framework is required to record and measure the performance of Apple Search Ads in your app.
 * If you don't want AppsFlyer to dynamically load this framework, set this property to true.
 */
- (void)disableCollectASA:(CDVInvokedUrlCommand*)command {
    BOOL isDisableBool = NO;
    id isDisablevalue = [command.arguments objectAtIndex:0];
    if ([isDisablevalue isKindOfClass:[NSNumber class]]) {
        isDisableBool = [(NSNumber*)isDisablevalue boolValue];
        [[AppsFlyerLib shared] setDisableCollectASA:isDisableBool];
    }
    CDVPluginResult *pluginResult = [CDVPluginResult
                                     resultWithStatus: CDVCommandStatus_OK
                                     ];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setUseReceiptValidationSandbox:(CDVInvokedUrlCommand*)command {
    BOOL isSandbox = [command.arguments objectAtIndex:0];
    [AppsFlyerLib shared].useReceiptValidationSandbox = isSandbox;

    CDVPluginResult *pluginResult = [CDVPluginResult
                                     resultWithStatus: CDVCommandStatus_OK messageAsString: isSandbox? @"Sandbox set to true" : @"Sandbox set to false"
                                     ];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)addPushNotificationDeepLinkPath:(CDVInvokedUrlCommand*)command {
    NSArray* path = [command argumentAtIndex:0];
    if (path == nil || path.count == 0) {
        return;
    }
    [[AppsFlyerLib shared] addPushNotificationDeepLinkPath:path];
    NSLog(@"[DEBUG] AppsFlyer: %@", path);

}

- (void)setResolveDeepLinkURLs:(CDVInvokedUrlCommand*)command {
    NSArray* urls = [command argumentAtIndex:0];
    if (urls == nil || urls.count == 0) {
        return;
    }
    [AppsFlyerLib shared].resolveDeepLinkURLs = urls;
    NSLog(@"[DEBUG] AppsFlyer: %@", urls);
}

@end
