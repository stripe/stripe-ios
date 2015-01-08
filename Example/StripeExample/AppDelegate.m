//
//  AppDelegate.m
//  StripeExample
//
//  Created by Jack Flintermann on 8/21/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "AppDelegate.h"
#import "Stripe.h"
#import "Constants.h"
#import <Parse/Parse.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (StripePublishableKey) {
        [Stripe setDefaultPublishableKey:StripePublishableKey];
    }
    if (ParseApplicationId && ParseClientKey) {
        [Parse setApplicationId:ParseApplicationId clientKey:ParseClientKey];
    }
    return YES;
}

@end
