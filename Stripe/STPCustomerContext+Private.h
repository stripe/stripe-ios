//
//  STPCustomerContext+Private.h
//  Stripe
//
//  Created by Ben Guo on 6/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

#import "STPBlocks.h"

@class STPAddress;

NS_ASSUME_NONNULL_BEGIN

@interface STPCustomerContext (Private)

- (void)updateCustomerWithShippingAddress:(STPAddress *)shipping completion:(nullable STPErrorBlock)completion;
- (void)detachSourceFromCustomer:(id<STPSourceProtocol>)source completion:(nullable STPErrorBlock)completion;

@end

NS_ASSUME_NONNULL_END
