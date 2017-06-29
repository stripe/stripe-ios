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
#import "StripeError.h"

#import <SafariServices/SafariServices.h>

#define FAUXPAS_IGNORED_IN_METHOD(...)

NS_ASSUME_NONNULL_BEGIN

@interface STPRedirectContext () <SFSafariViewControllerDelegate, STPURLCallbackListener>
@property (nonatomic, copy) STPRedirectContextCompletionBlock completion;
@property (nonatomic, strong) STPSource *source;
@property (nonatomic, strong, nullable) SFSafariViewController *safariVC;
@end

@implementation STPRedirectContext

- (nullable instancetype)initWithSource:(STPSource *)source
                             completion:(STPRedirectContextCompletionBlock)completion {

    if (source.flow != STPSourceFlowRedirect
        || source.redirect.url == nil
        || source.redirect.returnURL == nil) {
        return nil;
    }

    self = [super init];
    if (self) {
        _source = source;
        _completion = [completion copy];
    }
    return self;
}

- (void)dealloc {
    [self unsubscribeFromNotificationsAndDismissPresentedViewControllers];
}

- (void)startRedirectFlowFromViewController:(UIViewController *)presentingViewController {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability)
    if ([SFSafariViewController class] != nil) {
        [self startSafariViewControllerRedirectFlowFromViewController:presentingViewController];
    }
    else {
        [self startSafariAppRedirectFlow];
    }
}

- (void)startSafariViewControllerRedirectFlowFromViewController:(UIViewController *)presentingViewController {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability)
    if (self.state == STPRedirectContextStateNotStarted) {
        _state = STPRedirectContextStateInProgress;
        [self subscribeToUrlAndForegroundNotifications];
        self.safariVC = [[SFSafariViewController alloc] initWithURL:self.source.redirect.url];
        self.safariVC.delegate = self;
        [presentingViewController presentViewController:self.safariVC
                                               animated:YES
                                             completion:nil];
    }
}

- (void)startSafariAppRedirectFlow {
    if (self.state == STPRedirectContextStateNotStarted) {
        _state = STPRedirectContextStateInProgress;
        [self subscribeToUrlAndForegroundNotifications];
        [[UIApplication sharedApplication] openURL:self.source.redirect.url];
    }
}

- (void)cancel {
    if (self.state == STPRedirectContextStateInProgress) {
        _state = STPRedirectContextStateCancelled;
        [self unsubscribeFromNotificationsAndDismissPresentedViewControllers];
    }
}

#pragma mark - SFSafariViewControllerDelegate -

- (void)safariViewControllerDidFinish:(__unused SFSafariViewController *)controller { FAUXPAS_IGNORED_ON_LINE(APIAvailability)
    stpDispatchToMainThreadIfNecessary(^{
        [self handleRedirectCompletionWithError:nil
                    shouldDismissViewController:NO];
    });
}

- (void)safariViewController:(__unused SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully { FAUXPAS_IGNORED_ON_LINE(APIAvailability)
    if (didLoadSuccessfully == NO) {
        stpDispatchToMainThreadIfNecessary(^{
            [self handleRedirectCompletionWithError:[NSError stp_genericConnectionError]
                        shouldDismissViewController:YES];
        });
    }
}

#pragma mark - Private methods -

- (void)handleWillForegroundNotification {
    stpDispatchToMainThreadIfNecessary(^{
        [self handleRedirectCompletionWithError:nil
                    shouldDismissViewController:YES];
    });
}

- (BOOL)handleURLCallback:(__unused NSURL *)url {
    stpDispatchToMainThreadIfNecessary(^{
        [self handleRedirectCompletionWithError:nil
                    shouldDismissViewController:YES];
    });
    // We handle all returned urls that match what we registered for
    return YES;
}

- (void)handleRedirectCompletionWithError:(nullable NSError *)error
              shouldDismissViewController:(BOOL)shouldDismissViewController {
    if (self.state != STPRedirectContextStateInProgress) {
        return;
    }

    _state = STPRedirectContextStateCompleted;

    [self unsubscribeFromNotifications];

    if (shouldDismissViewController) {
        [self dismissPresentedViewController];
    }

    self.completion(self.source.stripeID, self.source.clientSecret, error);
}

- (void)subscribeToUrlAndForegroundNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillForegroundNotification)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[STPURLCallbackHandler shared] registerListener:self
                                              forURL:self.source.redirect.returnURL];
}

- (void)unsubscribeFromNotificationsAndDismissPresentedViewControllers {
    [self unsubscribeFromNotifications];
    [self dismissPresentedViewController];
}

- (void)unsubscribeFromNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    [[STPURLCallbackHandler shared] unregisterListener:self];
}

- (void)dismissPresentedViewController {
    if (self.safariVC) {
        [self.safariVC.presentingViewController dismissViewControllerAnimated:YES
                                                                   completion:nil];
    }
}

@end

NS_ASSUME_NONNULL_END
