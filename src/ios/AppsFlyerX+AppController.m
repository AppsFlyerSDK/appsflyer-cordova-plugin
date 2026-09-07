//
//  AppsFlyerX+AppController.m
//  Created by Jonathan Wesfield on 26/12/2018.
//

#import <Foundation/Foundation.h>
#import "AppsFlyerX+AppController.h"
#import <objc/runtime.h>
#import <AppsFlyerLib/AppsFlyerLib.h>

// AppsFlyerAttribution.h was replaced by AppsFlyerAttribution.swift as part of the RPC-core
// migration. A Cordova app compiles plugin sources directly into its single app target, so the
// Xcode-generated "<AppModule>-Swift.h" interface header has no name knowable at plugin-authoring
// time. This forward declaration mirrors AppsFlyerAttribution's @objc(AppsFlyerAttribution)
// surface exactly, so the linker resolves it against the real Swift implementation at build time.
@interface AppsFlyerAttribution : NSObject
+ (AppsFlyerAttribution *)shared;
- (void)continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^_Nullable)(NSArray * _Nullable))restorationHandler;
- (void)handleOpen:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options;
- (void)handleOpen:(NSURL *)url sourceApplication:(NSString * _Nullable)sourceApplication annotation:(id _Nullable)annotation;
- (void)handleLaunchOptions:(NSDictionary * _Nullable)launchOptions;
@end

@implementation AppDelegate (AppsFlyerX)
#ifndef AFSDK_DISABLE_APP_DELEGATE

#pragma mark - Original method exist flags for swizzling
static BOOL isOriginalContinueUserActivityExist;
static BOOL isOriginalOpenURLExist;
static BOOL isOriginalOpenURLOptionsExist;
static BOOL isOriginalDidFinishLaunchingExist;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // application:didFinishLaunchingWithOptions: is always swizzled, never a direct category
        // override (unlike the three methods below): Cordova's generated AppDelegate.m always
        // implements this one itself -- it's where the WebView/root view controller get created.
        // A category method with the same selector silently replaces that implementation instead
        // of coexisting with it, which produces a launched-but-black-screen app with no crash.
        SEL originalSelector4 = @selector(application:didFinishLaunchingWithOptions:);
        SEL swizzledSelector4 = @selector(af_application:didFinishLaunchingWithOptions:);
        [self addSwizzledMethodWithOriginalSelector:originalSelector4 swizzledSelector:swizzledSelector4 methodExistFlag:&isOriginalDidFinishLaunchingExist];

#if AFSDK_SHOULD_SWIZZLE
        SEL originalSelector = @selector(application:continueUserActivity:restorationHandler:);
        SEL swizzledSelector = @selector(af_application: continueUserActivity: restorationHandler:);
        [self addSwizzledMethodWithOriginalSelector:originalSelector swizzledSelector:swizzledSelector methodExistFlag:&isOriginalContinueUserActivityExist];

        SEL originalSelector2 = @selector(application:openURL:sourceApplication:annotation:);
        SEL swizzledSelector2 = @selector(af_application: openURL: sourceApplication: annotation:);
        [self addSwizzledMethodWithOriginalSelector:originalSelector2 swizzledSelector:swizzledSelector2 methodExistFlag:&isOriginalOpenURLExist];

        SEL originalSelector3 = @selector(application:openURL:options:);
        SEL swizzledSelector3 = @selector(af_application:openURL:options:);
        [self addSwizzledMethodWithOriginalSelector:originalSelector3 swizzledSelector:swizzledSelector3 methodExistFlag:&isOriginalOpenURLOptionsExist];
#endif
    });
}

#if !AFSDK_SHOULD_SWIZZLE
#pragma mark - AppDelegate Deep Link implementation
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    [self afLogger:@"[AppsFlyer Category] `application:openURL:options:`"];
    [[AppsFlyerAttribution shared] handleOpen:url options:options];
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    [self afLogger:@"[AppsFlyer Category] `application:continueUserActivity:restorationHandler:`"];
    [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [self afLogger:@"[AppsFlyer Category] `application:openURL:sourceApplication:annotation:`"];
    [[AppsFlyerAttribution shared] handleOpen:url sourceApplication:sourceApplication annotation:annotation];
    return YES;
}
#endif

#pragma mark - Method Swizzling - Deep Link implementation
- (BOOL)af_application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
    [self afLogger:@"[AppsFlyer Swizzled] `application:continueUserActivity:restorationHandler:`"];
    [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
    if (isOriginalContinueUserActivityExist) {
        return   [self af_application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    return YES;
}
- (BOOL)af_application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [self afLogger:@"[AppsFlyer Swizzled] `application:continueUserActivity:restorationHandler:`"];
    [[AppsFlyerAttribution shared] handleOpen:url sourceApplication:sourceApplication annotation:annotation];
    if (isOriginalOpenURLExist) {
        return [self af_application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
    return YES;
}

- (BOOL)af_application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    [self afLogger:@"[AppsFlyer Swizzled] `application:openURL:options:`"];
    [[AppsFlyerAttribution shared] handleOpen:url options:options];
    if (isOriginalOpenURLOptionsExist) {
        return [self af_application:app openURL:url options:options];
    }
    return YES;
}

- (BOOL)af_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self afLogger:@"[AppsFlyer Swizzled] `application:didFinishLaunchingWithOptions:`"];
    [[AppsFlyerAttribution shared] handleLaunchOptions:launchOptions];
    if (isOriginalDidFinishLaunchingExist) {
        return [self af_application:application didFinishLaunchingWithOptions:launchOptions];
    }
    return YES;
}

#pragma mark - Add swizzled methods
+ (void)addSwizzledMethodWithOriginalSelector:(SEL)originalSelector
                             swizzledSelector:(SEL)swizzledSelector
                              methodExistFlag:(BOOL *)methodExistFlag {
    Class class = [self class];
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    *methodExistFlag = [class instancesRespondToSelector:originalSelector];
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

#pragma mark - Logger
- (void)afLogger:(NSString *)log {
    if ([[AppsFlyerLib shared] isDebug]) {
        NSLog(@"[DEBUG] AppsFlyer: %@", log);
    }
}


#endif
@end
