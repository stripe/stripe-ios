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

@property (nonatomic, nullable, readonly) NSString *pin;
@property (nonatomic, nullable, readonly) NSDictionary *error;

@end

NS_ASSUME_NONNULL_END
