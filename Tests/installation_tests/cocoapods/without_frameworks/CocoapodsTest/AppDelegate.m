//
//  AppDelegate.m
//  CocoapodsTest
//
//  Created by Jack Flintermann on 8/4/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    ViewController *rootVC = [ViewController new];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:rootVC];
    UIWindow *window = [UIWindow new];
    window.rootViewController = nc;
    [window makeKeyAndVisible];
    self.window = window;
    return YES;
}

@end
