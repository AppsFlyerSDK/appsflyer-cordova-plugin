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

@end
