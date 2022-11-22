//
//  AppDelegate.m
//  Stripe3DS2DemoUI
//
//  Created by Andrew Harrison on 2/27/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

@import Stripe3DS2;

#import "AppDelegate.h"
#import "STDSDemoViewController.h"
#import "STDSImageLoader.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    STDSImageLoader *imageLoader = [[STDSImageLoader alloc] initWithURLSession:NSURLSession.sharedSession];
    STDSDemoViewController *demoViewController = [[STDSDemoViewController alloc] initWithImageLoader:imageLoader];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:demoViewController];
    
    self.window.rootViewController = navigationController;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
