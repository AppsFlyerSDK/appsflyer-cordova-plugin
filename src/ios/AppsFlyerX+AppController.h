//
//  AppsFlyerX+AppController.h
//  Created by Jonathan Wesfield on 26/12/2018.
//

#import "AppDelegate.h"

#define APPSFLYER_DEEPLINK_FLAG @"AppsFlyerDisableDeepLinks"

@interface AppDelegate (AppsFlyerX)

-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options;

-(BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler;

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

@end
