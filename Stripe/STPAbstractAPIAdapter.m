//
//  STPAbstractAPIAdapter.m
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAbstractAPIAdapter.h"
#import "STPBlocks.h"
#import "STPSource.h"

@implementation STPAbstractAPIAdapter

- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)retrieveSources:(nonnull STPSourceCompletionBlock)completion {

}

- (void)addSource:(nonnull id<STPSource>)source completion:(nonnull STPSourceCompletionBlock)completion {

}

- (void)selectSource:(nonnull id<STPSource>)source completion:(nonnull STPSourceCompletionBlock)completion {

}


@end
