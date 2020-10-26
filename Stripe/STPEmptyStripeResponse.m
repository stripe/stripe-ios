//
//  STPEmptyStripeResponse.m
//  StripeiOS
//
//  Created by Cameron Sabol on 6/11/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPEmptyStripeResponse.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPEmptyStripeResponse

@synthesize allResponseFields = _allResponseFields;

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    STPEmptyStripeResponse *emptyResponse = [self new];
    emptyResponse->_allResponseFields = [response copy];

    return emptyResponse;
}

@end

NS_ASSUME_NONNULL_END
