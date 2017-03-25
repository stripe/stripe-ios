//
//  STPSourceInfoDataSource.m
//  Stripe
//
//  Created by Ben Guo on 3/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceInfoDataSource.h"

#import "STPSelectorDataSource.h"

@implementation STPSourceInfoDataSource

- (instancetype)initWithSourceParams:(STPSourceParams *)sourceParams
                prefilledInformation:(__unused STPUserInformation *)prefilledInfo {
    self = [super init];
    if (self) {
        _sourceParams = sourceParams;
        _paymentMethodType = nil;
        _cells = @[];
        _requiresUserVerification = NO;
    }
    return self;
}

- (STPSourceParams *)completeSourceParams {
    return nil;
}

@end
