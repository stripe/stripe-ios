//
//  STPPaymentPresenter.m
//  Stripe
//
//  Created by Jack Flintermann on 11/25/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

#ifdef STRIPE_ENABLE_APPLEPAY

#import "STPPaymentPresenter.h"
#import <PassKit/PassKit.h>
#import "StripeError.h"
#import "Stripe.h"
#import "Stripe+ApplePay.h"
#import <objc/runtime.h>
#import "STPCheckoutViewController.h"

static const NSString *STPPaymentPresenterAssociatedObjectKey = @"STPPaymentPresenterAssociatedObjectKey";

@interface STPCheckoutOptions (PaymentRequestAdditions)
@property (nonatomic, readonly) PKPaymentRequest *paymentRequest;
@end

@interface STPPaymentPresenter () <STPCheckoutViewControllerDelegate, PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, weak) id<STPPaymentPresenterDelegate> delegate;
@property (nonatomic, copy) STPCheckoutOptions *checkoutOptions;
@property (weak, nonatomic) UIViewController *presentingViewController;
@property (weak, nonatomic) UIViewController *presentedViewController;
@property (nonatomic) BOOL hasAuthorizedPayment;
@property (nonatomic) NSError *error;
@end

@implementation STPPaymentPresenter

- (instancetype)initWithCheckoutOptions:(STPCheckoutOptions *)checkoutOptions delegate:(id<STPPaymentPresenterDelegate>)delegate {
    NSCAssert(checkoutOptions && delegate, @"You cannot pass nil values for checkoutOptions or delegate when creating an STPPaymentPresenter.");
    self = [super init];
    if (self) {
        _delegate = delegate;
        _checkoutOptions = checkoutOptions;
    }
    return self;
}

- (void)requestPaymentFromPresentingViewController:(UIViewController *)presentingViewController {
    if (presentingViewController.presentedViewController && presentingViewController.presentedViewController == self.presentedViewController) {
        NSLog(@"Error: called requestPaymentFromPresentingViewController: while already presenting a payment view controller.");
        return;
    }
    NSCAssert(presentingViewController, @"You cannot call requestPaymentFromPresentingViewController: with a nil argument.");
    self.presentingViewController = presentingViewController;

    // we really don't want to get dealloc'ed in case the caller doesn't remember to retain this object.
    objc_setAssociatedObject(self.presentingViewController, &STPPaymentPresenterAssociatedObjectKey, self, OBJC_ASSOCIATION_RETAIN);
    PKPaymentRequest *paymentRequest = self.checkoutOptions.paymentRequest;
    if (paymentRequest) {
        if ([self.delegate respondsToSelector:@selector(paymentPresenter:didPreparePaymentRequest:)]) {
            [self.delegate paymentPresenter:self didPreparePaymentRequest:paymentRequest];
        }
        if ([Stripe canSubmitPaymentRequest:paymentRequest]) {
            PKPaymentAuthorizationViewController *paymentViewController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
            paymentViewController.delegate = self;
            [self.presentingViewController presentViewController:paymentViewController animated:YES completion:nil];
            self.presentedViewController = paymentViewController;
            return;
        }
    }
    STPCheckoutViewController *checkoutViewController = [[STPCheckoutViewController alloc] initWithOptions:self.checkoutOptions];
    checkoutViewController.delegate = self;
    self.presentedViewController = checkoutViewController;
    [self.presentingViewController presentViewController:checkoutViewController animated:YES completion:nil];
}

- (void)finishWithStatus:(STPPaymentStatus)status error:(NSError *)error {
    [self.delegate paymentPresenter:self didFinishWithStatus:status error:error];
    objc_setAssociatedObject(self.presentingViewController, &STPPaymentPresenterAssociatedObjectKey, nil, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - STPCheckoutViewControllerDelegate

- (void)checkoutController:(__unused STPCheckoutViewController *)controller didFailWithError:(NSError *)error {
    [self finishWithStatus:STPPaymentStatusError error:error];
}

- (void)checkoutControllerDidCancel:(__unused STPCheckoutViewController *)controller {
    [self finishWithStatus:STPPaymentStatusUserCanceled error:nil];
}

- (void)checkoutControllerDidFinish:(__unused STPCheckoutViewController *)controller {
    [self finishWithStatus:STPPaymentStatusSuccess error:nil];
}

- (void)checkoutController:(__unused STPCheckoutViewController *)controller didCreateToken:(STPToken *)token completion:(STPTokenSubmissionHandler)completion {
    [self.delegate paymentPresenter:self didCreateStripeToken:token completion:completion];
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))pkCompletion {
    [Stripe createTokenWithPayment:payment
                        completion:^(STPToken *token, NSError *error) {
                            if (error) {
                                [self finishWithStatus:STPPaymentStatusError error:error];
                                return;
                            }
                            STPTokenSubmissionHandler completion = ^(STPBackendChargeResult status, NSError *error) {
                                self.error = error;
                                if (status == STPBackendChargeResultSuccess) {
                                    self.hasAuthorizedPayment = YES;
                                    pkCompletion(PKPaymentAuthorizationStatusSuccess);
                                } else {
                                    pkCompletion(PKPaymentAuthorizationStatusFailure);
                                }
                            };
                            [self.delegate paymentPresenter:self didCreateStripeToken:token completion:completion];
                        }];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    STPPaymentStatus status;
    if (self.error) {
        status = STPPaymentStatusError;
    } else if (self.hasAuthorizedPayment) {
        status = STPPaymentStatusSuccess;
    } else {
        status = STPPaymentStatusUserCanceled;
    }
    [self finishWithStatus:status error:self.error];
}

@end

@implementation STPCheckoutOptions (PaymentRequestAdditions)

- (PKPaymentRequest *)paymentRequest {
    if (!self.appleMerchantId || !self.purchaseAmount || !self.companyName) {
        return nil;
    }
    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:self.appleMerchantId];
    paymentRequest.currencyCode = self.purchaseCurrency;

    NSMutableArray *paymentSummaryItems = [@[] mutableCopy];
    if (self.purchaseDescription) {
        PKPaymentSummaryItem *item = [PKPaymentSummaryItem summaryItemWithLabel:self.purchaseDescription amount:self.purchaseAmount];
        [paymentSummaryItems addObject:item];
    }
    PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:self.companyName amount:self.purchaseAmount];
    [paymentSummaryItems addObject:total];
    paymentRequest.paymentSummaryItems = [paymentSummaryItems copy];

    if ([self.requireBillingAddress boolValue]) {
        paymentRequest.requiredBillingAddressFields = PKAddressFieldPostalAddress;
    }

    return paymentRequest;
}

@end

#endif
