//
//  STPPaymentResult.m
//  Stripe
//
//  Created by Jack Flintermann on 1/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentResult.h"

@interface STPPaymentResult()

@property(nonatomic, nonnull) id<STPSource> source;
@property(nonatomic, nullable) NSString *customer;

@end

@implementation STPPaymentResult

- (nonnull instancetype)initWithSource:(nonnull id<STPSource>)source customer:(nullable NSString *)customer {
    self = [super init];
    if (self) {
        _source = source;
        _customer = customer;
    }
    return self;
}

@end
