//
//  STPApplePayContext.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPApplePayContext.h"

#import "STPAPIClient+ApplePay.h"
#import "STPPaymentMethod.h"
#import "STPPaymentIntentParams.h"
#import "STPPaymentIntent+Private.h"
#import "STPPaymentHandler.h"
#import "NSError+Stripe.h"

typedef NS_ENUM(NSUInteger, STPPaymentState) {
    STPPaymentStateNotStarted,
    STPPaymentStatePending,
    STPPaymentStateError,
    STPPaymentStateSuccess
};

@interface STPApplePayContext() <PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, weak) id<STPApplePayContextDelegate> delegate;
@property (nonatomic) PKPaymentAuthorizationViewController *viewController;

// Internal state
@property (nonatomic) STPPaymentState paymentState;
@property (nonatomic, nullable) NSError *error;
/// YES if the flow cancelled or timed out.  This toggles which delegate method (didFinish or didiAuthorize) calls our didComplete delegate method
@property (nonatomic) BOOL didCancel;

@end

@implementation STPApplePayContext

- (instancetype)initWithPaymentRequest:(PKPaymentRequest *)paymentRequest delegate:(id<STPApplePayContextDelegate>)delegate {
    if (![Stripe canSubmitPaymentRequest:paymentRequest]) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _paymentState = STPPaymentStateNotStarted;
        _delegate = delegate;
        _apiClient = [STPAPIClient sharedClient];
        _viewController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
        _viewController.delegate = self;
        
        if (_viewController == nil) {
            return nil;
        }
    }
    return self;
}

- (void)setApiClient:(STPAPIClient *)apiClient {
    if (apiClient == nil) {
        _apiClient = [STPAPIClient sharedClient];
    } else {
        _apiClient = apiClient;
    }
}

- (void)presentApplePayOnViewController:(UIViewController *)viewController completion:(STPVoidBlock)completion {
    if (self.viewController.presentingViewController) {
        NSAssert(NO, @"Already presenting");
        return;
    }
    [viewController presentViewController:self.viewController animated:YES completion:completion];
}

- (NSDictionary *)delegateToAppleDelegateMapping {
    return @{
        NSStringFromSelector(@selector(paymentAuthorizationViewController:didSelectShippingMethod:handler:)) : NSStringFromSelector(@selector(applePayContext:didSelectShippingMethod:handler:)),
        NSStringFromSelector(@selector(paymentAuthorizationViewController:didSelectShippingMethod:completion:)) : NSStringFromSelector(@selector(applePayContext:didSelectShippingMethod:completion:)),
        NSStringFromSelector(@selector(paymentAuthorizationViewController:didSelectShippingContact:handler:)) : NSStringFromSelector(@selector(applePayContext:didSelectShippingContact:handler:)),
        NSStringFromSelector(@selector(paymentAuthorizationViewController:didSelectShippingContact:completion:)) : NSStringFromSelector(@selector(applePayContext:didSelectShippingContact:completion:)),
        
    };
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    // Called for the methods we additionally respond YES to in `respondsToSelector`, letting us forward directly to self.delegate
    // We could alternatively implement the PKPaymentAuthorizationViewControllerDelegate methods to call their respective STPApplePayContextDelegate methods
    NSString *selector = NSStringFromSelector([invocation selector]);
    SEL equivalentDelegateSelector = NSSelectorFromString([self delegateToAppleDelegateMapping][selector]);
    if ([self.delegate respondsToSelector:equivalentDelegateSelector]) {
        STPApplePayContext *_self = self;
        invocation.selector = equivalentDelegateSelector;
        [invocation setArgument:&_self atIndex:2]; // Replace paymentAuthorizationViewController with applePayContext
        [invocation setTarget:self.delegate];
        [invocation invoke];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    // STPApplePayContextDelegate exposes methods that map 1:1 to PKPaymentAuthorizationViewControllerDelegate methods
    // We want this method to respond the same way
    
    // Why not simply implement the methods to call their equivalents on self.delegate?
    // The implementation of e.g. didSelectShippingMethod must call the completion block.
    // If the user does not implement e.g. didSelectShippingMethod, we don't know the correct PKPaymentSummaryItems to pass to the completion block
    // (it may have changed since we were initialized due to another delegate method)
    NSString *selector = NSStringFromSelector(aSelector);
    SEL equivalentDelegateSelector = NSSelectorFromString([self delegateToAppleDelegateMapping][selector]);
    return [super respondsToSelector:aSelector] || [self.delegate respondsToSelector:equivalentDelegateSelector];
}
               
#pragma mark - PKPaymentAuthorizationViewControllerDelegate

// TODO: Is this target_os_ set correctly?
#if !(defined(TARGET_OS_MACCATALYST) && (TARGET_OS_MACCATALYST != 0))

- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(nonnull PKPayment *)payment
                                   handler:(nonnull void (^)(PKPaymentAuthorizationResult * _Nonnull))completion API_AVAILABLE(ios(11.0)) {
    // Some observations (on iOS 12 simulator):
    // - The docs say localizedDescription can be shown in the Apple Pay sheet, but I haven't seen this.
    // - If you call the completion block w/ a status of .failure and an error, the user is prompted to try again. Otherwise, the sheet is dismissed.

    [self _completePaymentWithPayment:payment completion:^(PKPaymentAuthorizationStatus status, NSError *error) {
        NSArray *errors = error ? @[[STPAPIClient pkPaymentErrorForStripeError:error]] : nil;
        PKPaymentAuthorizationResult *result = [[PKPaymentAuthorizationResult alloc] initWithStatus:status errors:errors];
        completion(result);
    }];
}


- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(nonnull void (^)(PKPaymentAuthorizationStatus))completion {
    [self _completePaymentWithPayment:payment completion:^(PKPaymentAuthorizationStatus status, __unused NSError *error) {
        completion(status);
    }];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    // Note: If you don't dismiss the VC, the UI disappears, the VC blocks interaction, and this method gets called again.
    [controller dismissViewControllerAnimated:YES completion:^{
        switch (self.paymentState) {
            case STPPaymentStateNotStarted: {
                [self.delegate applePayContextDidComplete:self status:STPPaymentStatusUserCancellation error:nil];
                break;
            }
            case STPPaymentStatePending: {
                // We can't cancel a pending payment. Instead, we'll ignore this and inform the user when the payment finishes.
                self.didCancel = YES;
                break;
            }
            case STPPaymentStateError: {
                [self.delegate applePayContextDidComplete:self status:STPPaymentStatusError error:self.error];
                break;
            }
            case STPPaymentStateSuccess: {
                [self.delegate applePayContextDidComplete:self status:STPPaymentStatusSuccess error:nil];
                break;
            }
        }
    }];
}

#pragma mark - Helpers

- (void)_completePaymentWithPayment:(PKPayment *)payment completion:(nonnull void (^)(PKPaymentAuthorizationStatus, NSError *))completion {
    [[STPAPIClient sharedClient] createPaymentMethodWithPayment:payment completion:^(STPPaymentMethod *paymentMethod, NSError *paymentMethodCreationError) {
        if (paymentMethodCreationError) {
            self.paymentState = STPPaymentStateError;
            self.error = paymentMethodCreationError;
            completion(PKPaymentAuthorizationStatusFailure, paymentMethodCreationError);
            return;
        }
        
        [self.delegate applePayContextNeedsPaymentIntent:self paymentMethod:paymentMethod.stripeId completion:^(NSString * _Nullable paymentIntentClientSecret, NSError * _Nullable paymentIntentCreationError) {
            if (paymentIntentCreationError) {
                self.paymentState = STPPaymentStateError;
                self.error = paymentIntentCreationError;
                completion(PKPaymentAuthorizationStatusFailure, paymentIntentCreationError);
                return;
            }
            
            // Retrieve the PaymentIntent and see if we need to confirm it client-side
            [self.apiClient retrievePaymentIntentWithClientSecret:paymentIntentClientSecret completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable paymentIntentError) {
                if (paymentIntentError) {
                    self.paymentState = STPPaymentStateError;
                    self.error = paymentIntentError;
                    completion(PKPaymentAuthorizationStatusFailure, paymentIntentError);
                    return;
                }
                if (paymentIntent.confirmationMethod == STPPaymentIntentConfirmationMethodAutomatic && (paymentIntent.status == STPPaymentIntentStatusRequiresPaymentMethod || paymentIntent.status == STPPaymentIntentStatusRequiresConfirmation)) {
                    // Confirm the PaymentIntent
                    STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:paymentIntentClientSecret];
                    paymentIntentParams.paymentMethodId = paymentMethod.stripeId;
                    paymentIntentParams.useStripeSDK = @(YES);

                    self.paymentState = STPPaymentStatePending;

                    // We don't use PaymentHandler because we can't handle next actions as-is - we'd need to dismiss the Apple Pay VC.
                    [self.apiClient confirmPaymentIntentWithParams:paymentIntentParams completion:^(STPPaymentIntent * _Nullable paymentIntent2, NSError * _Nullable confirmError) {
                        if (paymentIntent2 && (paymentIntent2.status == STPPaymentIntentStatusSucceeded || paymentIntent2.status == STPPaymentIntentStatusRequiresCapture)) {
                            self.paymentState = STPPaymentStateSuccess;

                            if (self.didCancel) {
                                [self.delegate applePayContextDidComplete:self status:STPPaymentStatusSuccess error:nil];
                            } else {
                                completion(PKPaymentAuthorizationStatusSuccess, nil);
                            }
                        } else {
                            self.paymentState = STPPaymentStateError;
                            self.error = confirmError;

                            if (self.didCancel) {
                                [self.delegate applePayContextDidComplete:self status:STPPaymentStatusError error:confirmError];
                            } else {
                                completion(PKPaymentAuthorizationStatusFailure, confirmError);
                            }
                        }
                    }];
                } else if (paymentIntent.status == STPPaymentIntentStatusSucceeded || paymentIntent.status == STPPaymentIntentStatusRequiresCapture) {
                    self.paymentState = STPPaymentStateSuccess;

                    if (self.didCancel) {
                        [self.delegate applePayContextDidComplete:self status:STPPaymentStatusSuccess error:nil];
                    } else {
                        completion(PKPaymentAuthorizationStatusSuccess, nil);
                    }
                } else {
                    self.paymentState = STPPaymentStateError;
                    NSDictionary *userInfo = @{
                        NSLocalizedDescriptionKey: [NSError stp_unexpectedErrorMessage],
                        STPErrorMessageKey: @"The PaymentIntent is in an unexpected state. If you pass confirmation_method = manual when creating the PaymentIntent, also pass confirm = true.  If server-side confirmation fails, double check you passing the error back to the client."
                    };
                    self.error = [NSError errorWithDomain:STPPaymentHandlerErrorDomain code:STPPaymentHandlerIntentStatusErrorCode userInfo:userInfo];

                    if (self.didCancel) {
                        [self.delegate applePayContextDidComplete:self status:STPPaymentStatusError error:self.error];
                    } else {
                        completion(PKPaymentAuthorizationStatusFailure, self.error);
                    }
                }
            }];
        }];
    }];
}

#endif

@end
