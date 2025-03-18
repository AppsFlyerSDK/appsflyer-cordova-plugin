#import "AppsFlyerPlugin.h"
#import "AppsFlyerAttribution.h"
#import "AppDelegate.h"
#if defined __has_include
#  if __has_include (<FBSDKAppLinkUtility.h>)
#       import <FBSDKAppLinkUtility.h>
#  endif
#endif

@implementation AppsFlyerPlugin


static NSString *const NO_DEVKEY_FOUND = @"AppsFlyer 'devKey' is missing or empty";
static NSString *const NO_APPID_FOUND  = @"'appId' is missing or empty";
static NSString *const SUCCESS         = @"Success";
static NSString *const NO_WAITING_TIME = @"You need to set waiting time for ATT";

 NSString* mConversionListener;
 NSString* mAttributionDataListener;
 NSString* mDeepLinkListener;
 NSString* mInviteListener;
 BOOL isConversionData = NO;
 BOOL isDeepLinking = NO;

- (void)pluginInitialize{}

/**
*   initialize the SDK.
*   initSdkOptions: SDK configuration
*/
- (void)initSdk:(CDVInvokedUrlCommand*)command
{
    NSDictionary* initSdkOptions = [command argumentAtIndex:0 withDefault:[NSNull null]];

    NSString* devKey = nil;
    NSString* appId = nil;
    NSNumber* waitForATTUserAuthorization;
    id shouldStartSdkValue = nil;
    id isDebugValue = nil;
    id sandboxValue = nil;
    id isDeepLinkingValue = nil;
    BOOL isDebug = NO;
    BOOL useUninstallSandbox = NO;
    BOOL shouldStartSdk = YES;


    if (![initSdkOptions isKindOfClass:[NSNull class]]) {
        // Assign values to variables
        devKey = (NSString*)[initSdkOptions objectForKey:afDevKey];
        appId = (NSString*)[initSdkOptions objectForKey:afAppId];
        waitForATTUserAuthorization = (NSNumber*)[initSdkOptions objectForKey:afwaitForATTUserAuthorization];
        isDebugValue = [initSdkOptions objectForKey:afIsDebug];
        shouldStartSdkValue = [initSdkOptions objectForKey:@"shouldStartSdk"];

        if ([isDebugValue isKindOfClass:[NSNumber class]]) {
            isDebug = [(NSNumber*)isDebugValue boolValue];
        }

        if ([shouldStartSdkValue isKindOfClass:[NSNumber class]]) {
            shouldStartSdk = [(NSNumber*)shouldStartSdkValue boolValue];
        }

        [self setShouldStartSdk:shouldStartSdk];
        sandboxValue = [initSdkOptions objectForKey:afSanboxUninstall];

        if ([sandboxValue isKindOfClass:[NSNumber class]]) {
            useUninstallSandbox = [(NSNumber*)sandboxValue boolValue];
        }

        isDeepLinkingValue = [initSdkOptions objectForKey:afOnDeepLinking];

        if ([isDeepLinkingValue isKindOfClass:[NSNumber class]]) {
            isDeepLinking = [(NSNumber*)isDeepLinkingValue boolValue];
        }
    }

    NSString* error = nil;

    // Verify dev key is not null/empty
    if (!devKey || [devKey isEqualToString:@""]) {
        error = NO_DEVKEY_FOUND;
    }

    if (!appId || [appId isEqualToString:@""]) {
        error = NO_APPID_FOUND;
    }

    // Throw an exception if the error object is not nil
    if (error != nil){
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    } else {
        if (isDeepLinking == YES) {
            [AppsFlyerLib shared].deepLinkDelegate = self;
        }

        // Initialize the SDK
        [[AppsFlyerLib shared] setPluginInfoWith:AFSDKPluginCordova pluginVersion:@"6.16.2" additionalParams:nil];
        [AppsFlyerLib shared].appleAppID = appId;
        [AppsFlyerLib shared].appsFlyerDevKey = devKey;
        [AppsFlyerLib shared].isDebug = isDebug;
        [AppsFlyerLib shared].useUninstallSandbox = useUninstallSandbox;
    }

#ifndef AFSDK_NO_IDFA
    // Here we set the time that the SDK will wait before it starts the launch. We take the time from the 'option' object in the app's index.js
    if (@available(iOS 14, *)) {
        if (waitForATTUserAuthorization != 0 && waitForATTUserAuthorization != nil) {
            [[AppsFlyerLib shared] waitForATTUserAuthorizationWithTimeoutInterval:waitForATTUserAuthorization.intValue];
        }
    }
#endif
    if (![initSdkOptions isKindOfClass:[NSNull class]]) {

        id isConversionDataValue = nil;
        isConversionDataValue = [initSdkOptions objectForKey:afConversionData];

        if ([isConversionDataValue isKindOfClass:[NSNumber class]]) {
            isConversionData = [isConversionDataValue boolValue];
        }
    }

    if (shouldStartSdk) {
        [self startSdk:command];
    }

    //post notification for the deep link object that the bridge is set and he can handle deep link
        [AppsFlyerAttribution shared].isBridgeReady = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:AF_BRIDGE_SET object:self];
        // Register for background-foreground transitions natively instead of doing this in JavaScript
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sendLaunch:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        if(isConversionData){
          CDVPluginResult* pluginResult = nil;
          mConversionListener = command.callbackId;

          [AppsFlyerLib shared].delegate = self;

          pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
          [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        }
        else{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:SUCCESS];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
}

-(void)startSdk:(CDVInvokedUrlCommand*)command {
    [self setShouldStartSdk:YES];
    [[AppsFlyerLib shared] start];
}

-(void)sendLaunch:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] postNotificationName:AF_BRIDGE_SET object:self];
    if ([self shouldStartSdk]) {
        [[AppsFlyerLib shared] start];
    }
}

/**
 Set the language of the device. The data will be displayed in Raw Data Reports
*/
- (void)setCurrentDeviceLanguage:(CDVInvokedUrlCommand*)command
{
    if ([command.arguments count] == 0) {
        return;
    }
    id isStringValue = nil;
    NSString* language;
    isStringValue = [command.arguments objectAtIndex:0];
    if ([isStringValue isKindOfClass:[NSString class]]) {
        language = ( NSString* ) isStringValue;
        [[AppsFlyerLib shared] setCurrentDeviceLanguage:language];
    }

}

- (void)sendPushNotificationData:(CDVInvokedUrlCommand*)command{
  NSDictionary* pushPayload = [command.arguments objectAtIndex:0];
  [[AppsFlyerLib shared] handlePushNotification:pushPayload];
}

/**
*   Sets new currency code. currencyId: ISO 4217 Currency Codes.
*/
- (void)setCurrencyCode:(CDVInvokedUrlCommand*)command
{
    if ([command.arguments count] == 0) {
        return;
    }

    NSString* currencyId = [command.arguments objectAtIndex:0];
    [AppsFlyerLib shared].currencyCode = currencyId;
}


- (AppsFlyerAdRevenueMediationNetworkType)getEnumValueFromString:(NSString *)mediationNetworkString {
    NSDictionary<NSString *, NSNumber *> *stringToEnumMap = @{
        @"googleadmob": @(AppsFlyerAdRevenueMediationNetworkTypeGoogleAdMob),
        @"ironsource": @(AppsFlyerAdRevenueMediationNetworkTypeIronSource),
        @"applovinmax": @(AppsFlyerAdRevenueMediationNetworkTypeApplovinMax),
        @"fyber": @(AppsFlyerAdRevenueMediationNetworkTypeFyber),
        @"appodeal": @(AppsFlyerAdRevenueMediationNetworkTypeAppodeal),
        @"Admost": @(AppsFlyerAdRevenueMediationNetworkTypeAdmost),
        @"Topon": @(AppsFlyerAdRevenueMediationNetworkTypeTopon),
        @"Tradplus": @(AppsFlyerAdRevenueMediationNetworkTypeTradplus),
        @"Yandex": @(AppsFlyerAdRevenueMediationNetworkTypeYandex),
        @"chartboost": @(AppsFlyerAdRevenueMediationNetworkTypeChartBoost),
        @"Unity": @(AppsFlyerAdRevenueMediationNetworkTypeUnity),
        @"toponpte": @(AppsFlyerAdRevenueMediationNetworkTypeToponPte),
        @"customMediation": @(AppsFlyerAdRevenueMediationNetworkTypeCustom),
        @"directMonetizationNetwork": @(AppsFlyerAdRevenueMediationNetworkTypeDirectMonetization)
    };
    
    NSNumber *enumValueNumber = stringToEnumMap[mediationNetworkString];
    if (enumValueNumber) {
        return (AppsFlyerAdRevenueMediationNetworkType)[enumValueNumber integerValue];
    } else {
        return -1; 
    }
}

/**
*    log AdRevenue event
*/
- (void)logAdRevenue:(CDVInvokedUrlCommand*)command
{
    if ([command.arguments count] == 0) {
        return;
    }

    NSDictionary* afAdRevenueDataMap = [command argumentAtIndex:0 withDefault:[NSNull null]];
    NSDictionary* additionalParametersMap = [command argumentAtIndex:1 withDefault:[NSNull null]];

    id monetizationNetwork = nil;
    AppsFlyerAdRevenueMediationNetworkType mediationNetwork;
    id currencyIso4217Code = nil;
    NSNumber *revenue = 0;

    id monetizationNetworkValue = nil;
    id mediationNetworkValue = nil;
    id currencyIso4217CodeValue = nil;
    id revenueValue = nil;

    if(![afAdRevenueDataMap isKindOfClass:[NSNull class]]){
        monetizationNetworkValue = [afAdRevenueDataMap objectForKey:@"monetizationNetwork"];
        if (monetizationNetworkValue != nil && [monetizationNetworkValue isKindOfClass:[NSString class]]) {
           monetizationNetwork = monetizationNetworkValue;
        }

        mediationNetworkValue = [afAdRevenueDataMap objectForKey:@"mediationNetwork"];
        if (mediationNetworkValue != nil && [mediationNetworkValue isKindOfClass:[NSString class]]) {
            if([self getEnumValueFromString: mediationNetworkValue] != -1){
                mediationNetwork = [self getEnumValueFromString: mediationNetworkValue];
            }
            else{
                NSLog(@"mediationNetwork param is not according to the Enum format");
                return;
            }
        }

        currencyIso4217CodeValue = [afAdRevenueDataMap objectForKey:@"currencyIso4217Code"];
        if (currencyIso4217CodeValue != nil && [currencyIso4217CodeValue isKindOfClass:[NSString class]]) {
           currencyIso4217Code = currencyIso4217CodeValue;
        }

        revenueValue = [afAdRevenueDataMap objectForKey:@"revenue"];
        if (revenueValue != nil && [revenueValue isKindOfClass:[NSNumber class]]) {
            revenue = revenueValue;
        }
        if(monetizationNetwork != nil && currencyIso4217Code != nil && revenue != nil){
            AFAdRevenueData *adRevenueData = [[AFAdRevenueData alloc] initWithMonetizationNetwork:monetizationNetwork mediationNetwork:mediationNetwork currencyIso4217Code:currencyIso4217Code eventRevenue:revenue];
            if([additionalParametersMap isKindOfClass:[NSNull class]]){
                [[AppsFlyerLib shared] logAdRevenue:adRevenueData additionalParameters:nil];
            }
            else{
                [[AppsFlyerLib shared] logAdRevenue:adRevenueData additionalParameters:additionalParametersMap];
            }
        }
        else{
            NSLog(@"one or more arguments are invalid or nil");
        }
    }
    else{
        NSLog(@"afAdRevenueDataMap is invalid or nil");
    }
}

/**
 * Sets the manually provided user consent.
 */
 
- (void)setConsentData:(CDVInvokedUrlCommand*)command
{
    if ([command.arguments count] == 0) {
        NSLog(@"Error: No arguments provided.");
        return;
    }

    NSDictionary *consentDataMap = (NSDictionary*)[command.arguments objectAtIndex:0];

    // Extract values safely, allowing nil, YES, and NO
    id isUserSubjectToGDPRValue = [consentDataMap objectForKey:@"isUserSubjectToGDPR"];
    id hasConsentForDataUsageValue = [consentDataMap objectForKey:@"hasConsentForDataUsage"];
    id hasConsentForAdsPersonalizationValue = [consentDataMap objectForKey:@"hasConsentForAdsPersonalization"];
    id hasConsentForAdStorageValue = [consentDataMap objectForKey:@"hasConsentForAdStorage"];

    // Convert to NSNumber explicitly (nil stays nil, but NO/YES are preserved)
    NSNumber *isUserSubjectToGDPR = ([isUserSubjectToGDPRValue isKindOfClass:[NSNumber class]]) ? isUserSubjectToGDPRValue : nil;
    NSNumber *hasConsentForDataUsage = ([hasConsentForDataUsageValue isKindOfClass:[NSNumber class]]) ? hasConsentForDataUsageValue : nil;
    NSNumber *hasConsentForAdsPersonalization = ([hasConsentForAdsPersonalizationValue isKindOfClass:[NSNumber class]]) ? hasConsentForAdsPersonalizationValue : nil;
    NSNumber *hasConsentForAdStorage = ([hasConsentForAdStorageValue isKindOfClass:[NSNumber class]]) ? hasConsentForAdStorageValue : nil;

    AppsFlyerConsent *consentData = [[AppsFlyerConsent alloc] initWithIsUserSubjectToGDPR:isUserSubjectToGDPR
                                                                       hasConsentForDataUsage:hasConsentForDataUsage
                                                            hasConsentForAdsPersonalization:hasConsentForAdsPersonalization
                                                                    hasConsentForAdStorage:hasConsentForAdStorage];

    // Pass the consent data to AppsFlyer
    [[AppsFlyerLib shared] setConsentData:consentData];

    NSLog(@"AppsFlyerConsent set successfully.");
}

/**
*   Sets new currency code. currencyId: ISO 4217 Currency Codes.
*/
- (void)enableTCFDataCollection:(CDVInvokedUrlCommand*)command
{
    if ([command.arguments count] == 0) {
        return;
    }
    BOOL enable = NO;
    id enableValue = nil;
    enableValue = [command.arguments objectAtIndex:0];
    if ([enableValue isKindOfClass:[NSNumber class]]) {
       enable = [(NSNumber*)enableValue boolValue];
    }
    [[AppsFlyerLib shared] enableTCFDataCollection:enable];
}
/**
*   Setting your own Custom ID enables you to cross-reference your own unique ID with AppsFlyer’s user ID and the other devices’ IDs.
*/
- (void)setAppUserId:(CDVInvokedUrlCommand *)command
{
    if ([command.arguments count] == 0) {
        return;
    }

    NSString* userId = [command.arguments objectAtIndex:0];
    [AppsFlyerLib shared].customerUserID  = userId;
}

/**
*   End User Opt-Out from AppsFlyer analytics.
*/
- (void)anonymizeUser:(CDVInvokedUrlCommand *)command
{
    if ([command.arguments count] == 0) {
        return;
    }

    BOOL isDisValueBool = NO;
    id isDisValue = nil;
    isDisValue = [command.arguments objectAtIndex:0];
    if ([isDisValue isKindOfClass:[NSNumber class]]) {
        isDisValueBool = [(NSNumber*)isDisValue boolValue];
        [AppsFlyerLib shared].anonymizeUser  = isDisValueBool;
    }
}

/**
*   Shut down all SDK for sending logs
*/
- (void)Stop:(CDVInvokedUrlCommand *)command
{
    if ([command.arguments count] == 0) {
        return;
    }

    BOOL isStopValueBool = NO;
    id isStopValue = nil;
    isStopValue = [command.arguments objectAtIndex:0];
    if ([isStopValue isKindOfClass:[NSNumber class]]) {
        isStopValueBool = [(NSNumber*)isStopValue boolValue];
        [AppsFlyerLib shared].isStopped  = isStopValueBool;
    }
}

/**
*   Get the Appsflyer ID
*/
- (void)getAppsFlyerUID:(CDVInvokedUrlCommand *)command
{
    NSString* userId = [[AppsFlyerLib shared] getAppsFlyerUID];
    CDVPluginResult *pluginResult = [ CDVPluginResult
                                    resultWithStatus    : CDVCommandStatus_OK
                                    messageAsString: userId
                                    ];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

/**
*   Get the deeplink data. use 'success' and 'failure' callback methods.
*/
- (void)registerOnAppOpenAttribution:(CDVInvokedUrlCommand *)command
{
    mAttributionDataListener = command.callbackId;
}

/**
 Register unified deep link callback
 */
- (void)registerDeepLink:(CDVInvokedUrlCommand *)command
{
    mDeepLinkListener = command.callbackId;
}

/**
* Log rich in-app events
* @param parameters eventName: custom event name, is presented in your dashboard.
*                   eventValue: event details
*                   callbackID: 'success' and 'failure' methods
*/
- (void)logEvent:(CDVInvokedUrlCommand*)command {

    NSString* error = nil;
    NSString* eventName = [command.arguments objectAtIndex:0];
    NSDictionary* eventValues = [command.arguments objectAtIndex:1];

 if(eventName == nil || eventName.length == 0){
        error = @"Event name is illegal";
    }
    if(eventValues == nil){
        error = @"Event Values are illegal";
    }

    if(error != nil){
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: error];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    return;
    }

    [[AppsFlyerLib shared] logEventWithEventName:eventName eventValues:eventValues completionHandler:^(NSDictionary<NSString *,id> * _Nullable dictionary, NSError * _Nullable error) {
        if(error != nil){
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: [error localizedDescription]];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            return;
        }else{
            CDVPluginResult *pluginResult = [ CDVPluginResult resultWithStatus: CDVCommandStatus_OK
            messageAsString:eventName
            ];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];

}
/**
*   Allows to pass APN Tokens that where collected by third party plugins to the AppsFlyer server. Can be used for Log Uninstall.
*/
- (void)registerUninstall:(CDVInvokedUrlCommand*)command {

    NSString* deviceToken = [command.arguments objectAtIndex:0];
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableData *deviceTokenData= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [deviceToken length]/2; i++) {
        byte_chars[0] = [deviceToken characterAtIndex:i*2];
        byte_chars[1] = [deviceToken characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [deviceTokenData appendBytes:&whole_byte length:1];
    }

    if(deviceToken!=nil){
        [[AppsFlyerLib shared] registerUninstall:deviceTokenData];
    }else{
        NSLog(@"Invalid device token");
    }
}

/**
*   Get the current SDK version
*/
- (void)getSdkVersion:(CDVInvokedUrlCommand*)command {
    NSString* version = [[AppsFlyerLib shared] getSDKVersion];
    CDVPluginResult *pluginResult = [CDVPluginResult
                                        resultWithStatus: CDVCommandStatus_OK
                                        messageAsString: version
                                        ];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

//USER INVITES
/**
*   Set AppsFlyer’s OneLink ID
*/

- (void)setAppInviteOneLinkID:(CDVInvokedUrlCommand*)command {
    if ([command.arguments count] == 0) {
        return;
    }
    NSString* oneLinkID = [command.arguments objectAtIndex:0];
    [AppsFlyerLib shared].appInviteOneLinkID = oneLinkID;
}

/**
*   Allowing your existing users to invite their friends and contacts as new users to your app
*   customParams - Parameters for Invite link
*/
- (void)generateInviteLink:(CDVInvokedUrlCommand*)command {
    NSDictionary* inviteLinkOptions = [command argumentAtIndex:0 withDefault:[NSNull null]];
    NSDictionary* customParams = (NSDictionary*)[inviteLinkOptions objectForKey: @"userParams"];

    NSString *channel = nil;
    NSString *campaign = nil;
    NSString *referrerName = nil;
    NSString *referrerImageUrl = nil;
    NSString *customerID = nil;
    NSString *baseDeepLink = nil;
    NSString *brandDomain = nil;

    if (![inviteLinkOptions isKindOfClass:[NSNull class]]) {
        channel = (NSString*)[inviteLinkOptions objectForKey: afUiChannel];
        campaign = (NSString*)[inviteLinkOptions objectForKey: afUiCampaign];
        referrerName = (NSString*)[inviteLinkOptions objectForKey: afUiRefName];
        referrerImageUrl = (NSString*)[inviteLinkOptions objectForKey: afUiImageUrl];
        customerID = (NSString*)[inviteLinkOptions objectForKey: afUiCustomerID];
        baseDeepLink = (NSString*)[inviteLinkOptions objectForKey: afUiBaseDeepLink];
        brandDomain = (NSString*)[inviteLinkOptions objectForKey: afUiBrandDomain];

        [AppsFlyerShareInviteHelper generateInviteUrlWithLinkGenerator:^AppsFlyerLinkGenerator * _Nonnull(AppsFlyerLinkGenerator * _Nonnull generator) {
            if (channel != nil && ![channel isEqualToString:@""]) {
                [generator setChannel:channel];
            }
            if (campaign != nil && ![campaign isEqualToString:@""]) {
                [generator setCampaign:campaign];
            }
            if (referrerName != nil && ![referrerName isEqualToString:@""]) {
                [generator setReferrerName:referrerName];
            }
            if (referrerImageUrl != nil && ![referrerImageUrl isEqualToString:@""]) {
                [generator setReferrerImageURL:referrerImageUrl];
            }
            if (customerID != nil && ![customerID isEqualToString:@""]) {
                [generator setReferrerCustomerId:customerID];
            }
            if (baseDeepLink != nil && ![baseDeepLink isEqualToString:@""]) {
                [generator setDeeplinkPath:baseDeepLink];
            }
            if (brandDomain != nil && ![brandDomain isEqualToString:@""]) {
                [generator setBrandDomain:brandDomain];
            }

            if (![customParams isKindOfClass:[NSNull class]]) {
                    [generator addParameters:customParams];
            }

            return generator;
        } completionHandler: ^(NSURL * _Nullable url) {
            mInviteListener = url.absoluteString;
                if (mInviteListener != nil) {
                CDVPluginResult *pluginResult = [ CDVPluginResult
                                                 resultWithStatus    : CDVCommandStatus_OK
                                                 messageAsString: mInviteListener
                                                 ];

                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
         }];
    }
}

//CROSS PROMOTION
/**
*   Log cross promotion impression. Make sure to use the promoted App ID as it appears within the AppsFlyer dashboard.
*                   promtAppID: Promoted Application ID
*                   campaign: Promoted Campaign
*/
-(void)logCrossPromotionImpression:(CDVInvokedUrlCommand*) command {

    if ([command.arguments count] == 0) {
        return;
    }

    NSString* promtAppID = [command.arguments objectAtIndex:0];
    NSString* campaign = campaign = [command.arguments objectAtIndex:1];
    NSDictionary* parameters = [command.arguments objectAtIndex:2];

    if (promtAppID != nil && ![promtAppID isEqualToString:@""] && parameters != nil) {
        [AppsFlyerCrossPromotionHelper logCrossPromoteImpression:promtAppID campaign:campaign parameters:parameters];
    }
}

/**
*   Use this call to log the click and launch the app store's app page (via Browser)
*                   promtAppId: Promoted Application ID
*                   campaign: Promoted Campaign
*                   customParams: Additional Parameters to log
*/
-(void)logCrossPromotionAndOpenStore:(CDVInvokedUrlCommand*) command {

    if ([command.arguments count] == 0) {
        return;
    }

    NSString* promtAppID = [command.arguments objectAtIndex:0];
    NSString* campaign = [command.arguments objectAtIndex:1];
    NSDictionary* customParams = [command argumentAtIndex:2 withDefault:[NSNull null]];

    if (promtAppID != nil && ![promtAppID isEqualToString:@""]) {
        [AppsFlyerShareInviteHelper generateInviteUrlWithLinkGenerator:^AppsFlyerLinkGenerator * _Nonnull(AppsFlyerLinkGenerator * _Nonnull generator) {
            if (campaign != nil && ![campaign isEqualToString:@""]) {
                [generator setCampaign:campaign];
            }
            if (![customParams isKindOfClass:[NSNull class]]) {
                [generator addParameters:customParams];
            }

            return generator;
        } completionHandler: ^(NSURL * _Nullable url) {
            NSString *appLink = url.absoluteString;
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appLink] options:@{} completionHandler:^(BOOL success) {
                CDVPluginResult* pluginResult =  [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            }];
        }];
    }
}


//5.2.0 - 'onConversionDataReceived' changed to 'onConversionDataSuccess'
-(void)onConversionDataSuccess:(NSDictionary*) installData {

    NSDictionary* message = @{
                              @"status": afSuccess,
                              @"type": afOnInstallConversionDataLoaded,
                              @"data": [installData copy]
                              };

    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:message waitUntilDone:NO];
}

//5.2.0 - 'onConversionDataRequestFailure' changed to 'onConversionDataFail'
-(void)onConversionDataFail:(NSError *) _errorMessage {

    NSDictionary* errorMessage = @{
                                   @"status": afFailure,
                                   @"type": afOnInstallConversionFailure,
                                   @"data": _errorMessage.localizedDescription
                                   };

    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:errorMessage waitUntilDone:NO];
}

/**
*  Get the deeplink data
*/
- (void) onAppOpenAttribution:(NSDictionary*) attributionData {

    NSDictionary* message = @{
                              @"status": afSuccess,
                              @"type": afOnAppOpenAttribution,
                              @"data": attributionData
                              };

    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:message waitUntilDone:NO];
}

- (void) onAppOpenAttributionFailure:(NSError *)_errorMessage {

    NSDictionary* errorMessage = @{
                                   @"status": afFailure,
                                   @"type": afOnAttributionFailure,
                                   @"data": _errorMessage.localizedDescription
                                   };

    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:errorMessage waitUntilDone:NO];
}

/**
 Unified deep link handler
 */
- (void)didResolveDeepLink:(AppsFlyerDeepLinkResult* _Nonnull) result {
    NSString *deepLinkStatus = nil;
    switch(result.status) {
        case AFSDKDeepLinkResultStatusFound:
            deepLinkStatus = @"FOUND";
            break;
        case AFSDKDeepLinkResultStatusNotFound:
            deepLinkStatus = @"NOT_FOUND";
            break;
        case AFSDKDeepLinkResultStatusFailure:
            deepLinkStatus = @"Error";
            break;
        default:
            [NSException raise:NSGenericException format:@"Unexpected FormatType."];
    }
    NSMutableDictionary* message = [[NSMutableDictionary alloc] initWithCapacity:4];
    [message setObject:([deepLinkStatus isEqual:@"Error"] || [deepLinkStatus isEqual:@"NOT_FOUND"]) ? afFailure : afSuccess forKey:@"status"];
    [message setObject:deepLinkStatus forKey:@"deepLinkStatus"];
    [message setObject:afOnDeepLinking forKey:@"type"];
    if([deepLinkStatus  isEqual: @"Error"]){
        [message setObject:result.error.localizedDescription forKey:@"data"];
    }else if([deepLinkStatus  isEqual: @"NOT_FOUND"]){
        [message setObject:@"deep link not found" forKey:@"data"];
    }else{
        [message setObject:result.deepLink.clickEvent forKey:@"data"];
    }

    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:message waitUntilDone:NO];
}

/**
*   Helper function to handle callbacks from the sdk
*/
-(void) handleCallback:(NSDictionary *) message{
    NSError *error;

    NSData *jsonMessage = [NSJSONSerialization dataWithJSONObject:message
                                                          options:0
                                                            error:&error];
    if (jsonMessage) {
        NSString *jsonMessageStr = [[NSString alloc] initWithBytes:[jsonMessage bytes] length:[jsonMessage length] encoding:NSUTF8StringEncoding];

        NSString* status = (NSString*)[message objectForKey: @"status"];
        NSString* type = (NSString*)[message objectForKey: @"type"];

        if([status isEqualToString:afSuccess] || [type isEqualToString:afOnDeepLinking]){
            [self reportOnSuccess:jsonMessageStr withType:type];
        }
        else{
            [self reportOnFailure:jsonMessageStr withType:type];
        }

        NSLog(@"jsonMessageStr = %@",jsonMessageStr);
    } else {
        NSLog(@"%@",error);
    }
}

/**
*   Error callback - called when error occurs.
*/
-(void) reportOnFailure:(NSString *)errorMessage withType:(NSString *)type{

    if([type isEqualToString:afOnAttributionFailure]){
        if(mAttributionDataListener != nil){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:NO]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:mAttributionDataListener];
        }
    }
    else if([type isEqualToString:afOnInstallConversionFailure]){

        if(mConversionListener != nil){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:NO]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:mConversionListener];
            mConversionListener = nil;
        }
    }
}

/**
*   Success callback - called after receiving data.
*/
-(void) reportOnSuccess:(NSString *)data withType:(NSString *)type {

    if([type isEqualToString:afOnAppOpenAttribution]){
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:data];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:mAttributionDataListener];
    }
    else if([type isEqualToString:afOnInstallConversionDataLoaded]){
        if(mConversionListener != nil){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:data];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:mConversionListener];
        }
    }else if([type isEqualToString:afOnDeepLinking]){
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:data];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:mDeepLinkListener];
    }
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
* Used by advertisers to exclude specified networks/integrated partners from getting data
*/
- (void)setSharingFilterForPartners:(CDVInvokedUrlCommand*)command {
    NSArray* partners = [command argumentAtIndex:0];
    if (partners == nil ||[partners count] == 0) {
           return;
       }
    [[AppsFlyerLib shared] setSharingFilterForPartners:partners];

}

/**
* Used by advertisers to exclude specified networks/integrated partners from getting data
*/
- (void)setSharingFilter:(CDVInvokedUrlCommand*)command {
    NSArray* partners = [command argumentAtIndex:0];
    if (partners == nil || [partners count] == 0) {
           return;
       }
      [[AppsFlyerLib shared] setSharingFilter:partners];
      CDVPluginResult *pluginResult = [CDVPluginResult
                                        resultWithStatus: CDVCommandStatus_OK
                                        ];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

/**
* Used by advertisers to exclude ALL networks/integrated partners from getting data
*/
- (void)setSharingFilterForAllPartners:(CDVInvokedUrlCommand*)command {
    [[AppsFlyerLib shared] setSharingFilterForAllPartners];
    CDVPluginResult *pluginResult = [CDVPluginResult
                                        resultWithStatus: CDVCommandStatus_OK
                                        ];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
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

#ifndef AFSDK_NO_IDFA
/**
 * AppsFlyer SDK dynamically loads the Apple adSupport.framework. This framework is required to collect IDFA for attribution purposes.
 * If you don't want AppsFlyer to dynamically load this framework, set this property to true.
 */
- (void)setDisableAdvertisingIdentifier:(CDVInvokedUrlCommand*)command {
    BOOL isDisableBool = NO;
    id isDisablevalue = [command.arguments objectAtIndex:0];
    if ([isDisablevalue isKindOfClass:[NSNumber class]]) {
        isDisableBool = [(NSNumber*)isDisablevalue boolValue];
        [[AppsFlyerLib shared] setDisableAdvertisingIdentifier:isDisableBool];
    }
    CDVPluginResult *pluginResult = [CDVPluginResult
                                     resultWithStatus: CDVCommandStatus_OK
                                     ];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
#endif
/**
* Set Onelink custom/branded domains
*/
- (void)setOneLinkCustomDomains:(CDVInvokedUrlCommand*)command {
    NSArray* domains = [command argumentAtIndex:0];
    if (domains == nil || domains.count == 0) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: afNoDomains];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    [[AppsFlyerLib shared] setOneLinkCustomDomains:domains];
    NSLog(@"[DEBUG] AppsFlyer: %@", domains);
    CDVPluginResult *pluginResult = [CDVPluginResult
                                      resultWithStatus: CDVCommandStatus_OK messageAsString:afSuccess
                                      ];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}
/**
 * use this api If you need deep linking data from Facebook, deferred deep linking, Dynamic Product Ads etc.
 * More information here: https://support.appsflyer.com/hc/en-us/articles/207033826-Facebook-Ads-setup-guide#integration
 */
- (void)enableFacebookDeferredApplinks:(CDVInvokedUrlCommand*)command {
    BOOL isEnabled = NO;
    id isEnabledvalue = [command.arguments objectAtIndex:0];
    if ([isEnabledvalue isKindOfClass:[NSNumber class]]) {
        isEnabled = [(NSNumber*)isEnabledvalue boolValue];
        if(isEnabled){
#if __has_include (<FBSDKAppLinkUtility.h>)
            [[AppsFlyerLib shared] enableFacebookDeferredApplinksWithClass: FBSDKAppLinkUtility.class];
            NSLog(@"Enabled FacebookDeferredApplinks");
#else
            NSLog(@"Please install FBSDK First!");
#endif
        }else{
            [[AppsFlyerLib shared] enableFacebookDeferredApplinksWithClass: nil];
            NSLog(@"Disabled FacebookDeferredApplinks");
        }
    }
}


/**
 Facebook Advanced Matching - set phone number
 */
- (void)setPhoneNumber:(CDVInvokedUrlCommand*)command {
    NSString* phoneNumber = [command.arguments objectAtIndex:0];
    [[AppsFlyerLib shared] setPhoneNumber:phoneNumber];
    NSLog(@"phone number: %@", phoneNumber);
    CDVPluginResult *pluginResult = [CDVPluginResult
                                      resultWithStatus: CDVCommandStatus_OK messageAsString:afSuccess
                                      ];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}
/**
 Facebook Advanced Matching - set user email
 */
- (void)setUserEmails:(CDVInvokedUrlCommand*)command {
    NSArray* emails = [command argumentAtIndex:0];
    if (emails == nil || emails.count == 0) {
        return;
    }
    [[AppsFlyerLib shared] setUserEmails:emails withCryptType: EmailCryptTypeSHA256];
    NSLog(@"emails: %@", emails);
    CDVPluginResult *pluginResult = [CDVPluginResult
                                      resultWithStatus: CDVCommandStatus_OK messageAsString:afSuccess
                                      ];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}

/**
* Receipt validation is a secure mechanism whereby the payment platform (e.g. Apple or Google) validates that an in-app purchase indeed occurred as reported.
* Learn more - https://support.appsflyer.com/hc/en-us/articles/207032106-Receipt-validation-for-in-app-purchases
*
* @param purchase info, success and failure callbacks
*/
- (void)validateAndLogInAppPurchase: (CDVInvokedUrlCommand*)command {
    NSString* productIdentifier = nil;
    NSString* tranactionId = nil;
    NSString* price = nil;
    NSString* currency = nil;
    NSDictionary* additionalParameters = nil;

    NSDictionary* purchaseInfo = [command.arguments objectAtIndex:0];


     if(![purchaseInfo isKindOfClass: [NSNull class]]){
            productIdentifier = (NSString*)[purchaseInfo objectForKey: afProductIdentifier];
            tranactionId = (NSString*)[purchaseInfo objectForKey: afTransactionId];
            price = (NSString*)[purchaseInfo objectForKey: afPrice];
            currency = (NSString*)[purchaseInfo objectForKey: afCurrency];
            additionalParameters = (NSDictionary*)[purchaseInfo objectForKey: afAdditionalParameters];

            [[AppsFlyerLib shared] validateAndLogInAppPurchase:productIdentifier price:price currency:currency transactionId:tranactionId additionalParameters:additionalParameters success:^(NSDictionary * _Nonnull response) {
                CDVPluginResult *pluginResult = [CDVPluginResult
                                                 resultWithStatus: CDVCommandStatus_OK messageAsString: VALIDATE_SUCCESS
                                                 ];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            } failure:^(NSError * _Nullable error, id  _Nullable reponse) {
                CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: error.localizedDescription];
                [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
                return;
            }];

    }else{
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: NO_PARAMETERS_ERROR];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
}

- (void)setUseReceiptValidationSandbox:(CDVInvokedUrlCommand*)command {
    BOOL isSandbox = [command.arguments objectAtIndex:0];
    [AppsFlyerLib shared].useReceiptValidationSandbox = isSandbox;

    CDVPluginResult *pluginResult = [CDVPluginResult
                                     resultWithStatus: CDVCommandStatus_OK messageAsString: isSandbox? @"Sandbox set to true" : @"Sandbox set to false"
                                     ];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setHost:(CDVInvokedUrlCommand*)command {
    NSString* prefix = [command.arguments objectAtIndex:0];
    NSString* name = [command.arguments objectAtIndex:1];
    [[AppsFlyerLib shared] setHost:name withHostPrefix:prefix];
    NSLog(@"[DEBUG] AppsFlyer: %@.%@",prefix, name);

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

- (void)disableSKAD:(CDVInvokedUrlCommand *)command
{
    if ([command.arguments count] == 0) {
        return;
    }

    BOOL isDisValueBool = NO;
    id isDisValue = nil;
    isDisValue = [command.arguments objectAtIndex:0];
    if ([isDisValue isKindOfClass:[NSNumber class]]) {
        isDisValueBool = [(NSNumber*)isDisValue boolValue];
        [AppsFlyerLib shared].disableSKAdNetwork = isDisValueBool;
        if (isDisValueBool){
            NSLog(@"[DEBUG] AppsFlyer: SKADNetwork is disabled");
        }else{
            NSLog(@"[DEBUG] AppsFlyer: SKADNetwork is enabled");
        }
    }
}


- (void)setAdditionalData:(CDVInvokedUrlCommand*)command{
    NSDictionary *additionalData = (NSDictionary*)[command.arguments objectAtIndex: 0];
    [[AppsFlyerLib shared] setAdditionalData:additionalData];
}

- (void)setPartnerData:(CDVInvokedUrlCommand*)command{
    NSString *partnerId = (NSString*)[command.arguments objectAtIndex: 0];
    NSDictionary *data = (NSDictionary*)[command.arguments objectAtIndex: 1];
    [[AppsFlyerLib shared] setPartnerDataWithPartnerId:partnerId partnerInfo:data];
}

@end
