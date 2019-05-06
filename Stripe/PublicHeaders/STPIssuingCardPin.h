//
//  STPIssuingCardPin.h
//  Stripe
//
//  Created by Arnaud Cavailhez on 4/29/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Information related to a Stripe Issuing card, including the PIN
 */
@interface STPIssuingCardPin  : NSObject<STPAPIResponseDecodable>

/**
 You cannot directly instantiate an `STPIssuingCardPin`.
 */
- (instancetype)init __attribute__((unavailable("You cannot directly instantiate an STPIssuingCardPin")));

/**
 The PIN for the card
 */
@property (nonatomic, nullable, readonly) NSString *pin;

/**
 If the PIN failed to be created, this error might be present
 */
@property (nonatomic, nullable, readonly) NSDictionary *error;

@end

NS_ASSUME_NONNULL_END
