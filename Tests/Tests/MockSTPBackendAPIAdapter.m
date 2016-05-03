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

- (void)retrieveCards:(STPCardCompletionBlock)completion {
    if (self.retrieveCardsError) {
        completion(nil, nil, self.retrieveCardsError);
    } else {
        completion(self.selectedCard, self.cards, nil);
    }
}

- (void)addToken:(STPToken *)token completion:(STPErrorBlock)completion {
    if (self.addTokenError) {
        completion(self.addTokenError);
    } else {
        self.cards = [self.cards arrayByAddingObject:token.card];
        completion(nil);
    }
}

- (void)selectCard:(STPCard *)card completion:(STPErrorBlock)completion {
    if (self.selectCardError) {
        completion(self.selectCardError);
    } else {
        self.selectedCard = card;
        completion(nil);
    }
}

- (void)deleteCard:(STPCard *)card completion:(STPErrorBlock)completion {
    if (self.deleteCardError) {
        completion(self.deleteCardError);
    } else {
        NSMutableArray *array = [self.cards mutableCopy];
        [array removeObject:card];
        self.cards = [array copy];
        completion(nil);
    }
}

- (void)updateCustomerShippingAddress:(STPAddress *)shippingAddress completion:(STPAddressCompletionBlock)completion {
    if (self.updateCustomerShippingAddressError) {
        completion(nil, self.updateCustomerShippingAddressError);
    }
    else {
        self.shippingAddress = shippingAddress;
        completion(self.shippingAddress, nil);
    }
}

- (void)retrieveCustomerShippingAddress:(STPAddressCompletionBlock)completion {
    if (self.onRetrieveCustomerShippingAddress) {
        self.onRetrieveCustomerShippingAddress();
    }
    completion(self.shippingAddress, nil);
}

@end
