//
//  STPMandateOnlineParams+Private.h
//  Stripe
//
//  Created by Cameron Sabol on 10/17/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPMandateOnlineParams.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPMandateOnlineParams (Private)

/// Boolean number to infer ip_address and user_agent automatically
@property (nonatomic, nullable) NSNumber *inferFromClient;

@end

NS_ASSUME_NONNULL_END
