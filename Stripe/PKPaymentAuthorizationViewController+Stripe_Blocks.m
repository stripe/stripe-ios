//
//  PKPaymentAuthorizationViewController+Stripe_Blocks.m
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <objc/runtime.h>

#import "PKPaymentAuthorizationViewController+Stripe_Blocks.h"
#import "STPAPIClient+ApplePay.h"
#import "STPCard.h"
#import "STPPaymentMethod.h"
#import "STPToken.h"

static char kSTPBlockBasedApplePayDelegateAssociatedObjectKey;

typedef void (^STPApplePayShippingMethodCompletionBlock)(PKPaymentAuthorizationStatus status, NSArray<PKPaymentSummaryItem *> *summaryItems);
typedef void (^STPApplePayShippingAddressCompletionBlock)(PKPaymentAuthorizationStatus status, NSArray<PKShippingMethod *> *shippingMethods, NSArray<PKPaymentSummaryItem *> *summaryItems);

@interface STPBlockBasedApplePayDelegate : NSObject <PKPaymentAuthorizationViewControllerDelegate>
@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic, copy) STPShippingAddressSelectionBlock onShippingAddressSelection;
@property (nonatomic, copy) STPShippingMethodSelectionBlock onShippingMethodSelection;
@property (nonatomic, copy) STPPaymentAuthorizationBlock onPaymentAuthorization;
@property (nonatomic, copy) STPApplePayPaymentMethodHandlerBlock onPaymentMethodCreation;
@property (nonatomic, copy) STPPaymentCompletionBlock onFinish;
@property (nonatomic) NSError *lastError;
@property (nonatomic) BOOL didSucceed;
@end

typedef void (^STPPaymentAuthorizationStatusCallback)(PKPaymentAuthorizationStatus status);

@implementation STPBlockBasedApplePayDelegate

#if !(defined(TARGET_OS_MACCATALYST) && (TARGET_OS_MACCATALYST != 0))

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment completion:(STPPaymentAuthorizationStatusCallback)completion {
    self.onPaymentAuthorization(payment);

    void(^paymentMethodCreateCompletion)(STPPaymentMethod *, NSError *) = ^(STPPaymentMethod *result, NSError *paymentMethodCreateError) {
        if (paymentMethodCreateError) {
            self.lastError = paymentMethodCreateError;
            completion(PKPaymentAuthorizationStatusFailure);
            return;
        }
        self.onPaymentMethodCreation(result, ^(STPPaymentStatus status, NSError *error) {
            if (status != STPPaymentStatusSuccess || error) {
                self.lastError = error;
                completion(PKPaymentAuthorizationStatusFailure);
                if (controller.presentingViewController == nil) {
                    // If we call completion() after dismissing, didFinishWithStatus is NOT called.
                    [self _finish];
                }
                return;
            }
            self.didSucceed = YES;
            completion(PKPaymentAuthorizationStatusSuccess);
            if (controller.presentingViewController == nil) {
                // If we call completion() after dismissing, didFinishWithStatus is NOT called.
                [self _finish];
            }
        });
    };
    [self.apiClient createPaymentMethodWithPayment:payment completion:paymentMethodCreateCompletion];
}

- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                   didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                                completion:(STPApplePayShippingMethodCompletionBlock)completion {
    self.onShippingMethodSelection(shippingMethod, ^(NSArray<PKPaymentSummaryItem *> *summaryItems) {
        completion(PKPaymentAuthorizationStatusSuccess, summaryItems);
    });
}

- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                  didSelectShippingContact:(PKContact *)contact
                                completion:(STPApplePayShippingAddressCompletionBlock)completion {
    STPAddress *stpAddress = [[STPAddress alloc] initWithPKContact:contact];
    self.onShippingAddressSelection(stpAddress, ^(STPShippingStatus status, NSArray<PKShippingMethod *>* shippingMethods, NSArray<PKPaymentSummaryItem*> *summaryItems) {
        if (status == STPShippingStatusInvalid) {
            completion(PKPaymentAuthorizationStatusInvalidShippingPostalAddress, shippingMethods, summaryItems);
        } else {
            completion(PKPaymentAuthorizationStatusSuccess, shippingMethods, summaryItems);
        }
    });
}

#endif

- (void)paymentAuthorizationViewControllerDidFinish:(__unused PKPaymentAuthorizationViewController *)controller {
    [self _finish];
}

- (void)_finish {
    if (self.didSucceed) {
        self.onFinish(STPPaymentStatusSuccess, nil);
    } else if (self.lastError) {
        self.onFinish(STPPaymentStatusError, self.lastError);
    } else {
        self.onFinish(STPPaymentStatusUserCancellation, nil);
    }
}

@end

@interface PKPaymentAuthorizationViewController()

@end

@implementation PKPaymentAuthorizationViewController (Stripe_Blocks)

+ (instancetype)stp_controllerWithPaymentRequest:(PKPaymentRequest *)paymentRequest
                                       apiClient:(STPAPIClient *)apiClient
                      onShippingAddressSelection:(STPShippingAddressSelectionBlock)onShippingAddressSelection
                       onShippingMethodSelection:(STPShippingMethodSelectionBlock)onShippingMethodSelection
                          onPaymentAuthorization:(STPPaymentAuthorizationBlock)onPaymentAuthorization
                         onPaymentMethodCreation:(STPApplePayPaymentMethodHandlerBlock)onPaymentMethodCreation
                                        onFinish:(STPPaymentCompletionBlock)onFinish {
    STPBlockBasedApplePayDelegate *delegate = [STPBlockBasedApplePayDelegate new];
    delegate.apiClient = apiClient;
    delegate.onShippingAddressSelection = onShippingAddressSelection;
    delegate.onShippingMethodSelection = onShippingMethodSelection;
    delegate.onPaymentAuthorization = onPaymentAuthorization;
    delegate.onPaymentMethodCreation = onPaymentMethodCreation;
    delegate.onFinish = onFinish;
    PKPaymentAuthorizationViewController *viewController = [[self alloc] initWithPaymentRequest:paymentRequest];
    viewController.delegate = delegate;
    objc_setAssociatedObject(viewController, &kSTPBlockBasedApplePayDelegateAssociatedObjectKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return viewController;
}

@end

void linkPKPaymentAuthorizationViewControllerBlocksCategory(void){}
