#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import "AppsFlyerAttribution.h"
#import <objc/message.h>

@interface AppsFlyerPlugin : CDVPlugin <UIApplicationDelegate, AppsFlyerLibDelegate, AppsFlyerDeepLinkDelegate>
- (void)resumeSDK:(CDVInvokedUrlCommand *)command;
- (void)getAppsFlyerUID:(CDVInvokedUrlCommand*)command;
- (void)onConversionDataSuccess:(NSDictionary*) installData;
- (void)onConversionDataFail:(NSError *) error;
- (void)onAppOpenAttribution:(NSDictionary*) attributionData;
- (void)onAppOpenAttributionFailure:(NSError *)_errorMessage;
- (void)didResolveDeepLink:(AppsFlyerDeepLinkResult* _Nonnull) result;
- (void)handleOpenUrl:(CDVInvokedUrlCommand *)url;
- (void)Stop:(CDVInvokedUrlCommand *) command;
- (void)setAppInviteOneLinkID:(CDVInvokedUrlCommand *)command;
- (void)generateInviteLink:(CDVInvokedUrlCommand*)command;
- (void)logCrossPromotionImpression:(CDVInvokedUrlCommand *)command;
- (void)logCrossPromotionAndOpenStore:(CDVInvokedUrlCommand *)command;
- (void)setDisableAdvertisingIdentifier:(CDVInvokedUrlCommand *)command;
- (void)disableCollectASA:(CDVInvokedUrlCommand *)command;
- (void)setOneLinkCustomDomains:(CDVInvokedUrlCommand *)command;
- (void)validateAndLogInAppPurchase: (CDVInvokedUrlCommand*)command;
- (void)setUseReceiptValidationSandbox:(CDVInvokedUrlCommand*)command;

@end

// Appsflyer JS objects
#define afDevKey                        @"devKey"
#define afAppId                         @"appId"
#define afwaitForATTUserAuthorization   @"waitForATTUserAuthorization"
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
#define afUiBrandDomain                 @"brandDomain"

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

//RECEIPT VALIDATION
#define afProductIdentifier                     @"productIdentifier"
#define afTransactionId                         @"transactionId"
#define afPrice                                 @"price"
#define afCurrency                              @"currency"
#define afAdditionalParameters                  @"additionalParameters"
#define afProductId                             @"productId"
#define afPurchaseType                          @"purchaseType"
static NSString *const NO_PARAMETERS_ERROR    = @"No purchase parameters found";
static NSString *const VALIDATE_SUCCESS       = @"In-App Purchase Validation success";

//Set custom domains
#define afNoDomains @"no domains in the domains array"
