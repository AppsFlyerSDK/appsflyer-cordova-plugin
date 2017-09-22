#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import "AppsFlyerTracker.h"


@interface AppsFlyerPlugin : CDVPlugin <UIApplicationDelegate, AppsFlyerTrackerDelegate>
- (void)initSdk:(CDVInvokedUrlCommand*)command;
- (void)resumeSDK:(CDVInvokedUrlCommand *)command;
- (void)setCurrencyCode:(CDVInvokedUrlCommand*)command;
- (void)setAppUserId:(CDVInvokedUrlCommand*)command;
- (void)getAppsFlyerUID:(CDVInvokedUrlCommand*)command;
- (void)sendTrackingWithEvent:(CDVInvokedUrlCommand*)command;
- (void)onConversionDataReceived:(NSDictionary*) installData;
- (void)onConversionDataRequestFailure:(NSError *) error;
- (void)trackEvent:(CDVInvokedUrlCommand*)command;
- (void)registerUninstall:(CDVInvokedUrlCommand*)command;
- (void)handleOpenUrl:(CDVInvokedUrlCommand *)url;
- (void)setDeviceTrackingDisabled:(CDVInvokedUrlCommand *)command;

@end




// Appsflyer JS objects
#define afDevKey                        @"devKey"
#define afAppId                         @"appId"
#define afIsDebug                       @"isDebug"

// Appsflyer native objects
#define afConversionData                @"onInstallConversionDataListener"
#define afOnInstallConversionData       @"onInstallConversionData"
#define afSuccess                       @"success"
#define afFailure                       @"failure"
#define afOnAttributionFailure          @"onAttributionFailure"
#define afOnAppOpenAttribution          @"onAppOpenAttribution"
#define afOnInstallConversionFailure    @"onInstallConversionFailure"
#define afOnInstallConversionDataLoaded @"onInstallConversionDataLoaded"