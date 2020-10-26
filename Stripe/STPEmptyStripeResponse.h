//
//  STPEmptyStripeResponse.h
//  StripeiOS
//
//  Created by Cameron Sabol on 6/11/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/**
 An STPAPIResponseDecodable implementation to use for endpoints that don't
 actually return objects, like /v1/3ds2/challenge_completed
 */
@interface STPEmptyStripeResponse : NSObject <STPAPIResponseDecodable>

@end

NS_ASSUME_NONNULL_END
