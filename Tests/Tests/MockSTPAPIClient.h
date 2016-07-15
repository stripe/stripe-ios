//
//  MockSTPAPIClient.h
//  Stripe
//
//  Created by Ben Guo on 7/5/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Stripe/Stripe.h>

NS_ASSUME_NONNULL_BEGIN

@interface MockSTPAPIClient : STPAPIClient
@property (nonatomic, copy, nullable) void(^onCreateTokenWithCard)(STPCardParams *cardParams, _Nullable STPTokenCompletionBlock completion);
@end

NS_ASSUME_NONNULL_END
