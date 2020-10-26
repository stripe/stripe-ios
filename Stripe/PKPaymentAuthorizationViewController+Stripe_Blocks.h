//
//  PKPaymentAuthorizationViewController+Stripe_Blocks.h
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <PassKit/PassKit.h>

#import "STPAPIClient.h"
#import "STPPaymentContext.h"


NS_ASSUME_NONNULL_BEGIN

typedef void(^STPApplePayPaymentMethodHandlerBlock)(STPPaymentMethod *paymentMethod, STPPaymentStatusBlock completion);
typedef void (^STPPaymentCompletionBlock)(STPPaymentStatus status,  NSError * __nullable error);
typedef void (^STPPaymentSummaryItemCompletionBlock)(NSArray<PKPaymentSummaryItem*> *summaryItems);
typedef void (^STPShippingMethodSelectionBlock)(PKShippingMethod *selectedMethod, STPPaymentSummaryItemCompletionBlock completion);
typedef void (^STPShippingAddressValidationBlock)(STPShippingStatus status, NSArray<PKShippingMethod *>* shippingMethods, NSArray<PKPaymentSummaryItem*> *summaryItems);
typedef void (^STPShippingAddressSelectionBlock)(STPAddress *selectedAddress, STPShippingAddressValidationBlock completion);
typedef void (^STPPaymentAuthorizationBlock)(PKPayment *payment);

@interface PKPaymentAuthorizationViewController (Stripe_Blocks)

+ (instancetype)stp_controllerWithPaymentRequest:(PKPaymentRequest *)paymentRequest
                                       apiClient:(STPAPIClient *)apiClient
                      onShippingAddressSelection:(STPShippingAddressSelectionBlock)onShippingAddressSelection
                       onShippingMethodSelection:(STPShippingMethodSelectionBlock)onShippingMethodSelection
                          onPaymentAuthorization:(STPPaymentAuthorizationBlock)onPaymentAuthorization
                         onPaymentMethodCreation:(STPApplePayPaymentMethodHandlerBlock)onPaymentMethodCreation
                                        onFinish:(STPPaymentCompletionBlock)onFinish;


@end

void linkPKPaymentAuthorizationViewControllerBlocksCategory(void);

NS_ASSUME_NONNULL_END
