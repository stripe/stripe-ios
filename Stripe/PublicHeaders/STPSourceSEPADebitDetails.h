//
//  STPSourceSEPADebitDetails.h
//  Stripe
//
//  Created by Brian Dorfman on 2/24/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  This class provides typed access to the contents of an STPSource `details`
 *  dictionary for SEPA Debit sources.
 */
@interface STPSourceSEPADebitDetails : NSObject <STPAPIResponseDecodable>

/**
 *  You cannot directly instantiate an `STPSourceSEPADebitDetails`. 
 *  You should only use one that is part of an existing `STPSource` object.
 */
- (nonnull instancetype) init __attribute__((unavailable("You cannot directly instantiate an STPSourceSEPADebitDetails. You should only use one that is part of an existing STPSource object.")));

/**
 *  The last 4 digits of the card.
 */
@property (nonatomic, readonly, nullable) NSString *last4;

/**
 *
 */
@property (nonatomic, readonly, nullable) NSString *bankCode;

/**
 *  Two-letter ISO code representing the issuing country of the card.
 */
@property (nonatomic, readonly, nullable) NSString *country;

/**
 *
 */
@property (nonatomic, readonly, nullable) NSString *fingerprint;

/**
 *
 */
@property (nonatomic, readonly, nullable) NSString *mandateReference;

/**
 *
 */
@property (nonatomic, readonly, nullable) NSURL *mandateURL;



@end

NS_ASSUME_NONNULL_END
