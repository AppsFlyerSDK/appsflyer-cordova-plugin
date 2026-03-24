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

 NSString* mInviteListener;

- (void)sendPushNotificationData:(CDVInvokedUrlCommand*)command{
  NSDictionary* pushPayload = [command.arguments objectAtIndex:0];
  [[AppsFlyerLib shared] handlePushNotification:pushPayload];
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

/**
* Receipt validation V2 is a secure mechanism whereby the payment platform (e.g. Apple or Google) validates that an in-app purchase indeed occurred as reported.
* This method uses the new V2 API with purchase details object.
* Learn more - https://dev.appsflyer.com/hc/docs/validate-and-log-purchase-ios
*
* @param purchase details, success and failure callbacks
*/
- (void)validateAndLogInAppPurchaseV2: (CDVInvokedUrlCommand*)command {
    NSLog(@"[DEBUG] AppsFlyer: validateAndLogInAppPurchaseV2 called");

    NSString* productId = nil;
    NSString* transactionId = nil;
    NSString* purchaseType = nil;
    NSDictionary* additionalParameters = nil;

    NSDictionary* purchaseDetails = [command.arguments objectAtIndex:0];
    NSLog(@"[DEBUG] AppsFlyer: purchaseDetails: %@", purchaseDetails);

    if(![purchaseDetails isKindOfClass: [NSNull class]]){
        NSLog(@"[DEBUG] AppsFlyer: purchaseDetails is not null");

        productId = (NSString*)[purchaseDetails objectForKey: afProductId];
        transactionId = (NSString*)[purchaseDetails objectForKey: @"purchaseToken"];
        purchaseType = (NSString*)[purchaseDetails objectForKey: afPurchaseType];

        NSLog(@"[DEBUG] AppsFlyer: Extracted values:");
        NSLog(@"[DEBUG] AppsFlyer: - productId: %@", productId);
        NSLog(@"[DEBUG] AppsFlyer: - purchaseToken: %@", transactionId);
        NSLog(@"[DEBUG] AppsFlyer: - purchaseType: %@", purchaseType);

        // Get additional parameters if provided
        if ([command.arguments count] > 1 && ![[command.arguments objectAtIndex:1] isKindOfClass:[NSNull class]]) {
            additionalParameters = (NSDictionary*)[command.arguments objectAtIndex:1];
            NSLog(@"[DEBUG] AppsFlyer: additionalParameters: %@", additionalParameters);
        } else {
            NSLog(@"[DEBUG] AppsFlyer: No additional parameters provided");
        }

        // Validate required parameters
        BOOL hasProductId = productId && [productId length] > 0;
        BOOL hasTransactionId = transactionId && [transactionId length] > 0;
        BOOL hasPurchaseType = purchaseType && [purchaseType length] > 0;

        if (!hasProductId || !hasTransactionId || !hasPurchaseType) {
            NSLog(@"[DEBUG] AppsFlyer: Validation failed - missing required parameters");
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: NO_PARAMETERS_ERROR];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            return;
        }

        NSLog(@"[DEBUG] AppsFlyer: All parameters validated successfully, creating AFSDKPurchaseDetails");

        // Create AFSDKPurchaseDetails object
        AFSDKPurchaseType purchaseTypeEnum = AFSDKPurchaseTypeOneTimePurchase;
        if ([purchaseType isEqualToString:@"subscription"]) {
            purchaseTypeEnum = AFSDKPurchaseTypeSubscription;
            NSLog(@"[DEBUG] AppsFlyer: Purchase type set to subscription");
        } else {
            NSLog(@"[DEBUG] AppsFlyer: Purchase type set to one-time purchase");
        }

        AFSDKPurchaseDetails *details = [[AFSDKPurchaseDetails alloc] initWithProductId:productId
                                                                           transactionId:transactionId
                                                                            purchaseType:purchaseTypeEnum];

        // Use the actual V2 method with the correct signature
        NSLog(@"[DEBUG] AppsFlyer: Calling AppsFlyerLib validateAndLogInAppPurchase V2 method");
        [[AppsFlyerLib shared] validateAndLogInAppPurchase:details
                                   purchaseAdditionalDetails:additionalParameters
                                                completion:^(NSDictionary * _Nullable response, NSError * _Nullable error) {
            NSLog(@"[DEBUG] AppsFlyer: V2 validation completion called");
            if (error) {
                NSLog(@"[DEBUG] AppsFlyer: V2 validation failed with error: %@", error.localizedDescription);
                // Error case
                NSDictionary *errorDict = @{
                    @"error": error.localizedDescription ?: @"Unknown error",
                    @"code": @(error.code)
                };
                NSError *jsonError;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:errorDict options:0 error:&jsonError];
                NSString *jsonString = @"";
                if (!jsonError) {
                    jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                }

                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:jsonString];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            } else {
                NSLog(@"[DEBUG] AppsFlyer: V2 validation succeeded with response: %@", response);
                // Success case
                NSError *jsonError;
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response options:0 error:&jsonError];
                NSString *jsonString = @"";
                if (!jsonError) {
                    jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                }

                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        }];

    } else {
        NSLog(@"[DEBUG] AppsFlyer: purchaseDetails is null or NSNull");
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

- (void)disableAppSetId:(CDVInvokedUrlCommand*)command{
    NSLog(@"AppsFlyer: This feature is not available on iOS");
}

@end
