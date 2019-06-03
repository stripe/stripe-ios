//
//  STPPaymentMethodCard.h
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPCardBrand.h"

@class STPPaymentMethodThreeDSecureUsage, STPPaymentMethodCardChecks, STPPaymentMethodCardWallet;

NS_ASSUME_NONNULL_BEGIN

/**
 Contains details about a user's credit card.
 
 @see https://stripe.com/docs/api/payment_methods/object#payment_method_object-card
 */
@interface STPPaymentMethodCard : NSObject <STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPPaymentMethodCard`. You should only use one that is part of an existing `STPPaymentMethod` object.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPPaymentMethodCard. You should only use one that is part of an existing STPPaymentMethod object.")));

/**
 The issuer of the card.
 */
@property (nonatomic, readonly) STPCardBrand brand;

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
 Uniquely identifies this particular card number. You can use this attribute to check whether two customers who’ve signed up with you are using the same card number, for example.
 */
@property (nonatomic, nullable, readonly) NSString *fingerprint;

/**
 Contains details on how this Card maybe be used for 3D Secure authentication.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodThreeDSecureUsage *threeDSecureUsage;

/**
 If this Card is part of a Card Wallet, this contains the details of the Card Wallet.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodCardWallet *wallet;

/**
 Returns a string representation for the provided card brand;
 i.e. `[NSString stringFromBrand:STPCardBrandVisa] ==  @"Visa"`.
 
 @param brand the brand you want to convert to a string
 
 @return A string representing the brand, suitable for displaying to a user.
 */
+ (NSString *)stringFromBrand:(STPCardBrand)brand;

@end

NS_ASSUME_NONNULL_END
