//
//  AppsFlyerX+AppController.m
//  Created by Jonathan Wesfield on 26/12/2018.
//

#import <Foundation/Foundation.h>
#import "AppsFlyerX+AppController.h"
#import <objc/runtime.h>
#import "AppsFlyerAttribution.h"

@implementation AppDelegate (AppsFlyerX)

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    [[AppsFlyerAttribution shared] handleOpenUrl:url options:options];
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler{
    [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
    return YES;
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    [[AppsFlyerAttribution shared] handleOpenUrl:url sourceApplication:sourceApplication annotation:annotation];
    return YES;
}

@end
