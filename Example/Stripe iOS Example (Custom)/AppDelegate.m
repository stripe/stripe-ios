//
//  AppDelegate.m
//  StripeExample
//
//  Created by Jack Flintermann on 8/21/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "AppDelegate.h"
#import "Constants.h"
#import "BrowseExamplesViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if (StripePublishableKey) {
        [Stripe setDefaultPublishableKey:StripePublishableKey];
    }
    UIViewController *rootVC = [[BrowseExamplesViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootVC];
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.rootViewController = nav;
    [window makeKeyAndVisible];
    self.window = window;
    return YES;
}

@end
