//
//  MockSTPSourceProvider.m
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/29/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

#import "MockSTPSourceProvider.h"
#import <Stripe/Stripe.h>

@implementation MockSTPSourceProvider

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

@end
