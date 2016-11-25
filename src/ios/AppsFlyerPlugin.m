#import "AppsFlyerPlugin.h"
#import "AppsFlyerTracker.h"

@implementation AppsFlyerPlugin


static NSString *const NO_DEVKEY_FOUND = @"No 'devKey' found or its empty";
static NSString *const NO_APPID_FOUND  = @"No 'appId' found or its empty";
static NSString *const SUCCESS         = @"Success";

 NSString* mConversionListener;

- (void)pluginInitialize{}

- (void)initSdk:(CDVInvokedUrlCommand*)command
{
    NSDictionary* initSdkOptions = [command argumentAtIndex:0 withDefault:[NSNull null]];
    
    NSString* devKey = nil;
    NSString* appId = nil;
    BOOL isDebug = NO;
    BOOL isConversionData = NO;
    
    if (![initSdkOptions isKindOfClass:[NSNull class]]) {
        
        id value = nil;
        id isConversionDataValue = nil;
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

- (void)getAppsFlyerUID:(CDVInvokedUrlCommand *)command
{
    NSString* userId = [[AppsFlyerTracker sharedTracker] getAppsFlyerUID];
    CDVPluginResult *pluginResult = [ CDVPluginResult
                                    resultWithStatus    : CDVCommandStatus_OK
                                    messageAsString: userId
                                    ];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
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

    NSData* token = [command.arguments objectAtIndex:0];
    NSString *deviceToken = [NSString stringWithFormat:@"%@",token];
    
    if(deviceToken!=nil){
        [[AppsFlyerTracker sharedTracker] registerUninstall:token];
    }else{
        NSLog(@"Invalid device token");
    }
}


-(void)onConversionDataReceived:(NSDictionary*) installData {
    
    NSDictionary* message = @{
                              @"status": afSuccess,
                              @"type": afOnInstallConversionDataLoaded,
                              @"data": installData
                              };
    
    [self performSelectorOnMainThread:@selector(handleCallback:) withObject:message waitUntilDone:NO];
}


-(void)onConversionDataRequestFailure:(NSError *) _errorMessage {
    
    NSDictionary* errorMessage = @{
                                   @"status": afFailure,
                                   @"type": afOnInstallConversionFailure,
                                   @"data": _errorMessage
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
                                   @"data": _errorMessage
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
        
        if([status isEqualToString:afSuccess]){
            [self reportOnSuccess:jsonMessageStr];
        }
        else{
            [self reportOnFailure:jsonMessageStr];
        }
        
        NSLog(@"jsonMessageStr = %@",jsonMessageStr);
    } else {
        NSLog(@"%@",error);
    }
}

-(void) reportOnFailure:(NSString *)errorMessage {
    
    if(mConversionListener != nil){
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:errorMessage];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:NO]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:mConversionListener];
        
        mConversionListener = nil;
    }}

-(void) reportOnSuccess:(NSString *)data {
    
    if(mConversionListener != nil){
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:data];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:NO]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:mConversionListener];
        
        mConversionListener = nil;
     }
}

@end
