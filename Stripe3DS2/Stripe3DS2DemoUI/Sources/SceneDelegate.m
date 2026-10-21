//
//  SceneDelegate.m
//  Stripe3DS2DemoUI
//
//  Copyright © 2026 Stripe. All rights reserved.
//

@import Stripe3DS2;

#import "SceneDelegate.h"
#import "STDSDemoViewController.h"
#import "STDSImageLoader.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];

    STDSImageLoader *imageLoader = [[STDSImageLoader alloc] initWithURLSession:NSURLSession.sharedSession];
    STDSDemoViewController *demoViewController = [[STDSDemoViewController alloc] initWithImageLoader:imageLoader];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:demoViewController];

    self.window.rootViewController = navigationController;

    [self.window makeKeyAndVisible];
}

@end
