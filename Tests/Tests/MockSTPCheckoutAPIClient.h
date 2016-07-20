//
//  MockSTPCheckoutAPIClient.h
//  Stripe
//
//  Created by Ben Guo on 7/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPCheckoutAPIClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface MockSTPCheckoutAPIClient : STPCheckoutAPIClient
@property (nonatomic, copy, nullable) STPPromise *(^createTokenWithAccount)(STPCheckoutAccount *checkoutAccount);
@end

NS_ASSUME_NONNULL_END
