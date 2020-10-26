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
#import "STPSourceWeChatPayDetails.h"
#import "STPURLCallbackHandler.h"
#import "NSError+Stripe.h"

NSString *const STPRedirectContextErrorDomain = @"STPRedirectContextErrorDomain";

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
@property (nonatomic, strong, readwrite, nullable) STPSource *source;

@property (nonatomic, assign) BOOL subscribedToURLNotifications;
@property (nonatomic, assign) BOOL subscribedToAppActiveNotifications;
@end

@implementation STPRedirectContext

- (nullable instancetype)initWithSource:(STPSource *)source
                             completion:(STPRedirectContextSourceCompletionBlock)completion {

    if ((source.flow != STPSourceFlowRedirect && source.type != STPSourceTypeWeChatPay)
        || !(source.status == STPSourceStatusPending ||
             source.status == STPSourceStatusChargeable)) {
        return nil;
    }
    _source = source;
    
    NSURL *nativeRedirectURL = [[self class] nativeRedirectURLForSource:source];
    NSURL *returnURL = source.redirect.returnURL;
    
    if (source.type == STPSourceTypeWeChatPay) {
        // Construct the returnURL for WeChat Pay:
        //   - nativeRedirectURL looks like "weixin://app/MERCHANT_APP_ID/pay/?..."
        //   - the WeChat app will redirect back using a URL like "MERCHANT_APP_ID://pay/?..."
        NSString *merchantAppID = nativeRedirectURL.pathComponents[1];
        returnURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://pay/", merchantAppID]];
    }
    
    self = [self initWithNativeRedirectURL:nativeRedirectURL
                               redirectURL:source.redirect.url
                                 returnURL:returnURL
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
        _subscribedToAppActiveNotifications = NO;
    }
    return self;
}

- (void)dealloc {
    [self unsubscribeFromNotificationsAndDismissPresentedViewControllers];
}

- (void)startRedirectFlowFromViewController:(UIViewController *)presentingViewController {

    if (self.state == STPRedirectContextStateNotStarted) {
        self.state = STPRedirectContextStateInProgress;
        [self subscribeToURLAndAppActiveNotifications];

        __weak typeof(self) weakSelf = self;
        [self performAppRedirectIfPossibleWithCompletion:^(BOOL success) {
            if (success) {
                return;
            }
            
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf == nil) {
                return;
            }
            // Redirect failed...
            if (strongSelf.source.type == STPSourceTypeWeChatPay) {
                // ...and this Source doesn't support web-based redirect — finish with an error.
                NSError *error = [[NSError alloc] initWithDomain:STPRedirectContextErrorDomain
                                                            code:STPRedirectContextAppRedirectError
                                                        userInfo:@{
                                                                   NSLocalizedDescriptionKey: [NSError stp_unexpectedErrorMessage],
                                                                   STPErrorMessageKey: @"Redirecting to WeChat failed. Only offer WeChat Pay if the WeChat app is installed.",
                                                                   }];
                stpDispatchToMainThreadIfNecessary(^{
                    [strongSelf handleRedirectCompletionWithError:error shouldDismissViewController:NO];
                });
            } else {
                // ...reset our state and try a web redirect
                strongSelf.state = STPRedirectContextStateNotStarted;
                [strongSelf unsubscribeFromNotifications];
                if ([SFSafariViewController class] != nil) {
                    [strongSelf startSafariViewControllerRedirectFlowFromViewController:presentingViewController];
                } else {
                    [strongSelf startSafariAppRedirectFlow];
                }
            }
        }];
    }
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
        [self subscribeToURLAndAppActiveNotifications];
        
        [[UIApplication sharedApplication] openURL:self.redirectURL options:@{} completionHandler:nil];
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
    NSError *manuallyClosedError = nil;
    if (self.returnURL != nil
        && self.state == STPRedirectContextStateInProgress
        && self.completionError == nil
        ) {
        manuallyClosedError = [NSError errorWithDomain:StripeDomain
                                                  code:STPCancellationError
                                              userInfo:@{
                                                  STPErrorMessageKey: @"User manually closed SFSafariViewController before redirect was completed."
                                              }
                               ];
    }
    stpDispatchToMainThreadIfNecessary(^{
        [self handleRedirectCompletionWithError:manuallyClosedError
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
        stpDispatchToMainThreadIfNecessary(^{
            if ([self.lastKnownSafariVCURL.host containsString:@"stripe.com"]) {
                [self handleRedirectCompletionWithError:[NSError stp_genericConnectionError]
                            shouldDismissViewController:YES];
            }
        });
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

- (void)performAppRedirectIfPossibleWithCompletion:(STPBoolCompletionBlock)onCompletion {
    
    NSURL *nativeURL = self.nativeRedirectURL;
    if (!nativeURL) {
        onCompletion(NO);
        return;
    }
    
    UIApplication *application = [UIApplication sharedApplication];
    [application openURL:nativeURL options:@{} completionHandler:^(BOOL success) {
        onCompletion(success);
    }];
}


- (void)handleDidBecomeActiveNotification {
    // Always `dispatch_async` the `handleDidBecomeActiveNotification` function
    // call to re-queue the task at the end of the run loop. This is so that the
    // `handleURLCallback` gets handled first.
    //
    // Verified this works even if `handleURLCallback` performs `dispatch_async`
    // but not completely sure why :)
    //
    // When returning from a `startSafariAppRedirectFlow` call, the
    // `UIApplicationDidBecomeActiveNotification` handler and
    // `STPURLCallbackHandler` compete. The problem is the
    // `UIApplicationDidBecomeActiveNotification` handler is always queued
    // first causing the `STPURLCallbackHandler` to always fail because the
    // registered callback was already unregistered by the
    // `UIApplicationDidBecomeActiveNotification` handler. We are patching
    // this so that the`STPURLCallbackHandler` can succeed and the
    // `UIApplicationDidBecomeActiveNotification` handler can silently fail.
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

- (void)subscribeToURLAndAppActiveNotifications {
    [self subscribeToURLNotifications];
    if (!self.subscribedToAppActiveNotifications) {
        self.subscribedToAppActiveNotifications = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDidBecomeActiveNotification)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
}

- (void)unsubscribeFromNotificationsAndDismissPresentedViewControllers {
    [self unsubscribeFromNotifications];
    [self dismissPresentedViewController];
}

- (void)unsubscribeFromNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[STPURLCallbackHandler shared] unregisterListener:self];
    self.subscribedToURLNotifications = NO;
    self.subscribedToAppActiveNotifications = NO;
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
        case STPSourceTypeWeChatPay:
            nativeURLString = source.weChatPayDetails.weChatAppURL;
        default:
            // All other sources currently have no native url support
            break;
    }

    NSURL *nativeURL = nativeURLString ? [NSURL URLWithString:nativeURLString] : nil;
    return nativeURL;
}

@end

NS_ASSUME_NONNULL_END
