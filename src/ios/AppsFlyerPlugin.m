#import "AppsFlyerPlugin.h"
#import "AppsFlyerTracker.h"
#import "AppDelegate.h"

@implementation AppsFlyerPlugin


static NSString *const NO_DEVKEY_FOUND = @"AppsFlyer 'devKey' is missing or empty";
static NSString *const NO_APPID_FOUND  = @"'appId' is missing or empty";
static NSString *const SUCCESS         = @"Success";

 NSString* mConversionListener;
 NSString* mAttributionDataListener;
 NSString* mConversionListenerOnResume;
 NSString* mInviteListener;
 BOOL isConversionData = NO;
    
- (void)pluginInitialize{}

- (void)initSdk:(CDVInvokedUrlCommand*)command
{
    NSDictionary* initSdkOptions = [command argumentAtIndex:0 withDefault:[NSNull null]];
    
    NSString* devKey = nil;
    NSString* appId = nil;
    BOOL isDebug = NO;
    BOOL useUninstallSandbox = NO;
    
    
    if (![initSdkOptions isKindOfClass:[NSNull class]]) {
        
        id value = nil;
        id isConversionDataValue = nil;
        id sandboxValue = nil;
        devKey = (NSString*)[initSdkOptions objectForKey: afDevKey];
        appId = (NSString*)[initSdkOptions objectForKey: afAppId];
        
        value = [initSdkOptions objectForKey: afIsDebug];
        if ([value isKindOfClass:[NSNumber class]]) {
            isDebug = [(NSNumber*)value boolValue];
        }
        isConversionDataValue = [initSdkOptions objectForKey: afConversionData];
        if ([isConversionDataValue isKindOfClass:[NSNumber class]]) {
            isConversionData = [(NSNumber*)isConversionDataValue boolValue];
        }
        sandboxValue = [initSdkOptions objectForKey: afSanboxUninstall];
        if ([sandboxValue isKindOfClass:[NSNumber class]]) {
            useUninstallSandbox = [(NSNumber*)sandboxValue boolValue];
        }
    }
    
    NSString* error = nil;
    
    if (!devKey || [devKey isEqualToString:@""]) {
        error = NO_DEVKEY_FOUND;
    }
    else if (!appId || [appId isEqualToString:@""]) {
        error = NO_APPID_FOUND;
    }
    
    if(error != nil){
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: error];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    else{
        
        [AppsFlyerTracker sharedTracker].appleAppID = appId;
        [AppsFlyerTracker sharedTracker].appsFlyerDevKey = devKey;
        [AppsFlyerTracker sharedTracker].isDebug = isDebug;
        [AppsFlyerTracker sharedTracker].useUninstallSandbox = useUninstallSandbox;
        [[AppsFlyerTracker sharedTracker] trackAppLaunch];

        
        if(isConversionData == YES){
          CDVPluginResult* pluginResult = nil;
          mConversionListener = command.callbackId;
            
          [AppsFlyerTracker sharedTracker].delegate = self;
         
          pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
          [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        }
        else{
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:SUCCESS];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }
    }
  }
    
- (void)resumeSDK:(CDVInvokedUrlCommand *)command
  {
      [[AppsFlyerTracker sharedTracker] trackAppLaunch];
      
      
      if (isConversionData == YES) {
          CDVPluginResult* pluginResult = nil;
          mConversionListenerOnResume = command.callbackId;
          
          pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
          [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
      }
      else {
          CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:SUCCESS];
          [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
      }
  }

    
- (void)setCurrencyCode:(CDVInvokedUrlCommand*)command
{
    if ([command.arguments count] == 0) {
        return;
    }
    
    NSString* currencyId = [command.arguments objectAtIndex:0];
    [AppsFlyerTracker sharedTracker].currencyCode = currencyId;
}

- (void)setAppUserId:(CDVInvokedUrlCommand *)command
{
    if ([command.arguments count] == 0) {
        return;
    }
    
    NSString* userId = [command.arguments objectAtIndex:0];
    [AppsFlyerTracker sharedTracker].customerUserID  = userId;
}

- (void)setDeviceTrackingDisabled:(CDVInvokedUrlCommand *)command
{
    if ([command.arguments count] == 0) {
        return;
    }
    
    BOOL isDisValueBool = NO;
    id isDisValue = nil;
    isDisValue = [command.arguments objectAtIndex:0];
    if ([isDisValue isKindOfClass:[NSNumber class]]) {
        isDisValueBool = [(NSNumber*)isDisValue boolValue];
        [AppsFlyerTracker sharedTracker].deviceTrackingDisabled  = isDisValueBool;
    }
}

- (void)stopTracking:(CDVInvokedUrlCommand *)command
{
    if ([command.arguments count] == 0) {
        return;
    }

    BOOL isStopValueBool = NO;
    id isStopValue = nil;
    isStopValue = [command.arguments objectAtIndex:0];
    if ([isStopValue isKindOfClass:[NSNumber class]]) {
        isStopValueBool = [(NSNumber*)isStopValue boolValue];
        [AppsFlyerTracker sharedTracker].isStopTracking  = isStopValueBool;
    }
}

- (void)getAppsFlyerUID:(CDVInvokedUrlCommand *)command
{
    NSString* userId = [[AppsFlyerTracker sharedTracker] getAppsFlyerUID];
    CDVPluginResult *pluginResult = [ CDVPluginResult
                                    resultWithStatus    : CDVCommandStatus_OK
                                    messageAsString: userId
                                    ];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)registerOnAppOpenAttribution:(CDVInvokedUrlCommand *)command
{
    mAttributionDataListener = command.callbackId;
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
}

- (void)sendTrackingWithEvent:(CDVInvokedUrlCommand *)command
{
    if ([command.arguments count] < 2) {
        return;
    }
    
    NSString* eventName = [command.arguments objectAtIndex:0];
    NSString* eventValue = [command.arguments objectAtIndex:1];
    [[AppsFlyerTracker sharedTracker] trackEvent:eventName withValue:eventValue];
}


- (void)trackEvent:(CDVInvokedUrlCommand*)command {

    NSString* eventName = [command.arguments objectAtIndex:0];
    NSDictionary* eventValues = [command.arguments objectAtIndex:1];
    [[AppsFlyerTracker sharedTracker] trackEvent:eventName withValues:eventValues];

}

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
        [[AppsFlyerTracker sharedTracker] registerUninstall:deviceTokenData];
    }else{
        NSLog(@"Invalid device token");
    }
}

- (void)getSdkVersion:(CDVInvokedUrlCommand*)command {
    NSString* version = [[AppsFlyerTracker sharedTracker] getSDKVersion];
    CDVPluginResult *pluginResult = [CDVPluginResult
                                        resultWithStatus: CDVCommandStatus_OK
                                        messageAsString: version
                                        ];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

//USER INVITES
    
- (void)setAppInviteOneLinkID:(CDVInvokedUrlCommand*)command {
    if ([command.arguments count] == 0) {
        return;
    }
    NSString* oneLinkID = [command.arguments objectAtIndex:0];
    [AppsFlyerTracker sharedTracker].appInviteOneLinkID = oneLinkID;
}
    
- (void)generateInviteLink:(CDVInvokedUrlCommand*)command {
    NSDictionary* inviteLinkOptions = [command argumentAtIndex:0 withDefault:[NSNull null]];
    NSDictionary* customParams = (NSDictionary*)[inviteLinkOptions objectForKey: @"userParams"];
    
    NSString *channel = nil;
    NSString *campaign = nil;
    NSString *referrerName = nil;
    NSString *referrerImageUrl = nil;
    NSString *customerID = nil;
    NSString *baseDeepLink = nil;
    
    if (![inviteLinkOptions isKindOfClass:[NSNull class]]) {
        channel = (NSString*)[inviteLinkOptions objectForKey: afUiChannel];
        campaign = (NSString*)[inviteLinkOptions objectForKey: afUiCampaign];
        referrerName = (NSString*)[inviteLinkOptions objectForKey: afUiRefName];
        referrerImageUrl = (NSString*)[inviteLinkOptions objectForKey: afUiImageUrl];
        customerID = (NSString*)[inviteLinkOptions objectForKey: afUiCustomerID];
        baseDeepLink = (NSString*)[inviteLinkOptions objectForKey: afUiBaseDeepLink];
        
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
-(void)trackCrossPromotionImpression:(CDVInvokedUrlCommand*) command {
    
    if ([command.arguments count] == 0) {
        return;
    }
    
    NSString* campaign = nil;
    NSString* promtAppID = [command.arguments objectAtIndex:0];
    campaign = [command.arguments objectAtIndex:1];
    
    if (promtAppID != nil && ![promtAppID isEqualToString:@""]) {
        [AppsFlyerCrossPromotionHelper trackCrossPromoteImpression:promtAppID campaign:campaign];
    }
}

-(void)trackAndOpenStore:(CDVInvokedUrlCommand*) command {
    
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


-(void) handleCallback:(NSDictionary *) message{
    NSError *error;
    
    NSData *jsonMessage = [NSJSONSerialization dataWithJSONObject:message
                                                          options:0
                                                            error:&error];
    if (jsonMessage) {
        NSString *jsonMessageStr = [[NSString alloc] initWithBytes:[jsonMessage bytes] length:[jsonMessage length] encoding:NSUTF8StringEncoding];
        
        NSString* status = (NSString*)[message objectForKey: @"status"];
        NSString* type = (NSString*)[message objectForKey: @"type"];
        
        if([status isEqualToString:afSuccess]){
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

-(void) reportOnFailure:(NSString *)errorMessage withType:(NSString *)type{
    
    if([type isEqualToString:afOnAttributionFailure]){
        //TODO
    }
    else if([type isEqualToString:afOnInstallConversionFailure]){
        if (mConversionListenerOnResume != nil) {
            mConversionListenerOnResume = nil;
        }
        
        if(mConversionListener != nil){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:errorMessage];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:NO]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:mConversionListener];
            
            mConversionListener = nil;
        }
    }
}

-(void) reportOnSuccess:(NSString *)data withType:(NSString *)type {
    
    if([type isEqualToString:afOnAppOpenAttribution]){
        if(mAttributionDataListener != nil){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:data];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:NO]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:mAttributionDataListener];
            mAttributionDataListener = nil;
        }
    }
    else if([type isEqualToString:afOnInstallConversionDataLoaded]){
        if (mConversionListenerOnResume != nil) {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:data];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:NO]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:mConversionListenerOnResume];
            
            mConversionListenerOnResume = nil;
        }
        
        if(mConversionListener != nil){
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:data];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:NO]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:mConversionListener];
            
            mConversionListener = nil;
        }
    }
}
- (void) handleOpenUrl:(CDVInvokedUrlCommand*)command {
    NSURL *url = [NSURL URLWithString:
        [[command.arguments objectAtIndex:0]
            stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[AppsFlyerTracker sharedTracker] handleOpenUrl:url options:nil];
}


@end


// Universal Links Support - AppDelegate interface:
@interface AppDelegate (AppsFlyerPlugin)

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler;

@end

// Universal Links Support - AppDelegate implementation:
@implementation AppDelegate (AppsFlyerPlugin)

// Depricated: swizzeled method see AppsFlyerX+AppController.m
// - (BOOL) application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *_Nullable))restorationHandler
// {
//     [[AppsFlyerTracker sharedTracker] continueUserActivity:userActivity restorationHandler:restorationHandler];
//     return YES;
// }

@end
