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

FAUXPAS_IGNORED_IN_FILE(APIAvailability)

static char kSTPBlockBasedApplePayDelegateAssociatedObjectKey;

typedef void (^STPApplePayShippingMethodCompletionBlock)(PKPaymentAuthorizationStatus status, NSArray<PKPaymentSummaryItem *> *summaryItems);
typedef void (^STPApplePayShippingAddressCompletionBlock)(PKPaymentAuthorizationStatus status, NSArray<PKShippingMethod *> *shippingMethods, NSArray<PKPaymentSummaryItem *> *summaryItems);

@interface STPBlockBasedApplePayDelegate : NSObject <PKPaymentAuthorizationViewControllerDelegate>
@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic, copy) STPShippingAddressSelectionBlock onShippingAddressSelection;
@property (nonatomic, copy) STPShippingMethodSelectionBlock onShippingMethodSelection;
@property (nonatomic, copy) STPPaymentAuthorizationBlock onPaymentAuthorization;
@property (nonatomic, copy) STPApplePayTokenHandlerBlock onTokenCreation;
@property (nonatomic, copy) STPPaymentCompletionBlock onFinish;
@property (nonatomic) NSError *lastError;
@property (nonatomic) BOOL didSucceed;
@end

typedef void (^STPPaymentAuthorizationStatusCallback)(PKPaymentAuthorizationStatus status);

@implementation STPBlockBasedApplePayDelegate

- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment completion:(STPPaymentAuthorizationStatusCallback)completion {
    self.onPaymentAuthorization(payment);
    [self.apiClient createTokenWithPayment:payment completion:^(STPToken * _Nullable token, NSError * _Nullable error) {
        if (error) {
            self.lastError = error;
            completion(PKPaymentAuthorizationStatusFailure);
            return;
        }
        self.onTokenCreation(token, ^(NSError *tokenCreationError){
            if (tokenCreationError) {
                self.lastError = tokenCreationError;
                completion(PKPaymentAuthorizationStatusFailure);
                return;
            }
            self.didSucceed = YES;
            completion(PKPaymentAuthorizationStatusSuccess);
        });
    }];
}

- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                   didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                                completion:(STPApplePayShippingMethodCompletionBlock)completion {
    self.onShippingMethodSelection(shippingMethod, ^(NSArray<PKPaymentSummaryItem *> *summaryItems) {
        completion(PKPaymentAuthorizationStatusSuccess, summaryItems);
    });
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                  didSelectShippingAddress:(ABRecordRef)address
                                completion:(STPApplePayShippingAddressCompletionBlock)completion {
    STPAddress *stpAddress = [[STPAddress alloc] initWithABRecord:address];
    self.onShippingAddressSelection(stpAddress, ^(STPShippingStatus status, NSArray<PKShippingMethod *>* shippingMethods, NSArray<PKPaymentSummaryItem*> *summaryItems) {
        if (status == STPShippingStatusInvalid) {
            completion(PKPaymentAuthorizationStatusInvalidShippingPostalAddress, shippingMethods, summaryItems);
        }
        else {
            completion(PKPaymentAuthorizationStatusSuccess, shippingMethods, summaryItems);
        }
    });
}
#pragma clang diagnostic pop

- (void)paymentAuthorizationViewControllerDidFinish:(__unused PKPaymentAuthorizationViewController *)controller {
    if (self.didSucceed) {
        self.onFinish(STPPaymentStatusSuccess, nil);
    }
    else if (self.lastError) {
        self.onFinish(STPPaymentStatusError, self.lastError);
    }
    else {
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
                                 onTokenCreation:(STPApplePayTokenHandlerBlock)onTokenCreation
                                        onFinish:(STPPaymentCompletionBlock)onFinish {
    STPBlockBasedApplePayDelegate *delegate = [STPBlockBasedApplePayDelegate new];
    delegate.apiClient = apiClient;
    delegate.onShippingAddressSelection = onShippingAddressSelection;
    delegate.onShippingMethodSelection = onShippingMethodSelection;
    delegate.onPaymentAuthorization = onPaymentAuthorization;
    delegate.onTokenCreation = onTokenCreation;
    delegate.onFinish = onFinish;
    PKPaymentAuthorizationViewController *viewController = [[self alloc] initWithPaymentRequest:paymentRequest];
    viewController.delegate = delegate;
    objc_setAssociatedObject(viewController, &kSTPBlockBasedApplePayDelegateAssociatedObjectKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return viewController;
}

@end

void linkPKPaymentAuthorizationViewControllerBlocksCategory(void){}
