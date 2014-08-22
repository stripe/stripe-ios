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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [Stripe setDefaultPublishableKey:StripePublishableKey];
    [Parse setApplicationId:ParseApplicationId
                  clientKey:ParseClientKey];
    return YES;
}

@end
