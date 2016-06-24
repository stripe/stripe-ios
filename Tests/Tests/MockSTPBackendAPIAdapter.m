//
//  MockSTPBackendAPIAdapter.m
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import "MockSTPBackendAPIAdapter.h"
#import <Stripe/Stripe.h>

@implementation MockSTPBackendAPIAdapter

- (instancetype)init {
    self = [super init];
    if (self) {
        _cards = @[];
    }
    return self;
}

- (void)retrieveCustomerSources:(STPSourceCompletionBlock)completion {
    if (self.retrieveCardsError) {
        completion(nil, nil, self.retrieveCardsError);
    } else {
        completion(self.selectedCard.stripeID, self.cards, nil);
    }
}

- (void)attachSourceToCustomer:(id<STPSource>)source completion:(STPErrorBlock)completion {
    if (self.addTokenError) {
        completion(self.addTokenError);
    } else {
        self.cards = [self.cards arrayByAddingObject:(STPCard *)source];
        completion(nil);
    }
}

- (void)selectDefaultCustomerSource:(id<STPSource>)source completion:(STPErrorBlock)completion {
    if (self.selectCardError) {
        completion(self.selectCardError);
    } else {
        self.selectedCard = (STPCard *)source;
        completion(nil);
    }
}

@end
