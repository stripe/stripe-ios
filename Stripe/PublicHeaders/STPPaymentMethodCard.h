//
//  STPPaymentMethodCard.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

@class STPPaymentMethodThreeDSecureUsage, STPPaymentMethodCardWallet, STPPaymentMethodCardChecks;

NS_ASSUME_NONNULL_BEGIN

/**
 Contains details about a user's credit card.
 
 @see https://site-admin.stripe.com/docs/api/payment_methods/object#payment_method_object-card
 */
@interface STPPaymentMethodCard : NSObject <STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPPaymentMethodCard`. You should only use one that is part of an existing `STPPaymentMethod` object.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentMethodCard. You should only use one that is part of an existing STPPaymentMethod object.")));

/**
 Card brand. Can be amex, diners, discover, jcb, mastercard, unionpay, visa, or unknown.
 */
@property (nonatomic, nullable, readonly) NSString *brand;

/**
 Checks on Card address and CVC if provided.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodCardChecks *checks;

/**
 Two-letter ISO code representing the country of the card.
 */
@property (nonatomic, nullable, readonly) NSString *country;

/**
 Two-digit number representing the card’s expiration month.
 */
@property (nonatomic, readonly) NSInteger expMonth;

/**
 Four-digit number representing the card’s expiration year.
 */
@property (nonatomic, readonly) NSInteger expYear;

/**
 Card funding type. Can be credit, debit, prepaid, or unknown.
 */
@property (nonatomic, nullable, readonly) NSString *funding;

/**
 The last four digits of the card.
 */
@property (nonatomic, nullable, readonly) NSString *last4;

/**
 Contains details on how this Card maybe be used for 3D Secure authentication.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodThreeDSecureUsage *threeDSecureUsage;

/**
 If this Card is part of a Card Wallet, this contains the details of the Card Wallet.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodCardWallet *wallet;

@end

NS_ASSUME_NONNULL_END
