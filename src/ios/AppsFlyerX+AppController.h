//
//  AppsFlyerX+AppController.h
//  Created by Jonathan Wesfield on 26/12/2018.
//

#import "AppDelegate.h"


@interface AppDelegate (AppsFlyerX)

-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options;

-(BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler;

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

+(void)addSwizzledMethod:(SEL _Nonnull )originalSelector swizzledSelector:(SEL _Nonnull)swizzledSelector methodExistFlag:(BOOL*_Nonnull)methodExistFlag;

+(void)enableSwizzling;

-(void)afLogger:(NSString*)log;
@end
