//
//  MockSTPCheckoutAPIClient.m
//  Stripe
//
//  Created by Ben Guo on 7/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "MockSTPCheckoutAPIClient.h"

@implementation MockSTPCheckoutAPIClient

- (STPPromise<STPToken *> *)createTokenWithAccount:(STPCheckoutAccount *)account {
    STPPromise *promise = self.createTokenWithAccount(account);
    return promise;
}

@end
