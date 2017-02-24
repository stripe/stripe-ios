//
//  STPSourceCardDetails.h
//  Stripe
//
//  Created by Brian Dorfman on 2/23/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"
#import "STPCard.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, STPSourceCard3DSecureStatus) {
    STPSourceCard3DSecureStatusRequired,
    STPSourceCard3DSecureStatusOptional,
    STPSourceCard3DSecureStatusNotSupported,
    STPSourceCard3DSecureStatusUnknown
};

/**
 *  This class provides typed access to the contents of an STPSource `details`
 *  dictionary for card sources.
 */
@interface STPSourceCardDetails : NSObject <STPAPIResponseDecodable>

/**
 *  You cannot directly instantiate an `STPSourceCardDetails`. You should only 
 *  use one that is part of an existing `STPSource` object.
 */
- (nonnull instancetype) init __attribute__((unavailable("You cannot directly instantiate an STPSourceCardDetails. You should only use one that is part of an existing STPSource object.")));

/**
 *  The last 4 digits of the card.
 */
@property (nonatomic, readonly, nullable) NSString *last4;

/**
 *  The card's expiration month. 1-indexed (i.e. 1 == January)
 */
@property (nonatomic, readonly) NSUInteger expMonth;

/**
 *  The card's expiration year.
 */
@property (nonatomic, readonly) NSUInteger expYear;

/**
 *  The issuer of the card.
 */
@property (nonatomic, readonly) STPCardBrand brand;

/**
 *  The funding source for the card (credit, debit, prepaid, or other)
 */
@property (nonatomic, readonly) STPCardFundingType funding;

/**
 *  Two-letter ISO code representing the issuing country of the card.
 */
@property (nonatomic, readonly, nullable) NSString *country;

/**
 *  Whether 3D Secure is supported or required by the card.
 */
@property (nonatomic, readonly) STPSourceCard3DSecureStatus threeDSecure;

@end

NS_ASSUME_NONNULL_END
