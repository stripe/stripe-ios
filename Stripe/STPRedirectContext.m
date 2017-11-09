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

@property (nonatomic, assign) BOOL subscribedToURLNotifications;
@property (nonatomic, assign) BOOL subscribedToForegroundNotifications;
@end

@implementation STPRedirectContext

- (nullable instancetype)initWithSource:(STPSource *)source
                             completion:(STPRedirectContextCompletionBlock)completion {

    if (source.flow != STPSourceFlowRedirect
        || source.status != STPSourceStatusPending
        || source.redirect.returnURL == nil
        || (source.redirect.url == nil
            && [self nativeRedirectURLForSource:source] == nil)) {
        return nil;
    }

    self = [super init];
    if (self) {
        _source = source;
        _completion = [completion copy];
        _subscribedToURLNotifications = NO;
        _subscribedToForegroundNotifications = NO;
    }
    return self;
}

- (void)dealloc {
    [self unsubscribeFromNotificationsAndDismissPresentedViewControllers];
}

- (void)performAppRedirectIfPossibleWithCompletion:(STPBoolCompletionBlock)onCompletion {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability)

    if (self.state == STPRedirectContextStateNotStarted) {
        NSURL *nativeUrl = [self nativeRedirectURLForSource:self.source];
        if (!nativeUrl) {
            onCompletion(NO);
            return;
        }

        // Optimistically start listening in case we get app switched away.
        // If the app switch fails we'll undo this later
        self.state = STPRedirectContextStateInProgress;
        [self subscribeToUrlAndForegroundNotifications];

        UIApplication *application = [UIApplication sharedApplication];
        if ([application respondsToSelector:@selector(openURL:options:completionHandler:)]) {

            WEAK(self);
            [application openURL:nativeUrl options:@{} completionHandler:^(BOOL success) {
                if (!success) {
                    STRONG(self);
                    self.state = STPRedirectContextStateNotStarted;
                    [self unsubscribeFromNotifications];
                }
                onCompletion(success);
            }];
        }
        else {
            _state = STPRedirectContextStateInProgress;
            BOOL opened = [application openURL:nativeUrl];
            if (!opened) {
                self.state = STPRedirectContextStateNotStarted;
                [self unsubscribeFromNotifications];
            }
            onCompletion(opened);
        }
    }
    else {
        onCompletion(NO);
    }
}

- (void)startRedirectFlowFromViewController:(UIViewController *)presentingViewController {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability)

    [self performAppRedirectIfPossibleWithCompletion:^(BOOL success) {
        if (!success) {
            if ([SFSafariViewController class] != nil) {
                [self startSafariViewControllerRedirectFlowFromViewController:presentingViewController];
            }
            else {
                [self startSafariAppRedirectFlow];
            }
        }
    }];
}

- (void)startSafariViewControllerRedirectFlowFromViewController:(UIViewController *)presentingViewController {
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability)
    if (self.state == STPRedirectContextStateNotStarted) {
        _state = STPRedirectContextStateInProgress;
        [self subscribeToUrlNotifications];
        self.safariVC = [[SFSafariViewController alloc] initWithURL:self.source.redirect.url];
        self.safariVC.delegate = self;
        [presentingViewController presentViewController:self.safariVC
                                               animated:YES
                                             completion:nil];
    }
}

- (void)startSafariAppRedirectFlow {
    if (self.state == STPRedirectContextStateNotStarted) {
        self.state = STPRedirectContextStateInProgress;
        [self subscribeToUrlAndForegroundNotifications];
        [[UIApplication sharedApplication] openURL:self.source.redirect.url];
    }
}

- (void)cancel {
    if (self.state == STPRedirectContextStateInProgress) {
        self.state = STPRedirectContextStateCancelled;
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

    self.state = STPRedirectContextStateCompleted;

    [self unsubscribeFromNotifications];

    if (shouldDismissViewController) {
        [self dismissPresentedViewController];
    }

    self.completion(self.source.stripeID, self.source.clientSecret, error);
}

- (void)subscribeToUrlNotifications {
    if (!self.subscribedToURLNotifications) {
        self.subscribedToURLNotifications = YES;
        [[STPURLCallbackHandler shared] registerListener:self
                                                  forURL:self.source.redirect.returnURL];
    }
}

- (void)subscribeToUrlAndForegroundNotifications {
    [self subscribeToUrlNotifications];
    if (!self.subscribedToForegroundNotifications) {
        self.subscribedToForegroundNotifications = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleWillForegroundNotification)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
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
    self.subscribedToURLNotifications = NO;
    self.subscribedToForegroundNotifications = NO;
}

- (void)dismissPresentedViewController {
    if (self.safariVC) {
        [self.safariVC.presentingViewController dismissViewControllerAnimated:YES
                                                                   completion:nil];
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
