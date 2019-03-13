//
//  STPPaymentMethodCardWalletVisaCheckout.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

@class STPPaymentMethodAddress;

NS_ASSUME_NONNULL_BEGIN

/**
 A Visa Checkout Card Wallet
 
 @see https://stripe.com/docs/visa-checkout
 */
@interface STPPaymentMethodCardWalletVisaCheckout : NSObject <STPAPIResponseDecodable>

/**
 Owner’s verified email. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
 */
@property (nonatomic, nullable, readonly) NSString *email;

/**
 Owner’s verified email. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
 */
@property (nonatomic, nullable, readonly) NSString *name;

/**
 Owner’s verified billing address. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodAddress *billingAddress;

/**
 Owner’s verified shipping address. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodAddress *shippingAddress;

@end

NS_ASSUME_NONNULL_END
