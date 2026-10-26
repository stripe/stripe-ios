//
//  SceneDelegate.m
//  Non-Card Payment Examples
//

@import Stripe;
@import StripeCore;
#import "SceneDelegate.h"
#import "BrowseExamplesViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    UIViewController *rootVC = [[BrowseExamplesViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootVC];
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    // The examples use an opaque navigation bar whose default scroll edge appearance is
    // transparent, so the window shows through it. Without a background color, that's black.
    window.backgroundColor = [UIColor systemBackgroundColor];
    window.rootViewController = nav;
    [window makeKeyAndVisible];
    self.window = window;

    // Handle any URL that launched the app.
    if (connectionOptions.URLContexts.count > 0) {
        [self scene:scene openURLContexts:connectionOptions.URLContexts];
    }
}

/**
 This method is implemented to route returnURLs back to the Stripe SDK.

 @see https://stripe.com/docs/payments/3d-secure#return-url
 */
- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    NSURL *url = URLContexts.anyObject.URL;
    if (url == nil) {
        return;
    }
    BOOL stripeHandled = [StripeAPI handleStripeURLCallbackWithURL:url];
    if (!stripeHandled) {
        // This was not a stripe url – do whatever url handling your app
        // normally does, if any.
    }
}

@end
