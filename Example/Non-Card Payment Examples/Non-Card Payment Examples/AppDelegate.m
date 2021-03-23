//
//  AppDelegate.m
//  StripeExample
//
//  Created by Jack Flintermann on 8/21/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

@import Stripe;
#import "AppDelegate.h"
#import "Constants.h"
#import "BrowseExamplesViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (StripePublishableKey) {
        [StripeAPI setDefaultPublishableKey:StripePublishableKey];
    }
    UIViewController *rootVC = [[BrowseExamplesViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootVC];
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.rootViewController = nav;
    [window makeKeyAndVisible];
    self.window = window;
    return YES;
}

/**
 This method is implemented to route returnURLs back to the Stripe SDK.
 
 @see https://stripe.com/docs/mobile/ios/authentication#return-url
 */
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    BOOL stripeHandled = [StripeAPI handleStripeURLCallbackWithURL:url];
    if (stripeHandled) {
        return YES;
    } else {
        // This was not a stripe url – do whatever url handling your app
        // normally does, if any.
    }
    return NO;
}

@end
