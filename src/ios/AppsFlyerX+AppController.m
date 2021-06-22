//
//  AppsFlyerX+AppController.m
//  Created by Jonathan Wesfield on 26/12/2018.
//

#import <Foundation/Foundation.h>
#import "AppsFlyerX+AppController.h"
#import <objc/runtime.h>
#import "AppsFlyerAttribution.h"

@implementation AppDelegate (AppsFlyerX)
BOOL useDeepLink;

-(id) init{
    if (self = [super init]) {
        id deepLinkFlag = [[NSBundle mainBundle] objectForInfoDictionaryKey:APPSFLYER_DEEPLINK_FLAG];
        useDeepLink = deepLinkFlag ? ![deepLinkFlag boolValue] : YES;
    }
    return  self;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    if(useDeepLink){
        [[AppsFlyerAttribution shared] handleOpenUrl:url options:options];
    }
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler{
    if(useDeepLink){
        [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    if(useDeepLink){
        [[AppsFlyerAttribution shared] handleOpenUrl:url sourceApplication:sourceApplication annotation:annotation];
    }
    return YES;
}

@end
