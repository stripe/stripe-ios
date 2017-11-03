//
//  STPRedirectContext.m
//  Stripe
//
//  Created by Brian Dorfman on 3/29/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPRedirectContext.h"

#import "STPDispatchFunctions.h"
#import "STPSource.h"
#import "STPURLCallbackHandler.h"
#import "STPWeakStrongMacros.h"
#import "NSError+Stripe.h"

#import <SafariServices/SafariServices.h>

#define FAUXPAS_IGNORED_IN_METHOD(...)

NS_ASSUME_NONNULL_BEGIN

typedef void (^STPBoolCompletionBlock)(BOOL success);

@interface STPRedirectContext () <SFSafariViewControllerDelegate, STPURLCallbackListener>

@property (nonatomic, copy) STPRedirectContextCompletionBlock completion;
@property (nonatomic, strong) STPSource *source;
@property (nonatomic, strong, nullable) SFSafariViewController *safariVC;
@property (nonatomic, assign, readwrite) STPRedirectContextState state;

@end

@implementation STPRedirectContext

- (nullable instancetype)initWithSource:(STPSource *)source completion:(STPRedirectContextCompletionBlock)completion {
    if (![self shouldInitWithSource:source]) {
        return nil;
    }

    self = [super init];
    if (self) {
        _source = source;
        _completion = [completion copy];
    }
    return self;
}

- (BOOL)shouldInitWithSource:(STPSource *)source {
    if (source.flow != STPSourceFlowRedirect) {
        // Source flow does not require a redirect
        return NO;
    }

    if (source.status != STPSourceStatusPending) {
        // Source status is not awaiting a redirect
        return NO;
    }

    if (source.redirect.returnURL == nil) {
        // Source redirect is missing `returnURL` for host app
        return NO;
    }

    if (source.redirect.url == nil && [self nativeRedirectURLForSource:source] == nil) {
        // Source does not have destination redirect url
        return NO;
    }

    return YES;
}

- (void)dealloc {
    [self unsubscribeFromUrlAndForegroundNotificationsAndDismissPresentedViewControllers];
}

- (void)startNativeAppRedirectFlowIfPossibleWithCompletion:(STPBoolCompletionBlock)onCompletion {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability)  // Ignore reference to new app redirect API

    if (self.state != STPRedirectContextStateNotStarted) {
        // Redirect already in progress, cancelled, completed, etc
        onCompletion(NO);
        return;
    }

    NSURL *nativeUrl = [self nativeRedirectURLForSource:self.source];
    if (!nativeUrl) {
        // Source does not support native app redirects
        onCompletion(NO);
        return;
    }

    // Switch to in progress state to prevent multiple redirect flow starts
    self.state = STPRedirectContextStateInProgress;

    // Start listening before performing the app switch in case execution stops and undo if it fails
    [self subscribeToUrlAndForegroundNotifications];

    UIApplication *application = [UIApplication sharedApplication];

    if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {
        // Use new iOS 10+ app open url API
        WEAK(self);
        [application openURL:nativeUrl options:@{} completionHandler:^(BOOL success) {
            STRONG(self);
            if (!success) {
                // Reset state and stop listening
                self.state = STPRedirectContextStateNotStarted;
                [self unsubscribeFromUrlAndForegroundNotifications];
            }
            onCompletion(success);
        }];
    }
    else {
        // Use legacy app open url API
        BOOL opened = [application openURL:nativeUrl];
        if (!opened) {
            // Reset state and stop listening
            self.state = STPRedirectContextStateNotStarted;
            [self unsubscribeFromUrlAndForegroundNotifications];
        }
        onCompletion(opened);
    }
}

- (void)startRedirectFlowFromViewController:(UIViewController *)presentingViewController {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability)  // Ignore reference to `SFSafariViewController`

    // Try native app redirect
    WEAK(self);
    [self startNativeAppRedirectFlowIfPossibleWithCompletion:^(BOOL success) {
        STRONG(self);
        if (!success) {
            if ([SFSafariViewController class] != nil) {
                // Fallback to new `SFSafariViewController` redirect
                [self startSafariViewControllerRedirectFlowFromViewController:presentingViewController];
            }
            else {
                // Fallback to legacy Safari app redirect
                [self startSafariAppRedirectFlow];
            }
        }
    }];
}

- (void)startSafariViewControllerRedirectFlowFromViewController:(UIViewController *)presentingViewController {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability)  // Ignore reference to `SFSafariViewController`

    if (self.state != STPRedirectContextStateNotStarted) {
        // Redirect already in progress, cancelled, completed, etc
        return;
    }

    // Switch to in progress state to prevent multiple redirect flow starts
    self.state = STPRedirectContextStateInProgress;

    // Start listening before presenting the `SFSafariViewController` in case it causes an app switch due to universal link handling
    [self subscribeToUrlAndForegroundNotifications];

    // Present `SFSafariViewController` with source redirect url
    self.safariVC = [[SFSafariViewController alloc] initWithURL:self.source.redirect.url];
    self.safariVC.delegate = self;
    [presentingViewController presentViewController:self.safariVC animated:YES completion:nil];
}

- (void)startSafariAppRedirectFlow {
    if (self.state != STPRedirectContextStateNotStarted) {
        // Redirect already in progress, cancelled, completed, etc
        return;
    }

    // Switch to in progress state to prevent multiple redirect flow starts
    self.state = STPRedirectContextStateInProgress;

    // Start listening before performing the app open url in case execution stops
    [self subscribeToUrlAndForegroundNotifications];

    // Perform app open url to Safari app or trigger universal link handling
    [[UIApplication sharedApplication] openURL:self.source.redirect.url];
}

- (void)cancel {
    if (self.state != STPRedirectContextStateInProgress) {
        // Redirect in a state that does not need to be cancelled
        return;
    }

    // Switch to cancelled state to prevent completion block activation
    self.state = STPRedirectContextStateCancelled;

    // Stop listening and dismiss any view controllers
    [self unsubscribeFromUrlAndForegroundNotificationsAndDismissPresentedViewControllers];
}

#pragma mark - SFSafariViewControllerDelegate -

- (void)safariViewControllerDidFinish:(__unused SFSafariViewController *)controller { FAUXPAS_IGNORED_ON_LINE(APIAvailability)
    stpDispatchToMainThreadIfNecessary(^{
        // User tapped "Done" in `SFSafariViewController`
        [self handleRedirectCompletionWithError:nil shouldDismissViewController:NO];
    });
}

- (void)safariViewController:(__unused SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully { FAUXPAS_IGNORED_ON_LINE(APIAvailability)
    if (didLoadSuccessfully == NO) {
        stpDispatchToMainThreadIfNecessary(^{
            // Common connection error while loading the destination url
            NSError *error = [NSError stp_genericConnectionError];
            [self handleRedirectCompletionWithError:error shouldDismissViewController:YES];
        });
    }
}

#pragma mark - Private Methods -

- (void)handleApplicationWillEnterForegroundNotification {
    stpDispatchToMainThreadIfNecessary(^{
        [self handleRedirectCompletionWithError:nil shouldDismissViewController:YES];
    });
}

- (BOOL)handleURLCallback:(__unused NSURL *)url {
    stpDispatchToMainThreadIfNecessary(^{
        [self handleRedirectCompletionWithError:nil shouldDismissViewController:YES];
    });

    // We handle all returned urls that match what we registered for
    return YES;
}

- (void)handleRedirectCompletionWithError:(nullable NSError *)error shouldDismissViewController:(BOOL)shouldDismissViewController {
    if (self.state != STPRedirectContextStateInProgress) {
        return;
    }

    self.state = STPRedirectContextStateCompleted;

    [self unsubscribeFromUrlAndForegroundNotifications];

    if (shouldDismissViewController) {
        [self dismissPresentedViewController];
    }

    self.completion(self.source.stripeID, self.source.clientSecret, error);
}

- (void)subscribeToUrlAndForegroundNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillEnterForegroundNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[STPURLCallbackHandler shared] registerListener:self forURL:self.source.redirect.returnURL];
}

- (void)unsubscribeFromUrlAndForegroundNotificationsAndDismissPresentedViewControllers {
    [self unsubscribeFromUrlAndForegroundNotifications];
    [self dismissPresentedViewController];
}

- (void)unsubscribeFromUrlAndForegroundNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[STPURLCallbackHandler shared] unregisterListener:self];
}

- (void)dismissPresentedViewController {
    if (self.safariVC) {
        [self.safariVC.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (nullable NSURL *)nativeRedirectURLForSource:(STPSource *)source {
    NSString *nativeUrlString = nil;
    switch (source.type) {
        case STPSourceTypeAlipay:
            nativeUrlString = source.details[@"native_url"];
            break;
        default:
            // All other sources currently have no native url support
            break;
    }

    NSURL *nativeUrl = nativeUrlString ? [NSURL URLWithString:nativeUrlString] : nil;
    return nativeUrl;
}

@end

NS_ASSUME_NONNULL_END
