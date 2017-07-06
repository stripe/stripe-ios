//
//  STPCard+Private.h
//  Stripe
//
//  Created by Ben Guo on 1/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCard.h"
#import "STPInternalAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPCard () <STPInternalAPIResponseDecodable>

+ (nullable NSString *)stringFromFunding:(STPCardFundingType)funding;

@end

NS_ASSUME_NONNULL_END
