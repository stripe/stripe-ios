//
//  PKPaymentAuthorizationViewController+Stripe.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 2/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//
#import <objc/runtime.h>

#import "PKPaymentAuthorizationViewController+Stripe.h"
#import "STPAPIClient+ApplePay.h"
#import "STPPaymentMethod.h"
#import "STPPaymentIntentParams.h"
#import "STPPaymentIntent+Private.h"
#import "STPApplePayDelegate.h"
#import "STPPaymentHandler.h"
#import "NSError+Stripe.h"

typedef NS_ENUM(NSUInteger, STPPaymentState) {
    STPPaymentStateNotStarted,
    STPPaymentStatePending,
    STPPaymentStateError,
    STPPaymentStateSuccess
};

static char kSTPApplePayDelegateAssociatedObjectKey;

@interface STPApplePayDelegate : NSObject <PKPaymentAuthorizationViewControllerDelegate>
@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic, weak) id<STPApplePayDelegate> delegate;
@property (nonatomic) STPPaymentStatusBlock completion;
@property (nonatomic) PKPaymentRequest *paymentRequest;

@property (nonatomic) STPPaymentState paymentState;
@property (nonatomic, nullable) NSError *error;

/// YES if the flow cancelled or timed out.  This toggles which delegate method (didFinish or didiAuthorize) calls the final completion block.
@property (nonatomic) BOOL didCancel;

@end

typedef void (^STPPaymentAuthorizationStatusCallback)(PKPaymentAuthorizationStatus status);

@implementation STPApplePayDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        self.paymentState = STPPaymentStateNotStarted;
    }
    return self;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    // Called for the methods we additionally respond YES to in `respondsToSelector`, letting us forward directly to self.delegate
    if ([self.delegate respondsToSelector:[invocation selector]]) {
        [invocation setTarget:self.delegate];
        [invocation invoke];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    // Forward the PKPaymentAuthorizationViewControllerDelegate that STPApplePayDelegate exposes to our delegate
    
    // Why not simply implement the methods and call them on self.delegate?
    // If the user does not implement e.g. didSelectShippingMethod, we have to call the completion block in our implementation,
    // but we don't know the correct PKPaymentSummaryItems to pass (it may have changed since we were initialized due to another delegate method)
    
    return [super respondsToSelector:aSelector] ||
    aSelector == @selector(paymentAuthorizationViewController:didSelectShippingMethod:handler:) ||
    aSelector == @selector(paymentAuthorizationViewController:didSelectShippingMethod:completion:) ||
    aSelector == @selector(paymentAuthorizationViewController:didSelectShippingContact:handler:) ||
    aSelector == @selector(paymentAuthorizationViewController:didSelectShippingContact:completion:);
}
               
#pragma mark - PKPaymentAuthorizationViewControllerDelegate

// Some observations (on iOS 12 simulator):
// - The docs say localizedDescription can be shown in the Apple Pay sheet, but I haven't seen this.

// TODO: Is this target_os_ set correctly?
#if !(defined(TARGET_OS_MACCATALYST) && (TARGET_OS_MACCATALYST != 0))

- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(nonnull PKPayment *)payment
                                   handler:(nonnull void (^)(PKPaymentAuthorizationResult * _Nonnull))completion API_AVAILABLE(ios(11.0)) {
    // Note: If you call the completion block w/ a status of .failure and an error, the user is prompted to try again. Otherwise, the sheet is dismissed.
    [self _completePaymentWithPayment:payment completion:^(PKPaymentAuthorizationStatus status, NSError *error) {
        PKPaymentAuthorizationResult *result = [[PKPaymentAuthorizationResult alloc] initWithStatus:status errors:@[[STPAPIClient pkPaymentErrorForStripeError:error]]];
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
                self.completion(STPPaymentStatusUserCancellation, nil);
                break;
            }
            case STPPaymentStatePending: {
                // We can't cancel a pending payment. Instead, we'll ignore this and inform the user when the payment finishes.
                self.didCancel = YES;
                break;
            }
            case STPPaymentStateError: {
                self.completion(STPPaymentStatusError, self.error);
                break;
            }
            case STPPaymentStateSuccess: {
                self.completion(STPPaymentStatusSuccess, nil);
                break;
            }
        }
    }];
}

#pragma mark - Helpers

- (void)_completePaymentWithPayment:(PKPayment *)payment completion:(nonnull void (^)(PKPaymentAuthorizationStatus, NSError *))completion {
    self.paymentState = STPPaymentStateNotStarted;
    [[STPAPIClient sharedClient] createPaymentMethodWithPayment:payment completion:^(STPPaymentMethod *paymentMethod, NSError *paymentMethodCreationError) {
        if (paymentMethodCreationError) {
            self.error = paymentMethodCreationError;
            completion(PKPaymentAuthorizationStatusFailure, paymentMethodCreationError);
            return;
        }
        
        [self.delegate createPaymentIntentWithPaymentMethod:paymentMethod.stripeId completion:^(NSString * _Nullable paymentIntentClientSecret, NSError * _Nullable paymentIntentCreationError) {
            if (paymentIntentCreationError) {
                self.error = paymentIntentCreationError;
                completion(PKPaymentAuthorizationStatusFailure, paymentIntentCreationError);
                return;
            }
            
            // Retrieve the PaymentIntent and see if we need to confirm it client-side
            [self.apiClient retrievePaymentIntentWithClientSecret:paymentIntentClientSecret completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable paymentIntentError) {
                if (paymentIntentError) {
                    self.error = paymentIntentError;
                    completion(PKPaymentAuthorizationStatusFailure, paymentIntentError);
                    return;
                }
                if (paymentIntent.confirmationMethod == STPPaymentIntentConfirmationMethodAutomatic && paymentIntent.status == STPPaymentIntentStatusRequiresAction) {
                    // Confirm the PaymentIntent
                    STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:paymentIntentClientSecret];
                    paymentIntentParams.paymentMethodId = paymentMethod.stripeId;
                    paymentIntentParams.useStripeSDK = @(YES);

                    self.paymentState = STPPaymentStatePending;

                    // We don't use PaymentHandler because 1. PaymentHandler is unavailable in extensions 2. We should never have to handle next actions anyways
                    [self.apiClient confirmPaymentIntentWithParams:paymentIntentParams completion:^(STPPaymentIntent * _Nullable paymentIntent2, NSError * _Nullable confirmError) {
                        if (paymentIntent2 && (paymentIntent2.status == STPPaymentIntentStatusSucceeded || paymentIntent2.status == STPPaymentIntentStatusRequiresCapture)) {
                            self.paymentState = STPPaymentStateSuccess;
                            self.error = nil; // Clear any previous attempt's error

                            if (self.didCancel) {
                                self.completion(STPPaymentStatusSuccess, nil);
                            } else {
                                completion(PKPaymentAuthorizationStatusSuccess, nil);
                            }
                        } else {
                            self.paymentState = STPPaymentStateError;
                            self.error = confirmError;

                            if (self.didCancel) {
                                self.completion(STPPaymentStatusError, confirmError);
                            } else {
                                completion(PKPaymentAuthorizationStatusFailure, confirmError);
                            }
                        }
                    }];
                } else if (paymentIntent.status == STPPaymentIntentStatusSucceeded || paymentIntent.status == STPPaymentIntentStatusRequiresCapture) {
                    self.paymentState = STPPaymentStateSuccess;
                    self.error = nil; // Clear any previous attempt's error

                    if (self.didCancel) {
                        self.completion(STPPaymentStatusSuccess, nil);
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
                        self.completion(STPPaymentStatusError, self.error);
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

@interface PKPaymentAuthorizationViewController()

@end

@implementation PKPaymentAuthorizationViewController (Stripe_Blocks)

+ (instancetype)stp_controllerWithPaymentRequest:(PKPaymentRequest *)paymentRequest
                                       apiClient:(STPAPIClient *)apiClient
                                        delegate:(id<STPApplePayDelegate>)delegate
                                      completion:(STPPaymentStatusBlock)completion {
    STPApplePayDelegate *stripeDelegate = [STPApplePayDelegate new];
    stripeDelegate.apiClient = apiClient;
    stripeDelegate.delegate = delegate;
    stripeDelegate.paymentRequest = paymentRequest;
    stripeDelegate.completion = completion;

    PKPaymentAuthorizationViewController *viewController = [[self alloc] initWithPaymentRequest:paymentRequest];
    viewController.delegate = stripeDelegate;
    objc_setAssociatedObject(viewController, &kSTPApplePayDelegateAssociatedObjectKey, stripeDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return viewController;
}

@end

void linkPKPaymentAuthorizationViewControllerStripeCategory(void){}
