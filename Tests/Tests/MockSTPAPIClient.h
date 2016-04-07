//
//  MockSTPAPIClient.h
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>

@interface MockSTPAPIClient : STPAPIClient

@property (nonatomic, copy, nullable) void(^createTokenWithCardBlock)(STPCardParams * __nonnull, STPTokenCompletionBlock __nonnull);

@end
