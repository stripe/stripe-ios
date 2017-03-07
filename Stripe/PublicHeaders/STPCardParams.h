//
//  STPCardParams.h
//  Stripe
//
//  Created by Jack Flintermann on 10/4/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPFormEncodable.h"
#if TARGET_OS_IPHONE
#import "STPAddress.h"
#endif

/**
 *  Representation of a user's credit card details. You can assemble these with information that your user enters and
 *  then create Stripe tokens with them using an STPAPIClient. @see https://stripe.com/docs/api#cards
 */
@interface STPCardParams : NSObject<STPFormEncodable>

/**
 *  The card's number.
 */
@property (nonatomic, copy, nullable) NSString *number;

/**
 *  The last 4 digits of the card's number, if it's been set, otherwise nil.
 */
- (nullable NSString *)last4;

/**
 *  The card's expiration month.
 */
@property (nonatomic) NSUInteger expMonth;

/**
 *  The card's expiration year.
 */
@property (nonatomic) NSUInteger expYear;

/**
 *  The card's security code, found on the back.
 */
@property (nonatomic, copy, nullable) NSString *cvc;

/**
 *  The cardholder's name.
 */
@property (nonatomic, copy, nullable) NSString *name;

/**
 *  The cardholder's address.
 */
@property(nonatomic, copy, nonnull) STPAddress *address;

@property (nonatomic, copy, nullable) NSString *addressLine1;
@property (nonatomic, copy, nullable) NSString *addressLine2;
@property (nonatomic, copy, nullable) NSString *addressCity;
@property (nonatomic, copy, nullable) NSString *addressState;
@property (nonatomic, copy, nullable) NSString *addressZip;
@property (nonatomic, copy, nullable) NSString *addressCountry;

/**
 *  Three-letter ISO currency code representing the currency paid out to the bank account. This is only applicable when tokenizing debit cards to issue payouts to managed accounts. You should not set it otherwise. The card can then be used as a transfer destination for funds in this currency.
 */
@property (nonatomic, copy, nullable) NSString *currency;

@end
