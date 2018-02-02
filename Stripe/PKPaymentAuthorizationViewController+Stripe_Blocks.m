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
#import "STPSource.h"
#import "STPToken.h"

static char kSTPBlockBasedApplePayDelegateAssociatedObjectKey;

typedef void (^STPApplePayShippingMethodCompletionBlock)(PKPaymentAuthorizationStatus status, NSArray<PKPaymentSummaryItem *> *summaryItems);
typedef void (^STPApplePayShippingAddressCompletionBlock)(PKPaymentAuthorizationStatus status, NSArray<PKShippingMethod *> *shippingMethods, NSArray<PKPaymentSummaryItem *> *summaryItems);

@interface STPBlockBasedApplePayDelegate : NSObject <PKPaymentAuthorizationViewControllerDelegate>
@property (nonatomic) STPAPIClient *apiClient;
@property (nonatomic, copy) STPShippingAddressSelectionBlock onShippingAddressSelection;
@property (nonatomic, copy) STPShippingMethodSelectionBlock onShippingMethodSelection;
@property (nonatomic, copy) STPPaymentAuthorizationBlock onPaymentAuthorization;
@property (nonatomic, copy) STPApplePaySourceHandlerBlock onSourceCreation;
@property (nonatomic, copy) STPPaymentCompletionBlock onFinish;
@property (nonatomic) NSError *lastError;
@property (nonatomic) BOOL didSucceed;
@property (nonatomic) BOOL createSource;
@end

typedef void (^STPPaymentAuthorizationStatusCallback)(PKPaymentAuthorizationStatus status);

@implementation STPBlockBasedApplePayDelegate

- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment completion:(STPPaymentAuthorizationStatusCallback)completion {
    self.onPaymentAuthorization(payment);

    void(^tokenOrSourceCompletion)(id<STPSourceProtocol>, NSError *) = ^(id<STPSourceProtocol> result, NSError *error) {
        if (error) {
            self.lastError = error;
            completion(PKPaymentAuthorizationStatusFailure);
            return;
        }
        id<STPSourceProtocol> source;
        // return the child card, not the STPToken
        if ([result isKindOfClass:[STPToken class]]) {
            source = ((STPToken *)result).card;
        }
        else if ([result isKindOfClass:[STPSource class]]) {
            source = (STPSource *)result;
        }
        self.onSourceCreation(source, ^(NSError *sourceCreation){
            if (sourceCreation) {
                self.lastError = sourceCreation;
                completion(PKPaymentAuthorizationStatusFailure);
                return;
            }
            self.didSucceed = YES;
            completion(PKPaymentAuthorizationStatusSuccess);
        });
    };
    if (self.createSource) {
        [self.apiClient createSourceWithPayment:payment completion:(STPSourceCompletionBlock)tokenOrSourceCompletion];
    }
    else {
        [self.apiClient createTokenWithPayment:payment completion:(STPTokenCompletionBlock)tokenOrSourceCompletion];
    }
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
        }
        else {
            completion(PKPaymentAuthorizationStatusSuccess, shippingMethods, summaryItems);
        }
    });
}

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
                                    createSource:(BOOL)createSource
                      onShippingAddressSelection:(STPShippingAddressSelectionBlock)onShippingAddressSelection
                       onShippingMethodSelection:(STPShippingMethodSelectionBlock)onShippingMethodSelection
                          onPaymentAuthorization:(STPPaymentAuthorizationBlock)onPaymentAuthorization
                                 onTokenCreation:(STPApplePaySourceHandlerBlock)onTokenCreation
                                        onFinish:(STPPaymentCompletionBlock)onFinish {
    STPBlockBasedApplePayDelegate *delegate = [STPBlockBasedApplePayDelegate new];
    delegate.apiClient = apiClient;
    delegate.createSource = createSource;
    delegate.onShippingAddressSelection = onShippingAddressSelection;
    delegate.onShippingMethodSelection = onShippingMethodSelection;
    delegate.onPaymentAuthorization = onPaymentAuthorization;
    delegate.onSourceCreation = onTokenCreation;
    delegate.onFinish = onFinish;
    PKPaymentAuthorizationViewController *viewController = [[self alloc] initWithPaymentRequest:paymentRequest];
    viewController.delegate = delegate;
    objc_setAssociatedObject(viewController, &kSTPBlockBasedApplePayDelegateAssociatedObjectKey, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return viewController;
}

@end

void linkPKPaymentAuthorizationViewControllerBlocksCategory(void){}
