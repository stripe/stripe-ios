//
//  MockSTPAPIClient.m
//  Stripe
//
//  Created by Ben Guo on 7/5/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "MockSTPAPIClient.h"

@implementation MockSTPAPIClient

- (instancetype)init {
    return [super initWithPublishableKey:@"mock"];
}

- (void)createTokenWithCard:(STPCardParams *)card completion:(STPTokenCompletionBlock)completion {
    if (self.onCreateTokenWithCard) {
        self.onCreateTokenWithCard(card, completion);
    }
}

@end
