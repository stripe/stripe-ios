//
//  PKPaymentAuthorizationViewController+Stripe.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 2/14/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <PassKit/PassKit.h>

#import "STPBlocks.h"

@class STPAPIClient;
@protocol STPApplePayDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 A helper TODO
 
 
 */
@interface PKPaymentAuthorizationViewController (Stripe)

/**
This  handles payment, cancel/timeout logic, error reporting, etc. for the user by implementing the `didAuthorizePayment` and `didFinish` PKPaymentAuthorizationViewControllerDelegate methodos.
*/
+ (instancetype)stp_controllerWithPaymentRequest:(PKPaymentRequest *)paymentRequest
                                       apiClient:(STPAPIClient *)apiClient
                                        delegate:(id<STPApplePayDelegate>)delegate
                                      completion:(STPPaymentStatusBlock)completion;
@end

void linkPKPaymentAuthorizationViewControllerStripeCategory(void);

NS_ASSUME_NONNULL_END
