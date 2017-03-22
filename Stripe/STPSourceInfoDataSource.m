//
//  STPSourceInfoDataSource.m
//  Stripe
//
//  Created by Ben Guo on 3/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceInfoDataSource.h"

@implementation STPSourceInfoDataSource

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams {
    self = [super init];
    if (self) {
        _sourceParams = sourceParams;
        _title = @"";
        _cells = @[];
    }
    return self;
}

- (STPSourceParams *)completeSourceParams {
    return nil;
}

@end
