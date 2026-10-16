//
//  AppDelegate.m
//  StripeExample
//
//  Created by Jack Flintermann on 8/21/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

@import Stripe;
@import StripeCore;
#import "AppDelegate.h"
#import "Constants.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (StripePublishableKey) {
        [StripeAPI setDefaultPublishableKey:StripePublishableKey];
    }
    // The window and returnURL handling live in `SceneDelegate`, since UIKit
    // routes URLs to the scene rather than the app delegate when using the
    // scene-based life cycle.
    return YES;
}

@end
