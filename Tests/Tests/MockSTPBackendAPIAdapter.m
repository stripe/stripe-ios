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
        _sources = @[];
    }
    return self;
}

- (void)retrieveSources:(STPSourceCompletionBlock)completion {
    if (self.retrieveSourcesError) {
        completion(nil, nil, self.retrieveSourcesError);
    }
    else {
        completion(self.selectedSource, self.sources, nil);
    }
}

- (void)addSource:(id<STPSource>)source completion:(STPSourceCompletionBlock)completion {
    if (self.addSourceError) {
        completion(nil, nil, self.addSourceError);
    }
    else {
        self.sources = [self.sources arrayByAddingObject:source];
        completion(self.selectedSource, self.sources, nil);
    }
}

- (void)selectSource:(nonnull id<STPSource>)source completion:(nonnull STPSourceCompletionBlock)completion {
    if (self.selectSourceError) {
        completion(nil, nil, self.selectSourceError);
    }
    else {
        self.selectedSource = source;
        completion(self.selectedSource, self.sources, nil);
    }
}

- (void)updateCustomerShippingAddress:(STPAddress *)shippingAddress completion:(STPAddressCompletionBlock)completion {
    if (self.updateCustomerShippingError) {
        completion(nil, self.updateCustomerShippingError);
    }
    else {
        self.shippingAddress = shippingAddress;
        completion(self.shippingAddress, nil);
    }
}

@end
