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

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000 // __IPHONE_11_0
-(PKPaymentAuthorizationResult * _Nonnull)resultFromStatus:(PKPaymentAuthorizationStatus)status {
    //TODO: can improve errors from PKPaymentAuthorizationStatus
    return [[PKPaymentAuthorizationResult alloc] initWithStatus:status errors:nil];
}

// required iOS 11 API - call through to old method to maintain similar functionality
// Does not take advantage of providing more granular information
- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(__unused PKPayment *)payment
                                   handler:(__unused void (^)(PKPaymentAuthorizationResult * _Nonnull))completion {
    
    [self paymentAuthorizationViewController:controller
                         didAuthorizePayment:payment
                                  completion:^(PKPaymentAuthorizationStatus status) {
                                      completion([self resultFromStatus:status]);
                                  }];
}

#endif

- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(STPPaymentAuthorizationStatusCallback)completion {
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

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000 // __IPHONE_11_0
// new iOS 11 API - call through to old method to maintain similar functionality
// Does not take advantage of providing more granular information
-(void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                  didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                                  handler:(void (^)(PKPaymentRequestShippingMethodUpdate * _Nonnull))completion {
    [self paymentAuthorizationViewController:controller didSelectShippingMethod:shippingMethod completion:^(PKPaymentAuthorizationStatus status, NSArray<PKPaymentSummaryItem *> * _Nonnull summaryItems) {
        PKPaymentRequestShippingMethodUpdate *shippingMethodUpdate = [[PKPaymentRequestShippingMethodUpdate alloc] initWithPaymentSummaryItems:summaryItems];
        shippingMethodUpdate.status = status;
        completion(shippingMethodUpdate);
    }];
}

#endif

- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                   didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                                completion:(STPApplePayShippingMethodCompletionBlock)completion {
    self.onShippingMethodSelection(shippingMethod, ^(NSArray<PKPaymentSummaryItem *> *summaryItems) {
        completion(PKPaymentAuthorizationStatusSuccess, summaryItems);
    });
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 110000 // __IPHONE_11_0
// new iOS 11 API - call through to old method to maintain similar functionality
// Does not take advantage of providing more granular information
-(void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                 didSelectShippingContact:(PKContact *)contact
                                  handler:(void (^)(PKPaymentRequestShippingContactUpdate * _Nonnull))completion {
    [self paymentAuthorizationViewController:controller
                    didSelectShippingContact:contact
                                  completion:^(PKPaymentAuthorizationStatus status, NSArray<PKShippingMethod *> * _Nonnull shippingMethods, NSArray<PKPaymentSummaryItem *> * _Nonnull summaryItems) {
                                      PKPaymentRequestShippingContactUpdate *update = [[PKPaymentRequestShippingContactUpdate alloc] initWithErrors:nil paymentSummaryItems:summaryItems shippingMethods:shippingMethods];
                                      update.status = status;
                                      completion(update);
    }];
}
#endif

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
