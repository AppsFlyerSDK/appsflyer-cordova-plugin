//
//  AppsFlyerX+AppController.m
//  Created by Jonathan Wesfield on 26/12/2018.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import <objc/runtime.h>
#import <AppsFlyerLib/AppsFlyerLib.h>

// Forward declaration mirroring AppsFlyerAttribution.swift's @objc(AppsFlyerAttribution) surface: a Cordova app compiles plugin sources into its own app target, so the Xcode-generated "<AppModule>-Swift.h" name isn't knowable at plugin-authoring time, and this lets the linker resolve it at build time instead.
// test-app/hooks/afqa-ios-simctl-deeplink-replay.js reads this declaration straight out of this file at run time (rather than keeping its own copy) to inject the same @interface into generated AppDelegate.m for simctl deep-link replay — this block is the single source of truth for both.
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
        SEL originalSelector4 = @selector(application:didFinishLaunchingWithOptions:);
        SEL swizzledSelector4 = @selector(af_application:didFinishLaunchingWithOptions:);
        [self addSwizzledMethodWithOriginalSelector:originalSelector4 swizzledSelector:swizzledSelector4 methodExistFlag:&isOriginalDidFinishLaunchingExist];

        SEL originalSelector = @selector(application:continueUserActivity:restorationHandler:);
        SEL swizzledSelector = @selector(af_application:continueUserActivity:restorationHandler:);
        [self addSwizzledMethodWithOriginalSelector:originalSelector swizzledSelector:swizzledSelector methodExistFlag:&isOriginalContinueUserActivityExist];

        SEL originalSelector2 = @selector(application:openURL:sourceApplication:annotation:);
        SEL swizzledSelector2 = @selector(af_application:openURL:sourceApplication:annotation:);
        [self addSwizzledMethodWithOriginalSelector:originalSelector2 swizzledSelector:swizzledSelector2 methodExistFlag:&isOriginalOpenURLExist];

        SEL originalSelector3 = @selector(application:openURL:options:);
        SEL swizzledSelector3 = @selector(af_application:openURL:options:);
        [self addSwizzledMethodWithOriginalSelector:originalSelector3 swizzledSelector:swizzledSelector3 methodExistFlag:&isOriginalOpenURLOptionsExist];
    });
}

#pragma mark - Method Swizzling - Deep Link implementation
- (BOOL)af_application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
    [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
    if (isOriginalContinueUserActivityExist) {
        return [self af_application:application continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    return YES;
}

- (BOOL)af_application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [[AppsFlyerAttribution shared] handleOpen:url sourceApplication:sourceApplication annotation:annotation];
    if (isOriginalOpenURLExist) {
        return [self af_application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
    return YES;
}

- (BOOL)af_application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    [[AppsFlyerAttribution shared] handleOpen:url options:options];
    if (isOriginalOpenURLOptionsExist) {
        return [self af_application:app openURL:url options:options];
    }
    return YES;
}

- (BOOL)af_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
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
