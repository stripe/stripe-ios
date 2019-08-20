//
//  STPRedirectContext.m
//  Stripe
//
//  Created by Brian Dorfman on 3/29/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPRedirectContext.h"
#import "STPRedirectContext+Private.h"

#import "STPBlocks.h"
#import "STPDispatchFunctions.h"
#import "STPPaymentIntent.h"
#import "STPPaymentIntentAction.h"
#import "STPPaymentIntentActionRedirectToURL.h"
#import "STPSource.h"
#import "STPURLCallbackHandler.h"
#import "STPWeakStrongMacros.h"
#import "NSError+Stripe.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^STPBoolCompletionBlock)(BOOL success);

/*
 SFSafariViewController sometimes manages its own dismissal and does not currently provide
 any easier API hooks to detect when the dismissal has completed. This machinery exists to
 insert ourselves into the View Controller transitioning process and detect when a dismissal
 transition has completed.
*/

@interface STPSafariViewControllerPresentationController : UIPresentationController
@property (nonatomic, weak, nullable) id<STPSafariViewControllerDismissalDelegate> dismissalDelegate;
@end

@implementation STPSafariViewControllerPresentationController
- (void)dismissalTransitionDidEnd:(BOOL)completed {
    if ([self.presentedViewController isKindOfClass:[SFSafariViewController class]]) {
        [self.dismissalDelegate safariViewControllerDidCompleteDismissal:(SFSafariViewController *)self.presentedViewController];
    }
    return [super dismissalTransitionDidEnd:completed];
}
@end

@interface STPRedirectContext () <SFSafariViewControllerDelegate, STPURLCallbackListener, UIViewControllerTransitioningDelegate>

@property (nonatomic, strong, nullable) SFSafariViewController *safariVC;
@property (nonatomic, assign, readwrite) STPRedirectContextState state;
/// If we're on iOS 11+ and in the SafariVC flow, this tracks the latest URL loaded/redirected to during the initial load
@property (nonatomic, strong, readwrite, nullable) NSURL *lastKnownSafariVCURL;

@property (nonatomic, assign) BOOL subscribedToURLNotifications;
@property (nonatomic, assign) BOOL subscribedToForegroundNotifications;
@end

@implementation STPRedirectContext

- (nullable instancetype)initWithSource:(STPSource *)source
                             completion:(STPRedirectContextSourceCompletionBlock)completion {

    if (source.flow != STPSourceFlowRedirect
        || !(source.status == STPSourceStatusPending ||
             source.status == STPSourceStatusChargeable)) {
        return nil;
    }

    self = [self initWithNativeRedirectURL:[[self class] nativeRedirectURLForSource:source]
                               redirectURL:source.redirect.url
                                 returnURL:source.redirect.returnURL
                                completion:^(NSError * _Nullable error) {
                                    completion(source.stripeID, source.clientSecret, error);
                                }];
    return self;
}

- (nullable instancetype)initWithPaymentIntent:(STPPaymentIntent *)paymentIntent
                                    completion:(STPRedirectContextPaymentIntentCompletionBlock)completion {
    NSURL *redirectURL = paymentIntent.nextAction.redirectToURL.url;
    NSURL *returnURL = paymentIntent.nextAction.redirectToURL.returnURL;

    if (paymentIntent.status != STPPaymentIntentStatusRequiresAction
        || paymentIntent.nextAction.type != STPIntentActionTypeRedirectToURL
        || !redirectURL
        || !returnURL) {
        return nil;
    }

    return [self initWithNativeRedirectURL:nil
                               redirectURL:redirectURL
                                 returnURL:returnURL
                                completion:^(NSError * _Nullable error) {
                                    completion(paymentIntent.clientSecret, error);
                                }];
}

/**
 Failable initializer for the general case of STPRedirectContext, some URLs and a completion block.
 */
- (nullable instancetype)initWithNativeRedirectURL:(nullable NSURL *)nativeRedirectURL
                                       redirectURL:(nullable NSURL *)redirectURL
                                         returnURL:(NSURL *)returnURL
                                        completion:(STPErrorBlock)completion {
    if ((nativeRedirectURL == nil && redirectURL == nil)
        || returnURL == nil) {
        return nil;
    }

    self = [super init];
    if (self) {
        _nativeRedirectURL = nativeRedirectURL;
        _redirectURL = redirectURL;
        _returnURL = returnURL;
        _completion = completion;

        _subscribedToURLNotifications = NO;
        _subscribedToForegroundNotifications = NO;
    }
    return self;
}

- (void)dealloc {
    [self unsubscribeFromNotificationsAndDismissPresentedViewControllers];
}

- (void)performAppRedirectIfPossibleWithCompletion:(STPBoolCompletionBlock)onCompletion {

    if (self.state == STPRedirectContextStateNotStarted) {
        NSURL *nativeURL = self.nativeRedirectURL;
        if (!nativeURL) {
            onCompletion(NO);
            return;
        }

        // Optimistically start listening in case we get app switched away.
        // If the app switch fails we'll undo this later
        self.state = STPRedirectContextStateInProgress;
        [self subscribeToURLAndForegroundNotifications];

        UIApplication *application = [UIApplication sharedApplication];
        if (@available(iOS 10, *)) {

            WEAK(self);
            [application openURL:nativeURL options:@{} completionHandler:^(BOOL success) {
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
            BOOL opened = [application openURL:nativeURL];
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

    WEAK(self)
    [self performAppRedirectIfPossibleWithCompletion:^(BOOL success) {
        if (!success) {
            STRONG(self)
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

    if (self.state == STPRedirectContextStateNotStarted) {
        _state = STPRedirectContextStateInProgress;
        [self subscribeToURLNotifications];
        self.lastKnownSafariVCURL = self.redirectURL;
        self.safariVC = [[SFSafariViewController alloc] initWithURL:self.lastKnownSafariVCURL];
        self.safariVC.delegate = self;
        self.safariVC.transitioningDelegate = self;
        self.safariVC.modalPresentationStyle = UIModalPresentationCustom;
        [presentingViewController presentViewController:self.safariVC
                                               animated:YES
                                             completion:nil];
    }
}

- (void)startSafariAppRedirectFlow {
    if (self.state == STPRedirectContextStateNotStarted) {
        self.state = STPRedirectContextStateInProgress;
        [self subscribeToURLAndForegroundNotifications];
        [[UIApplication sharedApplication] openURL:self.redirectURL];
    }
}

- (void)cancel {
    if (self.state == STPRedirectContextStateInProgress) {
        self.state = STPRedirectContextStateCancelled;
        [self unsubscribeFromNotificationsAndDismissPresentedViewControllers];
    }
}

#pragma mark - SFSafariViewControllerDelegate -

- (void)safariViewControllerDidFinish:(__unused SFSafariViewController *)controller {
    stpDispatchToMainThreadIfNecessary(^{
        [self handleRedirectCompletionWithError:nil
                    shouldDismissViewController:NO];
    });
}

- (void)safariViewController:(__unused SFSafariViewController *)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully {
    /*
     SafariVC is, imo, over-eager to report errors. The way that (for example) girogate.de redirects
     can cause SafariVC to report that the initial load failed, even though it completes successfully.

     So, only report failures to complete the initial load if the host was a Stripe domain.
     Stripe uses 302 redirects, and this should catch local connection problems as well as
     server-side failures from Stripe.
     */
    if (didLoadSuccessfully == NO) {
        if (@available(iOS 11, *)) {
            stpDispatchToMainThreadIfNecessary(^{
                if ([self.lastKnownSafariVCURL.host containsString:@"stripe.com"]) {
                    [self handleRedirectCompletionWithError:[NSError stp_genericConnectionError]
                                shouldDismissViewController:YES];
                }
            });
        } else {
            /*
             We can only track the latest URL loaded on iOS 11, because `safariViewController:initialLoadDidRedirectToURL:`
             didn't exist prior to that. This might be a spurious error, so we need to ignore it.
             */
        }
    }
}

- (void)safariViewController:(__unused SFSafariViewController *)controller initialLoadDidRedirectToURL:(NSURL *)URL {
    stpDispatchToMainThreadIfNecessary(^{
        // This is only kept up to date during the "initial load", but we only need the value in
        // `safariViewController:didCompleteInitialLoad:`, so that's fine.
        self.lastKnownSafariVCURL = URL;
    });
}

#pragma mark - STPSafariViewControllerDismissalDelegate -

- (void)safariViewControllerDidCompleteDismissal:(__unused SFSafariViewController *)controller {
    self.completion(self.completionError);
    self.completionError = nil;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (nullable UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented
                                                               presentingViewController:(nullable UIViewController *)presenting
                                                                   sourceViewController:(__unused UIViewController *)source {
    STPSafariViewControllerPresentationController *controller = [[STPSafariViewControllerPresentationController alloc] initWithPresentedViewController:presented
                                                                                                                              presentingViewController:presenting];
    controller.dismissalDelegate = self;
    return controller;
}

#pragma mark - Private methods -

- (void)handleWillForegroundNotification {
    // Always `dispatch_async` the `handleWillForegroundNotification` function
    // call to re-queue the task at the end of the run loop. This is so that the
    // `handleURLCallback` gets handled first.
    //
    // Verified this works even if `handleURLCallback` performs `dispatch_async`
    // but not completely sure why :)
    //
    // When returning from a `startSafariAppRedirectFlow` call, the
    // `UIApplicationWillEnterForegroundNotification` handler and
    // `STPURLCallbackHandler` compete. The problem is the
    // `UIApplicationWillEnterForegroundNotification` handler is always queued
    // first causing the `STPURLCallbackHandler` to always fail because the
    // registered callback was already unregistered by the
    // `UIApplicationWillEnterForegroundNotification` handler. We are patching
    // this so that the`STPURLCallbackHandler` can succeed and the
    // `UIApplicationWillEnterForegroundNotification` handler can silently fail.
    dispatch_async(dispatch_get_main_queue(), ^{
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
    
    if ([self isSafariVCPresented]) {
        // SafariVC dismissal delegate will manage calling completion handler
        self.completionError = error;
    } else {
        self.completion(error);
    }
    
    if (shouldDismissViewController) {
        [self dismissPresentedViewController];
    }
}

- (void)subscribeToURLNotifications {
    if (!self.subscribedToURLNotifications) {
        self.subscribedToURLNotifications = YES;
        [[STPURLCallbackHandler shared] registerListener:self
                                                  forURL:self.returnURL];
    }
}

- (void)subscribeToURLAndForegroundNotifications {
    [self subscribeToURLNotifications];
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
    if ([self isSafariVCPresented]) {
        [self.safariVC.presentingViewController dismissViewControllerAnimated:YES
                                                                   completion:nil];
        self.safariVC = nil;
    }
}

- (BOOL)isSafariVCPresented {
    return self.safariVC != nil;
}

+ (nullable NSURL *)nativeRedirectURLForSource:(STPSource *)source {
    NSString *nativeURLString = nil;
    switch (source.type) {
        case STPSourceTypeAlipay:
            nativeURLString = source.details[@"native_url"];
            break;
        default:
            // All other sources currently have no native url support
            break;
    }

    NSURL *nativeURL = nativeURLString ? [NSURL URLWithString:nativeURLString] : nil;
    return nativeURL;
}

@end

NS_ASSUME_NONNULL_END
