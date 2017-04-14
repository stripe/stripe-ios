//
//  STPAdditionalSourceInfo.m
//  Stripe
//
//  Created by Ben Guo on 4/11/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPAdditionalSourceInfo.h"

@implementation STPAdditionalSourceInfo

- (id)copyWithZone:(__unused NSZone *)zone {
    STPAdditionalSourceInfo *copy = [self.class new];
    copy.metadata = self.metadata;
    copy.statementDescriptor = self.statementDescriptor;
    return copy;
}

@end
