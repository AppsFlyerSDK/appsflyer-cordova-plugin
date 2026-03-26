#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import "AppsFlyerAttribution.h"
#import <objc/message.h>

@interface AppsFlyerPlugin : CDVPlugin <UIApplicationDelegate, AppsFlyerLibDelegate, AppsFlyerDeepLinkDelegate>
- (void)resumeSDK:(CDVInvokedUrlCommand *)command;
- (void)onConversionDataSuccess:(NSDictionary*) installData;
- (void)onConversionDataFail:(NSError *) error;
- (void)onAppOpenAttribution:(NSDictionary*) attributionData;
- (void)onAppOpenAttributionFailure:(NSError *)_errorMessage;
- (void)didResolveDeepLink:(AppsFlyerDeepLinkResult* _Nonnull) result;

@end

// Appsflyer JS objects
#define afDevKey                        @"devKey"
#define afAppId                         @"appId"
#define afwaitForATTUserAuthorization   @"waitForATTUserAuthorization"
#define afIsDebug						@"isDebug"
#define afSanboxUninstall				@"useUninstallSandbox"

// Appsflyer native objects
#define afConversionData                @"onInstallConversionDataListener"
#define afOnInstallConversionData       @"onInstallConversionData"
#define afSuccess                       @"success"
#define afFailure                       @"failure"
#define afOnAttributionFailure          @"onAttributionFailure"
#define afOnAppOpenAttribution          @"onAppOpenAttribution"
#define afOnInstallConversionFailure    @"onInstallConversionFailure"
#define afOnInstallConversionDataLoaded @"onInstallConversionDataLoaded"
#define afDeepLink                      @"onDeepLinking"
#define afOnDeepLinking                 @"onDeepLinkListener"
