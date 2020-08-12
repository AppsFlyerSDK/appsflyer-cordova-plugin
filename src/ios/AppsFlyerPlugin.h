#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import "AppsFlyerLib.h"


@interface AppsFlyerPlugin : CDVPlugin <UIApplicationDelegate, AppsFlyerLibDelegate>
// @interface AppsFlyerPlugin : CDVPlugin <UIApplicationDelegate, AppsFlyerTrackerDelegate>
- (void)initSdk:(CDVInvokedUrlCommand*)command;
- (void)resumeSDK:(CDVInvokedUrlCommand *)command;
- (void)setCurrencyCode:(CDVInvokedUrlCommand*)command;
- (void)setAppUserId:(CDVInvokedUrlCommand*)command;
- (void)getAppsFlyerUID:(CDVInvokedUrlCommand*)command;
- (void)onConversionDataSuccess:(NSDictionary*) installData;
- (void)onConversionDataFail:(NSError *) error;
- (void)logEvent:(CDVInvokedUrlCommand*)command;
- (void)registerUninstall:(CDVInvokedUrlCommand*)command;
- (void)handleOpenUrl:(CDVInvokedUrlCommand *)url;
- (void)deviceLoggingDisabled:(CDVInvokedUrlCommand *)command;
- (void)Stop:(CDVInvokedUrlCommand *) command;
- (void)setAppInviteOneLinkID:(CDVInvokedUrlCommand *)command;
- (void)generateInviteLink:(CDVInvokedUrlCommand*)command;
- (void)logCrossPromotionImpression:(CDVInvokedUrlCommand *)command;
- (void)logCrossPromotionAndOpenStore:(CDVInvokedUrlCommand *)command;
- (void)registerOnAppOpenAttribution:(CDVInvokedUrlCommand *)command;
- (void)getSdkVersion:(CDVInvokedUrlCommand *)command;
@end




// Appsflyer JS objects
#define afDevKey                        @"devKey"
#define afAppId                         @"appId"
#define afTimeToWaitForAdvertiserID     @"timeToWaitForAdvertiserID"
#define afIsDebug						@"isDebug"
#define afSanboxUninstall				@"useUninstallSandbox"

// User Invites, Cross Promotion
#define afCpAppID                       @"crossPromotedAppId"
#define afUiChannel                     @"channel"
#define afUiCampaign                    @"campaign"
#define afUiRefName                     @"referrerName"
#define afUiImageUrl                    @"referrerImageUrl"
#define afUiCustomerID                  @"customerID"
#define afUiBaseDeepLink                @"baseDeepLink"

// Appsflyer native objects
#define afConversionData                @"onInstallConversionDataListener"
#define afOnInstallConversionData       @"onInstallConversionData"
#define afSuccess                       @"success"
#define afFailure                       @"failure"
#define afOnAttributionFailure          @"onAttributionFailure"
#define afOnAppOpenAttribution          @"onAppOpenAttribution"
#define afOnInstallConversionFailure    @"onInstallConversionFailure"
#define afOnInstallConversionDataLoaded @"onInstallConversionDataLoaded"
