//
//  STPLineItem.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPLineItem.h"

@interface STPLineItem()

@property(nonatomic, readwrite) NSString *label;
@property(nonatomic, readwrite) NSDecimalNumber *amount;

@end

@implementation STPLineItem

- (instancetype)initWithLabel:(NSString *)label amount:(NSDecimalNumber *)amount {
    self = [super init];
    if (self) {
        _label = label;
        _amount = amount;
    }
    return self;
}

@end
